import os
from PIL import Image, ImageDraw, ImageFont

SRC_DIR = "/home/alvin/Desktop/personal/custom_quickshell/workspace/arythmatic_source"
OUTPUT_DIR = os.path.join(SRC_DIR, "plymouth_theme")
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(SRC_DIR, exist_ok=True)

# 1. branding_sub.png
W, H = 400, 30
SS = 2
bw, bh = W * SS, H * SS
b_im = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
b_draw = ImageDraw.Draw(b_im)

try:
    f_sub = ImageFont.truetype("/usr/share/fonts/julietaula-montserrat-fonts/Montserrat-Medium.otf", 11 * SS)
except Exception:
    f_sub = ImageFont.load_default()

sub_text = "F E D O R A   O S"
sb = b_draw.textbbox((0, 0), sub_text, font=f_sub)
sx = (bw - (sb[2] - sb[0])) // 2
sy = (bh - (sb[3] - sb[1])) // 2
b_draw.text((sx, sy), sub_text, font=f_sub, fill=(160, 174, 192, 210))

sub_final = b_im.resize((W, H), Image.Resampling.LANCZOS)
sub_final.save(os.path.join(OUTPUT_DIR, "branding_sub.png"), "PNG", optimize=True)

# 2. progress_box.png (Track)
BAR_W, BAR_H = 320, 4
track_im = Image.new("RGBA", (BAR_W * SS, BAR_H * SS), (0, 0, 0, 0))
t_draw = ImageDraw.Draw(track_im)
r = 2 * SS
t_draw.rounded_rectangle([0, 0, BAR_W * SS - 1, BAR_H * SS - 1], radius=r, fill=(28, 35, 48, 220), outline=(48, 58, 76, 200), width=1*SS)
track_final = track_im.resize((BAR_W, BAR_H), Image.Resampling.LANCZOS)
track_final.save(os.path.join(OUTPUT_DIR, "progress_box.png"), "PNG", optimize=True)

# 3. progress_bar.png (Fill gradient Golden Amber #FFAA00 -> Radiant Orange #FF8C00)
fill_im = Image.new("RGBA", (BAR_W * SS, BAR_H * SS), (0, 0, 0, 0))
f_draw = ImageDraw.Draw(fill_im)

AMBER = (255, 170, 0)    # #FFAA00
ORANGE = (255, 120, 0)   # #FF7800

for x in range(BAR_W * SS):
    ratio = x / (BAR_W * SS)
    r_val = int(AMBER[0] + (ORANGE[0] - AMBER[0]) * ratio)
    g_val = int(AMBER[1] + (ORANGE[1] - AMBER[1]) * ratio)
    b_val = int(AMBER[2] + (ORANGE[2] - AMBER[2]) * ratio)
    f_draw.line([(x, 0), (x, BAR_H * SS - 1)], fill=(r_val, g_val, b_val, 255))

mask = Image.new("L", (BAR_W * SS, BAR_H * SS), 0)
m_draw = ImageDraw.Draw(mask)
m_draw.rounded_rectangle([0, 0, BAR_W * SS - 1, BAR_H * SS - 1], radius=r, fill=255)
fill_im.putalpha(mask)

fill_final = fill_im.resize((BAR_W, BAR_H), Image.Resampling.LANCZOS)
fill_final.save(os.path.join(OUTPUT_DIR, "progress_bar.png"), "PNG", optimize=True)

# Copy dialog companions from askmeidentity
import shutil
src_ami = "/usr/share/plymouth/themes/askmeidentity"
for f in ["box.png", "lock.png", "entry.png", "bullet.png", "capslock.png", "keyboard.png", "keymap-render.png"]:
    src_f = os.path.join(src_ami, f)
    if os.path.exists(src_f):
        shutil.copy2(src_f, os.path.join(OUTPUT_DIR, f))

print("Generated branding_sub.png, progress_box.png, progress_bar.png, and copied dialog assets successfully.")
