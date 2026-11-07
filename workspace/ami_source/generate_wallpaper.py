#!/usr/bin/env python3
import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import subprocess

WIDTH = 3840
HEIGHT = 2160
OUT_PATH = "/home/alvin/Pictures/Wallpapers/askmeidentity-obsidian.png"
SOURCE_SHIELD_SVG = "/home/alvin/Desktop/personal/custom_quickshell/workspace/ami_source/shield_only.svg"
SOURCE_TEXT_SVG = "/home/alvin/Desktop/personal/custom_quickshell/workspace/ami_source/text_step_12.svg"

os.makedirs("/home/alvin/Pictures/Wallpapers", exist_ok=True)
os.makedirs("/tmp/ami_wp", exist_ok=True)

print("1. Rendering official vector assets from SVG...")
shield_png = "/tmp/ami_wp/shield_trimmed_highres.png"
subprocess.run([
    "magick", "-background", "none", "-density", "1200",
    SOURCE_SHIELD_SVG, "-trim", "+repage", "-resize", "x680", shield_png
], check=True)

text_png = "/tmp/ami_wp/text_trimmed_highres.png"
subprocess.run([
    "magick", "-background", "none", "-density", "1200",
    SOURCE_TEXT_SVG, "-trim", "+repage", "-resize", "x84", text_png
], check=True)

shield_img = Image.open(shield_png).convert("RGBA")
text_img = Image.open(text_png).convert("RGBA")
sw, sh = shield_img.size
tw, th = text_img.size

print(f"Shield size: {sw}x{sh}, Text size: {tw}x{th}")

print("2. Generating obsidian canvas and deep cosmic vignette...")
# Base obsidian: #07090F
base_img = Image.new("RGBA", (WIDTH, HEIGHT), (7, 9, 15, 255))
radial_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
radial_draw = ImageDraw.Draw(radial_layer)

cx, cy = WIDTH // 2, HEIGHT // 2 - 40
max_radius = int(math.hypot(WIDTH, HEIGHT) / 2)

# Smooth deep navy radial bloom
for r in range(max_radius, 0, -15):
    factor = 1.0 - (r / max_radius)
    alpha = int(110 * (factor ** 1.9))
    r_val = int(7 + (16 - 7) * factor)
    g_val = int(9 + (26 - 9) * factor)
    b_val = int(15 + (48 - 15) * factor)
    radial_draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=(r_val, g_val, b_val, alpha)
    )

base_img = Image.alpha_composite(base_img, radial_layer)

print("3. Drawing cyber constellation & security grid...")
grid_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
grid_draw = ImageDraw.Draw(grid_layer)

spacing = 80
for x in range(spacing // 2, WIDTH, spacing):
    for y in range(spacing // 2, HEIGHT, spacing):
        dist = math.hypot(x - cx, y - cy)
        if 420 < dist < 1700:
            fade = math.sin((dist - 420) / 1280 * math.pi)
            dot_alpha = int(32 * fade)
            grid_draw.rectangle([x, y, x + 2, y + 2], fill=(41, 98, 255, dot_alpha))

random.seed(1337)
nodes = []
for _ in range(40):
    ang = random.uniform(0, 2 * math.pi)
    dist = random.uniform(500, 1600)
    nx = int(cx + dist * math.cos(ang))
    ny = int(cy + dist * math.sin(ang) * 0.72)
    nodes.append((nx, ny))

for i in range(len(nodes)):
    for j in range(i + 1, len(nodes)):
        d = math.hypot(nodes[i][0] - nodes[j][0], nodes[i][1] - nodes[j][1])
        if d < 280:
            line_alpha = int(28 * (1.0 - d / 280))
            grid_draw.line([nodes[i], nodes[j]], fill=(0, 240, 255, line_alpha), width=1)

for nx, ny in nodes:
    d = math.hypot(nx - cx, ny - cy)
    fade = 1.0 - (d / 1700)
    node_alpha = int(90 * max(0.2, fade))
    grid_draw.ellipse([nx - 3, ny - 3, nx + 3, ny + 3], fill=(0, 240, 255, node_alpha))
    grid_draw.ellipse([nx - 1, ny - 1, nx + 1, ny + 1], fill=(255, 255, 255, int(160 * fade)))

base_img = Image.alpha_composite(base_img, grid_layer)

print("4. Compositing glowing ambient aura behind shield...")
aura_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
aura_draw = ImageDraw.Draw(aura_layer)

aura_draw.ellipse([cx - 450, cy - 420, cx + 450, cy + 360], fill=(41, 98, 255, 60))
aura_draw.ellipse([cx - 280, cy - 250, cx + 280, cy + 220], fill=(0, 240, 255, 40))
aura_draw.ellipse([cx - 160, cy - 130, cx + 160, cy + 120], fill=(96, 176, 28, 35))
aura_layer = aura_layer.filter(ImageFilter.GaussianBlur(radius=80))
base_img = Image.alpha_composite(base_img, aura_layer)

print("5. Positioning Shield and official typography...")
shield_x = cx - sw // 2
shield_y = cy - sh // 2 - 70

# Shield ambient soft drop shadow
shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
shadow_mask = Image.new("RGBA", (sw, sh), (0, 0, 0, 210))
shadow.paste(shadow_mask, (shield_x, shield_y + 18), shield_img)
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=28))
base_img = Image.alpha_composite(base_img, shadow)

