use std::env;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use anyhow::{bail, Context, Result};
use image::Luma;
use ocrs::{ImageSource, OcrEngine, OcrEngineParams};
use qrcode::QrCode;
use rten::Model;

const DETECTION_MODEL_URL: &str = "https://ocrs-models.s3-accelerate.amazonaws.com/text-detection.onnx";
const RECOGNITION_MODEL_URL: &str = "https://ocrs-models.s3-accelerate.amazonaws.com/text-recognition.onnx";

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    let bin_name = Path::new(&args[0])
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("ag-screen-tools");

    // Determine command either from binary name (e.g. symlinked as screen-ocr) or from first argument
    let command = if bin_name.contains("ocr") {
        "ocr"
    } else if bin_name.contains("qr") {
        "qr-scan"
    } else if args.len() > 1 {
        args[1].as_str()
    } else {
        eprintln!("Usage: {} <ocr | qr-scan | qr-gen <text>>", bin_name);
        return Ok(());
    };

    match command {
        "ocr" => {
            let file_opt = if args.len() > 2 && args[1] == "ocr" {
                Some(args[2].clone())
            } else if args.len() > 1 && bin_name.contains("ocr") {
                Some(args[1].clone())
            } else {
                None
            };
            handle_ocr(file_opt)?;
        }
        "qr-scan" | "qr-read" => {
            let file_opt = if args.len() > 2 && args[1].starts_with("qr") {
                Some(args[2].clone())
            } else if args.len() > 1 && bin_name.contains("qr") {
                Some(args[1].clone())
            } else {
                None
            };
            handle_qr_scan(file_opt)?;
        }
        "qr-gen" | "qr" => {
            let text = if args.len() > 2 {
                args[2..].join(" ")
            } else if args.len() > 1 && !args[1].starts_with("qr") {
                args[1..].join(" ")
            } else {
                eprintln!("Usage: {} qr-gen <text_or_url>", bin_name);
                return Ok(());
            };
            handle_qr_gen(&text)?;
        }
        _ => {
            eprintln!("Unknown command: '{}'. Options: ocr, qr-scan, qr-gen <text>", command);
        }
    }

    Ok(())
}

fn get_models_dir() -> Result<PathBuf> {
    let home = env::var("HOME").context("HOME environment variable not set")?;
    let dir = PathBuf::from(home).join(".local/share/antigravity/models");
    fs::create_dir_all(&dir)?;
    Ok(dir)
}

fn ensure_model(dir: &Path, filename: &str, url: &str) -> Result<PathBuf> {
    let path = dir.join(filename);
    if path.exists() && fs::metadata(&path)?.len() > 100_000 {
        return Ok(path);
    }

    println!("Downloading OCR model '{}'...", filename);
    let status = Command::new("curl")
        .args(["-sSL", url, "-o"])
        .arg(&path)
        .status()
        .context("Failed to run curl to download OCR model")?;

    if !status.success() || !path.exists() {
        bail!("Failed to download model from {}", url);
    }
    Ok(path)
}

fn capture_area_via_slurp() -> Result<Option<PathBuf>> {
    // 1. Run slurp to get screen coordinates
    let slurp_output = Command::new("slurp")
        .output()
        .context("Failed to run slurp. Make sure slurp is installed.")?;

    if !slurp_output.status.success() {
        // User canceled selection (e.g. pressed Escape or clicked outside)
        return Ok(None);
    }

    let geometry = String::from_utf8_lossy(&slurp_output.stdout).trim().to_string();
    if geometry.is_empty() {
        return Ok(None);
    }

    // 2. Capture screenshot of the selected area via grim
    let tmp_path = env::temp_dir().join(format!("ag_screen_grab_{}.png", std::process::id()));
    let grim_status = Command::new("grim")
        .args(["-g", &geometry])
        .arg(&tmp_path)
        .status()
        .context("Failed to run grim. Make sure grim is installed.")?;

    if !grim_status.success() || !tmp_path.exists() {
        bail!("grim capture failed for geometry '{}'", geometry);
    }

    Ok(Some(tmp_path))
}

fn copy_to_clipboard(text: &str) -> Result<()> {
    let mut child = Command::new("wl-copy")
        .stdin(Stdio::piped())
        .spawn()
        .context("Failed to execute wl-copy")?;

    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(text.as_bytes())?;
    }
    child.wait()?;
    Ok(())
}

fn notify(app_name: &str, title: &str, body: &str, icon: Option<&str>) {
    let mut cmd = Command::new("notify-send");
    cmd.args(["-a", app_name, title, body]);
    if let Some(ic) = icon {
        cmd.args(["-i", ic]);
    }
    let _ = cmd.spawn();
}

