#!/usr/bin/env python3
"""
Arythmatic Cinematic Plymouth Boot Animation Generator
Generates 203 high-resolution animation frames for Plymouth boot splash.
Layering rule: The amber crossbar is rendered BEHIND all typographic characters.
"""

import math
import os
import subprocess
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFilter

SRC_DIR = "/home/alvin/Desktop/personal/custom_quickshell/workspace/arythmatic_source"
SVG_FILE = os.path.join(SRC_DIR, "logo_dark.svg")
ICON_FILE = os.path.join(SRC_DIR, "icon.svg")
OUTPUT_DIR = os.path.join(SRC_DIR, "plymouth_theme")

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(SRC_DIR, exist_ok=True)

# 1. Parse original SVG
tree = ET.parse(SVG_FILE)
root = tree.getroot()
paths = root.findall(".//{http://www.w3.org/2000/svg}path")

letter_paths = [
    paths[10], # A
    paths[9],  # r
    paths[0],  # y (amber mark)
    paths[8],  # t
    paths[7],  # h
    paths[6],  # m
    paths[5],  # a
    paths[4],  # t
    paths[3],  # i
    paths[2],  # c
]
line_path = paths[1] # Amber crossbar (MUST BE IN BACKGROUND)

print("1. Rendering high-res isolated emblem (the mathematical 'A')...")
emblem_png_path = os.path.join(SRC_DIR, "emblem_highres.png")
subprocess.run([
    "magick", "-background", "none", "-density", "800",
    ICON_FILE, "-trim", "+repage", emblem_png_path
], check=True)

emblem_img = Image.open(emblem_png_path).convert("RGBA")
ew, eh = emblem_img.size
print(f"Emblem size: {ew}x{eh}")

print("2. Pre-rendering letter reveal steps (with amber bar in background)...")
# Render 10 letter steps where the amber line is always BEHIND the characters
text_crops = []
for k in range(1, 11):
    step_svg = ET.Element('{http://www.w3.org/2000/svg}svg', {
        'width': '370', 'height': '58', 'viewBox': '0 0 370 58', 'fill': 'none'
    })
    # Line is FIRST so it is drawn behind all characters
    step_svg.append(line_path)
    for p in letter_paths[:k]:
        step_svg.append(p)

    step_svg_path = os.path.join(SRC_DIR, f"step_{k}.svg")
    step_png_path = os.path.join(SRC_DIR, f"step_{k}.png")
    ET.ElementTree(step_svg).write(step_svg_path)
    subprocess.run([
        "magick", "-background", "none", "-density", "600",
        step_svg_path, "-trim", "+repage", "-resize", "x44", step_png_path
    ], check=True)
    text_crops.append(Image.open(step_png_path).convert("RGBA"))

# Full locked wordmark
full_step = text_crops[-1]
lw, lh = full_step.size
print(f"Full wordmark step size: {lw}x{lh}")

print("3. Pre-rendering 203 cinematic animation frames...")
CW, CH = 540, 240
CCX, CCY = CW // 2, CH // 2

# Dimensions & scaling
S_INITIAL = 1.05
S_FINAL = 0.58

# Target docked position for emblem
D_EMBLEM_Y = 62
D_WORDMARK_Y = 142

F_SCAN_END = 120   # 0..119: Pulse + 2 Mathematical Laser Scan Passes (~2.5s)
F_ZOOM_END = 150   # 120..149: Smooth glide upward & scale down (~0.6s)
F_TYPE_END = 196   # 150..195: Letter-by-letter reveal (10 letters * 4.5 frames)
TOTAL_FRAMES = 203 # 196..202: Locked final state with subtle shimmer

