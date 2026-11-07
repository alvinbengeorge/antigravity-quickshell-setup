#!/usr/bin/env python3
import sys
import os
import json
import urllib.request
import colorsys
from PIL import Image
import io

CACHE_FILE = "/tmp/quickshell_media_art.jpg"

def extract_vibrant_color(art_url):
    if not art_url:
        return None

    data = None
    try:
        if art_url.startswith("http://") or art_url.startswith("https://"):
            req = urllib.request.Request(art_url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=2.5) as resp:
                data = resp.read()
            # Cache it for QML Image component to load directly
            with open(CACHE_FILE, "wb") as f:
                f.write(data)
        elif art_url.startswith("file://"):
            local_path = art_url[7:]
            if os.path.exists(local_path):
                with open(local_path, "rb") as f:
                    data = f.read()
        elif os.path.exists(art_url):
            with open(art_url, "rb") as f:
                data = f.read()
    except Exception as e:
        return None

    if not data:
        return None

    try:
        img = Image.open(io.BytesIO(data)).convert("RGB")
        img = img.resize((48, 48))
        colors = img.getcolors(maxcolors=48 * 48)
        if not colors:
            return None

        best_rgb = None
        best_score = -1.0

        for count, (r, g, b) in colors:
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            # Filter out extreme blacks, whites, and greys
            if v < 0.12 or v > 0.96 or s < 0.15:
                continue
            # Score formula: favor vibrant saturated tones
            score = (s ** 1.3) * (v ** 0.8) * (count ** 0.4)
            if score > best_score:
                best_score = score
                best_rgb = (r, g, b)

        if not best_rgb:
            # Fallback to mean color
            stat = img.resize((1, 1)).getpixel((0, 0))
            best_rgb = stat[:3]

        r, g, b = best_rgb
        h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        
        # Boost vibrancy if it's too dim for UI text/elements
        if v < 0.45:
            v = min(0.85, v * 1.8)
            s = min(1.0, max(0.5, s))
            r_f, g_f, b_f = colorsys.hsv_to_rgb(h, s, v)
            r, g, b = int(r_f * 255), int(g_f * 255), int(b_f * 255)

        hex_code = f"#{r:02x}{g:02x}{b:02x}"
        return {
            "color": hex_code,
            "cacheFile": CACHE_FILE if os.path.exists(CACHE_FILE) else ""
        }
    except Exception:
        return None

def main():
    art_url = sys.argv[1] if len(sys.argv) > 1 else ""
    res = extract_vibrant_color(art_url)
    if res:
        print(json.dumps(res))
    else:
        print(json.dumps({"color": "", "cacheFile": ""}))

if __name__ == "__main__":
    main()