fn handle_ocr(file_arg: Option<String>) -> Result<()> {
    let img_path = match file_arg {
        Some(path_str) => PathBuf::from(path_str),
        None => match capture_area_via_slurp()? {
            Some(p) => p,
            None => return Ok(()), // User canceled
        },
    };

    let models_dir = get_models_dir()?;
    let det_model_path = ensure_model(&models_dir, "text-detection.onnx", DETECTION_MODEL_URL)?;
    let rec_model_path = ensure_model(&models_dir, "text-recognition.onnx", RECOGNITION_MODEL_URL)?;

    let det_model = Model::load_file(det_model_path)?;
    let rec_model = Model::load_file(rec_model_path)?;

    let engine = OcrEngine::new(OcrEngineParams {
        detection_model: Some(det_model),
        recognition_model: Some(rec_model),
        ..Default::default()
    })?;

    let img = image::open(&img_path)
        .context("Failed to open captured image")?
        .into_rgb8();
    let img_source = ImageSource::from_bytes(img.as_raw(), img.dimensions())?;
    let ocr_input = engine.prepare_input(img_source)?;

    // Get line rects and recognize text
    let word_rects = engine.detect_words(&ocr_input)?;
    let line_rects = engine.find_text_lines(&ocr_input, &word_rects);
    let line_texts = engine.recognize_text(&ocr_input, &line_rects)?;

    let lines: Vec<String> = line_texts
        .iter()
        .flatten()
        .map(|l| l.to_string())
        .filter(|s| !s.trim().is_empty())
        .collect();

    if lines.is_empty() {
        notify("Screen OCR", "No text detected", "Try selecting the region again with higher contrast.", Some("edit-copy"));
        let _ = fs::remove_file(&img_path);
        return Ok(());
    }

    let full_text = lines.join("\n");
    copy_to_clipboard(&full_text)?;

    // Create a compact preview for notification
    let preview = if full_text.len() > 140 {
        format!("{}...", &full_text[..137])
    } else {
        full_text.clone()
    };

    notify("Screen OCR", "Text Copied to Clipboard", &preview, Some("edit-copy"));
    println!("{}", full_text);

    let _ = fs::remove_file(&img_path);
    Ok(())
}

fn handle_qr_scan(file_arg: Option<String>) -> Result<()> {
    let img_path = match file_arg {
        Some(path_str) => PathBuf::from(path_str),
        None => match capture_area_via_slurp()? {
            Some(p) => p,
            None => return Ok(()),
        },
    };

    let img = image::open(&img_path)
        .context("Failed to open captured image")?
        .to_luma8();
    let mut prepared = rqrr::PreparedImage::prepare(img);
    let grids = prepared.detect_grids();

    if grids.is_empty() {
        notify("QR Scanner", "No QR Code Found", "Please select a clearer area around the QR code.", Some("dialog-warning"));
        let _ = fs::remove_file(&img_path);
        return Ok(());
    }

    let mut decoded_text = String::new();
    for grid in grids {
        if let Ok((_, content)) = grid.decode() {
            decoded_text = content;
            break;
        }
    }

    if decoded_text.is_empty() {
        notify("QR Scanner", "Failed to Decode", "The QR code was blurry or obscured.", Some("dialog-warning"));
        let _ = fs::remove_file(&img_path);
        return Ok(());
    }

    copy_to_clipboard(&decoded_text)?;
    notify("QR Scanner", "QR Code Copied to Clipboard", &decoded_text, Some("camera-photo"));
    println!("{}", decoded_text);

    let _ = fs::remove_file(&img_path);
    Ok(())
}

fn handle_qr_gen(text: &str) -> Result<()> {
    let code = QrCode::new(text.as_bytes())
        .context("Failed to generate QR code for given input")?;

    // Render as PNG image
    let image = code.render::<Luma<u8>>()
        .min_dimensions(360, 360)
        .quiet_zone(true)
        .build();

    let out_path = env::temp_dir().join("antigravity_generated_qr.png");
    image.save(&out_path)?;

    // Copy image directly to Wayland clipboard so user can paste it anywhere
    let _ = Command::new("wl-copy")
        .args(["-t", "image/png"])
        .stdin(Stdio::from(fs::File::open(&out_path)?))
        .status();

    // Also render ANSI block version in terminal if running interactively
    let ansi_qr = code.render::<qrcode::render::unicode::Dense1x2>().build();
    println!("{}", ansi_qr);
    println!("QR code for '{}' generated and copied to clipboard as image!", text);

    notify(
        "QR Generator",
        "QR Code Ready",
        &format!("Generated for: {}\nImage copied to clipboard!", text),
        out_path.to_str()
    );

    Ok(())
}