for f in range(TOTAL_FRAMES):
    im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))

    # ── STAGE 1: Emblem Solo + Pulsing Halo + Laser Sweep (Frames 0..119) ────
    if f < F_SCAN_END:
        pulse = (math.sin((f / 60.0) * 2 * math.pi) + 1.0) / 2.0
        cur_scale = S_INITIAL + 0.05 * pulse

        cur_w = int(ew * cur_scale * (140.0 / eh))
        cur_h = int(eh * cur_scale * (140.0 / eh))
        s_img = emblem_img.resize((cur_w, cur_h), Image.Resampling.LANCZOS)

        # Ambient golden aura
        glow_scale = 1.25 + 0.1 * pulse
        gw, gh = int(cur_w * glow_scale), int(cur_h * glow_scale)
        glow = s_img.resize((gw, gh), Image.Resampling.LANCZOS)
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        g_layer.paste(glow, (CCX - gw // 2, CCY - gh // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=int(14 + 5 * pulse)))
        im = Image.alpha_composite(im, g_layer)

        # Emblem in center
        im.paste(s_img, (CCX - cur_w // 2, CCY - cur_h // 2), s_img)

        # Vertical mathematical laser scan sweep
        sweep_f = f % 60
        t_sweep = sweep_f / 59.0
        scan_y = int((CCY - cur_h // 2 - 10) + (cur_h + 20) * t_sweep)
        scan_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(scan_layer)

        # Core laser line
        scan_w = int(cur_w * 0.85)
        s_draw.line(
            [(CCX - scan_w // 2, scan_y), (CCX + scan_w // 2, scan_y)],
            fill=(255, 255, 255, 240), width=2
        )
        # Amber scan halo
        s_draw.line(
            [(CCX - scan_w // 2 - 10, scan_y), (CCX + scan_w // 2 + 10, scan_y)],
            fill=(255, 170, 0, 160), width=4
        )
        scan_layer = scan_layer.filter(ImageFilter.GaussianBlur(radius=3))
        im = Image.alpha_composite(im, scan_layer)

    # ── STAGE 2: Smooth Glide Upward (Frames 120..149) ───────────────────────
    elif f < F_ZOOM_END:
        t = (f - F_SCAN_END) / float(F_ZOOM_END - F_SCAN_END)
        ease = math.sin(t * math.pi / 2.0) # Ease out

        cur_scale = S_INITIAL + (S_FINAL - S_INITIAL) * ease
        cur_y = int(CCY + (D_EMBLEM_Y - CCY) * ease)

        cur_w = int(ew * cur_scale * (140.0 / eh))
        cur_h = int(eh * cur_scale * (140.0 / eh))
        s_img = emblem_img.resize((cur_w, cur_h), Image.Resampling.LANCZOS)

        # Soft halo
        glow = s_img.resize((int(cur_w * 1.2), int(cur_h * 1.2)), Image.Resampling.LANCZOS)
        gw, gh = glow.size
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        g_layer.paste(glow, (CCX - gw // 2, cur_y - gh // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=8))
        im = Image.alpha_composite(im, g_layer)

        im.paste(s_img, (CCX - cur_w // 2, cur_y - cur_h // 2), s_img)

    # ── STAGE 3: Progressive Letter Reveal (Frames 150..195) ─────────────────
    elif f < F_TYPE_END:
        cur_w = int(ew * S_FINAL * (140.0 / eh))
        cur_h = int(eh * S_FINAL * (140.0 / eh))
        s_img = emblem_img.resize((cur_w, cur_h), Image.Resampling.LANCZOS)

        # Subtle stationary glow
        glow = s_img.resize((int(cur_w * 1.15), int(cur_h * 1.15)), Image.Resampling.LANCZOS)
        gw, gh = glow.size
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        g_layer.paste(glow, (CCX - gw // 2, D_EMBLEM_Y - gh // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=6))
        im = Image.alpha_composite(im, g_layer)

        im.paste(s_img, (CCX - cur_w // 2, D_EMBLEM_Y - cur_h // 2), s_img)

        # Determine step (1..10)
        t_step = (f - F_ZOOM_END) / float(F_TYPE_END - F_ZOOM_END)
        step_idx = min(9, int(t_step * 10))
        word_img = text_crops[step_idx]
        ww, wh = word_img.size

        # Center wordmark beneath emblem
        im.paste(word_img, (CCX - ww // 2, D_WORDMARK_Y - wh // 2), word_img)

    # ── STAGE 4: Final Locked Frame (Frames 196..202) ────────────────────────
    else:
        cur_w = int(ew * S_FINAL * (140.0 / eh))
        cur_h = int(eh * S_FINAL * (140.0 / eh))
        s_img = emblem_img.resize((cur_w, cur_h), Image.Resampling.LANCZOS)

        # Halo
        glow = s_img.resize((int(cur_w * 1.15), int(cur_h * 1.15)), Image.Resampling.LANCZOS)
        gw, gh = glow.size
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        g_layer.paste(glow, (CCX - gw // 2, D_EMBLEM_Y - gh // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=6))
        im = Image.alpha_composite(im, g_layer)

        im.paste(s_img, (CCX - cur_w // 2, D_EMBLEM_Y - cur_h // 2), s_img)

        # Full wordmark with amber bar strictly behind characters
        word_img = text_crops[-1]
        ww, wh = word_img.size
        im.paste(word_img, (CCX - ww // 2, D_WORDMARK_Y - wh // 2), word_img)

    # Save frame with standard 3-digit zero padding
    frame_name = f"frame-{f:03d}.png"
    out_file = os.path.join(OUTPUT_DIR, frame_name)
    im.save(out_file, "PNG", optimize=True)

print(f"4. Successfully generated all {TOTAL_FRAMES} frames in {OUTPUT_DIR}.")
