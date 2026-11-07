#!/usr/bin/env python3
"""
Real-time 4-band audio spectrum visualizer for Quickshell Antigravity Dynamic Island.
Reads live audio stream from EasyEffects sink monitor (or default monitor),
computes 4 frequency bands (Bass, Low-Mid, Mid, Treble) via FFT,
and streams smooth normalized values to stdout.
"""

import sys
import time
import subprocess
import numpy as np

def get_best_monitor():
    try:
        out = subprocess.check_output(["pactl", "list", "short", "sources"], text=True, stderr=subprocess.DEVNULL)
        if "easyeffects_sink.monitor" in out:
            return "easyeffects_sink.monitor"
    except Exception:
        pass
    return "@DEFAULT_MONITOR@"

def run_tracker():
    rate = 22050
    chunk = 1024  # ~46ms window (~21 updates/sec)
    
    hanning = np.hanning(chunk)
    freqs = np.fft.rfftfreq(chunk, d=1.0/rate)
    
    # 4 distinct frequency bands
    b0_mask = (freqs >= 25) & (freqs <= 160)    # Sub-bass & kick drum
    b1_mask = (freqs > 160) & (freqs <= 600)    # Bass & low-mids (bassline/warmth)
    b2_mask = (freqs > 600) & (freqs <= 2400)   # Midrange (vocals & instruments)
    b3_mask = (freqs > 2400) & (freqs <= 9000)  # Treble (hi-hats, air, snares)
    
    peaks = [14.0, 6.0, 1.4, 0.40]
    min_peaks = [5.0, 2.0, 0.45, 0.12]
    smooth = [0.0, 0.0, 0.0, 0.0]
    was_silent = False
    
    while True:
        target_device = get_best_monitor()
        cmd = [
            "parec",
            "-d", target_device,
            "--format=s16le",
            f"--rate={rate}",
            "--channels=1",
            "--latency-msec=20"
        ]
        
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                bufsize=chunk * 4
            )
        except Exception:
            time.sleep(1.0)
            continue

        try:
            while True:
                raw = proc.stdout.read(chunk * 2)
                if not raw or len(raw) < chunk * 2:
                    break
                
                samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
                rms = float(np.sqrt(np.mean(samples**2)))
                
                if rms < 0.005:
                    if was_silent:
                        continue
                    was_silent = True
                    smooth = [0.0, 0.0, 0.0, 0.0]
                    sys.stdout.write('{"b0":0.00,"b1":0.00,"b2":0.00,"b3":0.00}\n')
                    sys.stdout.flush()
                else:
                    was_silent = False
                    fft = np.abs(np.fft.rfft(samples * hanning))
                    
                    raw_bands = [
                        float(np.mean(fft[b0_mask])) if np.any(b0_mask) else 0.0,
                        float(np.mean(fft[b1_mask])) if np.any(b1_mask) else 0.0,
                        float(np.mean(fft[b2_mask])) if np.any(b2_mask) else 0.0,
                        float(np.mean(fft[b3_mask])) if np.any(b3_mask) else 0.0
                    ]
                    
                    for i in range(4):
                        # Auto-gain: slow release on peak
                        peaks[i] = max(peaks[i] * 0.985, min_peaks[i])
                        if raw_bands[i] > peaks[i]:
                            peaks[i] = raw_bands[i]
                        
                        norm = min(1.0, max(0.0, raw_bands[i] / peaks[i]))
                        # Dynamic contrast expansion
                        norm = pow(norm, 1.35)
                        # Asymmetric smoothing: punchy attack (0.65), smooth release (0.28)
                        attack = 0.65 if norm > smooth[i] else 0.28
                        smooth[i] = smooth[i] * (1.0 - attack) + norm * attack
                    
                    line = f'{{"b0":{smooth[0]:.2f},"b1":{smooth[1]:.2f},"b2":{smooth[2]:.2f},"b3":{smooth[3]:.2f}}}\n'
                    sys.stdout.write(line)
                    sys.stdout.flush()
                    
        except (BrokenPipeError, KeyboardInterrupt):
            break
        except Exception:
            pass
        finally:
            try:
                proc.terminate()
                proc.wait(timeout=1.0)
            except Exception:
                pass
            time.sleep(0.5)

if __name__ == "__main__":
    run_tracker()
