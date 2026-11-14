//! Real-time 4-band audio spectrum visualizer for Quickshell Antigravity Dynamic Island.
//! Reads live audio stream from EasyEffects sink monitor (or default monitor),
//! computes 4 frequency bands (Bass, Low-Mid, Mid, Treble) via real-to-complex FFT,
//! and streams smooth normalized values to stdout.

use realfft::RealFftPlanner;
use std::f32::consts::PI;
use std::io::{self, Read, Write};
use std::process::{Child, Command, Stdio};
use std::thread;
use std::time::Duration;

const RATE: u32 = 22050;
const CHUNK: usize = 1024;
const CHUNK_BYTES: usize = CHUNK * 2; // 16-bit PCM = 2 bytes per sample

fn get_best_monitor() -> String {
    if let Ok(output) = Command::new("pactl")
        .args(["list", "short", "sources"])
        .stderr(Stdio::null())
        .output()
    {
        let text = String::from_utf8_lossy(&output.stdout);
        if text.contains("easyeffects_sink.monitor") {
            return "easyeffects_sink.monitor".to_string();
        }
    }
    "@DEFAULT_MONITOR@".to_string()
}

fn spawn_parec(monitor: &str) -> io::Result<Child> {
    Command::new("parec")
        .arg("-d")
        .arg(monitor)
        .arg("--format=s16le")
        .arg(format!("--rate={RATE}"))
        .arg("--channels=1")
        .arg("--latency-msec=20")
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
}

fn main() {
    let mut real_planner = RealFftPlanner::<f32>::new();
    let r2c = real_planner.plan_fft_forward(CHUNK);
    let mut indata = r2c.make_input_vec();
    let mut spectrum = r2c.make_output_vec();

    // Precompute Hanning window
    let mut hanning = [0.0f32; CHUNK];
    for i in 0..CHUNK {
        hanning[i] = 0.5 * (1.0 - (2.0 * PI * i as f32 / (CHUNK - 1) as f32).cos());
    }

    // Precalculate frequency band bin indices
    let df = RATE as f32 / CHUNK as f32; // ~21.5332 Hz per bin
    let mut b0_bins = Vec::new();
    let mut b1_bins = Vec::new();
    let mut b2_bins = Vec::new();
    let mut b3_bins = Vec::new();

    let num_bins = spectrum.len(); // 513
    for k in 0..num_bins {
        let f = k as f32 * df;
        if (25.0..=160.0).contains(&f) {
            b0_bins.push(k);
        } else if f > 160.0 && f <= 600.0 {
            b1_bins.push(k);
        } else if f > 600.0 && f <= 2400.0 {
            b2_bins.push(k);
        } else if f > 2400.0 && f <= 9000.0 {
            b3_bins.push(k);
        }
    }

    let mut peaks = [14.0f32, 6.0, 1.4, 0.40];
    let min_peaks = [5.0f32, 2.0, 0.45, 0.12];
    let mut smooth = [0.0f32; 4];
    let mut was_silent = false;

    let mut stdout = io::stdout().lock();
    let mut raw_buf = [0u8; CHUNK_BYTES];

    loop {
        let target_device = get_best_monitor();
        let mut child = match spawn_parec(&target_device) {
            Ok(c) => c,
            Err(_) => {
                thread::sleep(Duration::from_millis(1000));
                continue;
            }
        };

        let mut child_stdout = match child.stdout.take() {
            Some(out) => out,
            None => {
                let _ = child.kill();
                thread::sleep(Duration::from_millis(500));
                continue;
            }
        };

        loop {
            if let Err(_) = child_stdout.read_exact(&mut raw_buf) {
                break;
            }

            // Convert s16le bytes to normalized float samples [-1.0, 1.0]
            let mut sum_sq = 0.0f32;
            for i in 0..CHUNK {
                let sample_i16 = i16::from_le_bytes([raw_buf[i * 2], raw_buf[i * 2 + 1]]);
                let sample_f32 = sample_i16 as f32 / 32768.0;
                sum_sq += sample_f32 * sample_f32;
                indata[i] = sample_f32 * hanning[i];
            }

            let rms = (sum_sq / CHUNK as f32).sqrt();

            if rms < 0.005 {
                if was_silent {
                    continue;
                }
                was_silent = true;
                smooth = [0.0; 4];
                if writeln!(stdout, "{{\"b0\":0.00,\"b1\":0.00,\"b2\":0.00,\"b3\":0.00}}").is_err()
                    || stdout.flush().is_err()
                {
                    return;
                }
            } else {
                was_silent = false;
                if r2c.process(&mut indata, &mut spectrum).is_err() {
                    continue;
                }

                // Compute magnitudes
                let mut mags = [0.0f32; 513];
                for (k, c) in spectrum.iter().enumerate() {
                    mags[k] = c.norm();
                }

                let calc_band_mean = |bins: &[usize]| -> f32 {
                    if bins.is_empty() {
                        0.0
                    } else {
                        let sum: f32 = bins.iter().map(|&idx| mags[idx]).sum();
                        sum / bins.len() as f32
                    }
                };

                let raw_bands = [
                    calc_band_mean(&b0_bins),
                    calc_band_mean(&b1_bins),
                    calc_band_mean(&b2_bins),
                    calc_band_mean(&b3_bins),
                ];

                for i in 0..4 {
                    peaks[i] = (peaks[i] * 0.985).max(min_peaks[i]);
                    if raw_bands[i] > peaks[i] {
                        peaks[i] = raw_bands[i];
                    }

                    let norm = (raw_bands[i] / peaks[i]).clamp(0.0, 1.0);
                    let norm = norm.powf(1.35);
                    let attack = if norm > smooth[i] { 0.65 } else { 0.28 };
                    smooth[i] = smooth[i] * (1.0 - attack) + norm * attack;
                }

                if writeln!(
                    stdout,
                    "{{\"b0\":{:.2},\"b1\":{:.2},\"b2\":{:.2},\"b3\":{:.2}}}",
                    smooth[0], smooth[1], smooth[2], smooth[3]
                )
                .is_err()
                    || stdout.flush().is_err()
                {
                    return;
                }
            }
        }

        let _ = child.kill();
        let _ = child.wait();
        thread::sleep(Duration::from_millis(500));
    }
}