# Paste shield
base_img.paste(shield_img, (shield_x, shield_y), shield_img)

# Position text
text_x = cx - tw // 2
text_y = shield_y + sh + 55

# Text soft glow / shadow
text_shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
text_mask = Image.new("RGBA", (tw, th), (41, 98, 255, 90))
text_shadow.paste(text_mask, (text_x, text_y), text_img)
text_shadow = text_shadow.filter(ImageFilter.GaussianBlur(radius=12))
base_img = Image.alpha_composite(base_img, text_shadow)

base_img.paste(text_img, (text_x, text_y), text_img)

# 6. Minimalist Subtitle
sub_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
sub_draw = ImageDraw.Draw(sub_layer)

font_candidates = [
    "/usr/share/fonts/google-sans/GoogleSans-Medium.ttf",
    "/usr/share/fonts/inter/Inter-Medium.otf",
    "/usr/share/fonts/montserrat/Montserrat-SemiBold.ttf",
    "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf"
]
font_sub = None
for f in font_candidates:
    if os.path.exists(f):
        font_sub = ImageFont.truetype(f, 18)
        break
if not font_sub:
    font_sub = ImageFont.load_default()

tagline = "IDENTITY ARCHITECTURE & ACCESS INTELLIGENCE"
tag_spacing = 7
chars = list(tagline)
char_widths = [sub_draw.textbbox((0, 0), c, font=font_sub)[2] - sub_draw.textbbox((0, 0), c, font=font_sub)[0] for c in chars]
total_tag_w = sum(char_widths) + (len(chars) - 1) * tag_spacing
tag_x = cx - total_tag_w // 2
tag_y = text_y + th + 45

cur_x = tag_x
for i, c in enumerate(chars):
    sub_draw.text((cur_x, tag_y), c, font=font_sub, fill=(148, 163, 184, 190))
    cur_x += char_widths[i] + tag_spacing

# Bottom minimal watermark
tech_stamp = "FEDORA 44 // HYPRLAND // ZERO TRUST WORKSTATION"
stamp_spacing = 4
s_chars = list(tech_stamp)
s_widths = [sub_draw.textbbox((0, 0), c, font=font_sub)[2] - sub_draw.textbbox((0, 0), c, font=font_sub)[0] for c in s_chars]
total_s_w = sum(s_widths) + (len(s_chars) - 1) * stamp_spacing
s_x = cx - total_s_w // 2
s_y = HEIGHT - 85

cur_sx = s_x
for i, c in enumerate(s_chars):
    sub_draw.text((cur_sx, s_y), c, font=font_sub, fill=(100, 116, 139, 85))
    cur_sx += s_widths[i] + stamp_spacing

base_img = Image.alpha_composite(base_img, sub_layer)

print(f"6. Saving final 4K wallpaper to {OUT_PATH}...")
base_img.convert("RGB").save(OUT_PATH, "PNG", optimize=True)
print("Done! Wallpaper generated successfully.")
