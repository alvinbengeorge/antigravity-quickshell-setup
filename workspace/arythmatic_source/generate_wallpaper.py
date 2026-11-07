#!/usr/bin/env python3
"""
Arythmatic Ultra-HD 4K Wallpaper Generator
Generates luxury obsidian wallpaper with glowing mathematical amber aesthetics.
"""

import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import subprocess

WIDTH = 3840
HEIGHT = 2160
OUT_PATH = "/home/alvin/Pictures/Wallpapers/arythmatic-obsidian.png"
SRC_DIR = "/home/alvin/Desktop/personal/custom_quickshell/workspace/arythmatic_source"
ICON_SVG = os.path.join(SRC_DIR, "icon.svg")
LOGO_SVG = os.path.join(SRC_DIR, "logo_fixed_layering.svg")

os.makedirs("/home/alvin/Pictures/Wallpapers", exist_ok=True)
os.makedirs("/tmp/arythmatic_wp", exist_ok=True)

print("1. Rendering vector assets from SVG...")
icon_png = "/tmp/arythmatic_wp/icon_trimmed_highres.png"
subprocess.run([
    "magick", "-background", "none", "-density", "1200",
    ICON_SVG, "-trim", "+repage", "-resize", "x540", icon_png
], check=True)

logo_png = "/tmp/arythmatic_wp/logo_trimmed_highres.png"
subprocess.run([
    "magick", "-background", "none", "-density", "1200",
    LOGO_SVG, "-trim", "+repage", "-resize", "x130", logo_png
], check=True)

icon_img = Image.open(icon_png).convert("RGBA")
logo_img = Image.open(logo_png).convert("RGBA")
iw, ih = icon_img.size
lw, lh = logo_img.size

print(f"Icon size: {iw}x{ih}, Logo size: {lw}x{lh}")

print("2. Generating obsidian canvas and deep warm amber vignette...")
# Base obsidian dark: #080B10 (matches deep cosmic dark)
base_img = Image.new("RGBA", (WIDTH, HEIGHT), (8, 11, 16, 255))
radial_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
radial_draw = ImageDraw.Draw(radial_layer)

cx, cy = WIDTH // 2, HEIGHT // 2 - 60
max_radius = int(math.hypot(WIDTH, HEIGHT) / 2)

# Smooth golden amber / espresso radial bloom
for r in range(max_radius, 0, -18):
    factor = 1.0 - (r / max_radius)
    alpha = int(120 * (factor ** 2.2))
    r_val = int(8 + (255 - 8) * factor * 0.45)
    g_val = int(11 + (170 - 11) * factor * 0.35)
    b_val = int(16 + (30 - 16) * factor * 0.20)
    radial_draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=(r_val, g_val, b_val, alpha)
    )

base_img = Image.alpha_composite(base_img, radial_layer)

print("3. Drawing mathematical matrix & constellation grid...")
grid_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
grid_draw = ImageDraw.Draw(grid_layer)

# Isometric / arithmetic grid dots
spacing = 75
for x in range(spacing // 2, WIDTH, spacing):
    for y in range(spacing // 2, HEIGHT, spacing):
        dist = math.hypot(x - cx, y - cy)
        if 400 < dist < 1750:
            fade = math.sin((dist - 400) / 1350 * math.pi)
            dot_alpha = int(35 * fade)
            grid_draw.rectangle([x, y, x + 2, y + 2], fill=(255, 170, 0, dot_alpha))

# Constellation nodes & geometric connectives
random.seed(4242)
nodes = []
for _ in range(45):
    ang = random.uniform(0, 2 * math.pi)
    dist = random.uniform(480, 1650)
    nx = int(cx + dist * math.cos(ang))
    ny = int(cy + dist * math.sin(ang) * 0.75)
    nodes.append((nx, ny))

for i in range(len(nodes)):
    for j in range(i + 1, len(nodes)):
        d = math.hypot(nodes[i][0] - nodes[j][0], nodes[i][1] - nodes[j][1])
        if d < 260:
            line_alpha = int(24 * (1.0 - d / 260))
            grid_draw.line([nodes[i], nodes[j]], fill=(255, 180, 20, line_alpha), width=1)

for nx, ny in nodes:
    d = math.hypot(nx - cx, ny - cy)
    fade = 1.0 - (d / 1750)
    node_alpha = int(85 * max(0.2, fade))
    grid_draw.ellipse([nx - 3, ny - 3, nx + 3, ny + 3], fill=(255, 170, 0, node_alpha))
    grid_draw.ellipse([nx - 1, ny - 1, nx + 1, ny + 1], fill=(255, 255, 255, int(150 * fade)))

base_img = Image.alpha_composite(base_img, grid_layer)

print("4. Compositing glowing ambient aura behind emblem...")
aura_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
aura_draw = ImageDraw.Draw(aura_layer)

# Multi-layered golden aura
for radius, alpha, fill_col in [
    (520, 25, (255, 170, 0)),
    (380, 45, (255, 160, 0)),
    (260, 75, (255, 185, 30)),
    (160, 110, (255, 210, 80))
]:
    layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(*fill_col, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(radius=radius // 3))
    aura_layer = Image.alpha_composite(aura_layer, layer)

base_img = Image.alpha_composite(base_img, aura_layer)

print("5. Rendering emblem neon bloom...")
bloom_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
ix = cx - iw // 2
iy = cy - ih // 2

# Wide glow
wide_glow = icon_img.resize((int(iw * 1.3), int(ih * 1.3)), Image.Resampling.LANCZOS)
gw, gh = wide_glow.size
g_canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
g_canvas.paste(wide_glow, (cx - gw // 2, cy - gh // 2), wide_glow)
g_canvas = g_canvas.filter(ImageFilter.GaussianBlur(radius=36))

# Tight crisp neon halo
tight_glow = icon_img.resize((int(iw * 1.08), int(ih * 1.08)), Image.Resampling.LANCZOS)
tw, th = tight_glow.size
t_canvas = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
t_canvas.paste(tight_glow, (cx - tw // 2, cy - th // 2), tight_glow)
t_canvas = t_canvas.filter(ImageFilter.GaussianBlur(radius=10))

base_img = Image.alpha_composite(base_img, g_canvas)
base_img = Image.alpha_composite(base_img, t_canvas)

# Paste primary emblem
base_img.paste(icon_img, (ix, iy), icon_img)

print("6. Rendering typography & sub-caption...")
lx = cx - lw // 2
ly = cy + ih // 2 + 50
base_img.paste(logo_img, (lx, ly), logo_img)

# Sub-caption: "ACADEMY INFRASTRUCTURE & LMS PLATFORM"
caption_text = "E D U C A T I O N A L   I N F R A S T R U C T U R E   •   L M S   P L A T F O R M"
draw = ImageDraw.Draw(base_img)
try:
    font = ImageFont.truetype("/usr/share/fonts/google-noto-sans-vf-fonts/NotoSans-VF.ttf", 32)
except Exception:
    font = ImageFont.load_default()

bbox = draw.textbbox((0, 0), caption_text, font=font)
cap_w = bbox[2] - bbox[0]
draw.text((cx - cap_w // 2, ly + lh + 36), caption_text, font=font, fill=(180, 195, 215, 220))

print(f"7. Saving final 4K wallpaper to {OUT_PATH} and workspace...")
base_rgb = base_img.convert("RGB")
base_rgb.save(OUT_PATH, "PNG", quality=98)
base_rgb.save(os.path.join(SRC_DIR, "arythmatic-obsidian.png"), "PNG", quality=98)
print("Done! Wallpaper generated successfully.")
