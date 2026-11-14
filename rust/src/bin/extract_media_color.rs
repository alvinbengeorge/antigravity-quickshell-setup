use serde::Serialize;
use std::collections::HashMap;
use std::fs;
use std::io::Read;
use std::path::Path;

const CACHE_FILE: &str = "/tmp/quickshell_media_art.jpg";

#[derive(Serialize)]
struct ColorResult {
    color: String,
    #[serde(rename = "cacheFile")]
    cache_file: String,
}

fn rgb_to_hsv(r: u8, g: u8, b: u8) -> (f64, f64, f64) {
    let rf = r as f64 / 255.0;
    let gf = g as f64 / 255.0;
    let bf = b as f64 / 255.0;
    let cmax = rf.max(gf).max(bf);
    let cmin = rf.min(gf).min(bf);
    let delta = cmax - cmin;
    let h = if delta == 0.0 {
        0.0
    } else if cmax == rf {
        60.0 * (((gf - bf) / delta) % 6.0)
    } else if cmax == gf {
        60.0 * (((bf - rf) / delta) + 2.0)
    } else {
        60.0 * (((rf - gf) / delta) + 4.0)
    };
    let h = if h < 0.0 { h + 360.0 } else { h };
    let s = if cmax == 0.0 { 0.0 } else { delta / cmax };
    let v = cmax;
    (h, s, v)
}

fn hsv_to_rgb(h: f64, s: f64, v: f64) -> (u8, u8, u8) {
    let c = v * s;
    let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
    let m = v - c;
    let sector = (h / 60.0) as u32;
    let (rf, gf, bf) = match sector {
        0 => (c, x, 0.0),
        1 => (x, c, 0.0),
        2 => (0.0, c, x),
        3 => (0.0, x, c),
        4 => (x, 0.0, c),
        _ => (c, 0.0, x),
    };
    (
        ((rf + m) * 255.0).round().clamp(0.0, 255.0) as u8,
        ((gf + m) * 255.0).round().clamp(0.0, 255.0) as u8,
        ((bf + m) * 255.0).round().clamp(0.0, 255.0) as u8,
    )
}

fn fetch_art_data(art_url: &str) -> Option<Vec<u8>> {
    if art_url.is_empty() {
        return None;
    }

    if art_url.starts_with("http://") || art_url.starts_with("https://") {
        if let Ok(resp) = ureq::get(art_url)
            .set("User-Agent", "Mozilla/5.0")
            .timeout(std::time::Duration::from_millis(2500))
            .call()
        {
            let mut bytes = Vec::new();
            if resp.into_reader().read_to_end(&mut bytes).is_ok() && !bytes.is_empty() {
                let _ = fs::write(CACHE_FILE, &bytes);
                return Some(bytes);
            }
        }
    } else {
        let local_path = if let Some(stripped) = art_url.strip_prefix("file://") {
            stripped
        } else {
            art_url
        };

        if Path::new(local_path).exists() {
            if let Ok(bytes) = fs::read(local_path) {
                return Some(bytes);
            }
        }
    }

    None
}

fn extract_vibrant_color(art_url: &str) -> Option<ColorResult> {
    let data = fetch_art_data(art_url)?;

    let img = image::load_from_memory(&data).ok()?;
    let resized = img.resize_exact(48, 48, image::imageops::FilterType::CatmullRom);
    let rgb = resized.to_rgb8();

    let mut color_counts: HashMap<(u8, u8, u8), u32> = HashMap::new();
    let mut sum_r = 0u64;
    let mut sum_g = 0u64;
    let mut sum_b = 0u64;
    let total_pixels = 48 * 48;

    for pixel in rgb.pixels() {
        let r = pixel[0];
        let g = pixel[1];
        let b = pixel[2];
        sum_r += r as u64;
        sum_g += g as u64;
        sum_b += b as u64;
        *color_counts.entry((r, g, b)).or_insert(0) += 1;
    }

    let mut best_rgb: Option<(u8, u8, u8)> = None;
    let mut best_score = -1.0;

    for (&(r, g, b), &count) in &color_counts {
        let (_h, s, v) = rgb_to_hsv(r, g, b);

        // Filter out extreme blacks, whites, and greys
        if v < 0.12 || v > 0.96 || s < 0.15 {
            continue;
        }

        // Score formula: favor vibrant saturated tones
        let score = s.powf(1.3) * v.powf(0.8) * (count as f64).powf(0.4);
        if score > best_score {
            best_score = score;
            best_rgb = Some((r, g, b));
        }
    }

    let (mut r, mut g, mut b) = best_rgb.unwrap_or_else(|| {
        (
            (sum_r / total_pixels) as u8,
            (sum_g / total_pixels) as u8,
            (sum_b / total_pixels) as u8,
        )
    });

    let (h, mut s, mut v) = rgb_to_hsv(r, g, b);
    if v < 0.45 {
        v = (v * 1.8).min(0.85);
        s = s.max(0.5).min(1.0);
        let (r2, g2, b2) = hsv_to_rgb(h, s, v);
        r = r2;
        g = g2;
        b = b2;
    }

    let hex_code = format!("#{:02x}{:02x}{:02x}", r, g, b);
    let cache_file = if Path::new(CACHE_FILE).exists() {
        CACHE_FILE.to_string()
    } else {
        String::new()
    };

    Some(ColorResult {
        color: hex_code,
        cache_file,
    })
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let art_url = args.get(1).map(|s| s.as_str()).unwrap_or("");

    let res = extract_vibrant_color(art_url).unwrap_or(ColorResult {
        color: String::new(),
        cache_file: String::new(),
    });

    if let Ok(json) = serde_json::to_string(&res) {
        println!("{}", json);
    }
}
