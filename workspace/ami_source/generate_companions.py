import os
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = "/tmp/askmeidentity-plymouth"
os.makedirs(OUTPUT_DIR, exist_ok=True)

FONT_MED = '/usr/share/fonts/julietaula-montserrat-fonts/Montserrat-Medium.otf'

# 1. branding_sub.png
W, H = 400, 30
SS = 2
bw, bh = W * SS, H * SS
b_im = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
b_draw = ImageDraw.Draw(b_im)
f_sub = ImageFont.truetype(FONT_MED, 11 * SS)

sub_text = "F E D O R A   O S"
sb = b_draw.textbbox((0, 0), sub_text, font=f_sub)
sx = (bw - (sb[2] - sb[0])) // 2
sy = (bh - (sb[3] - sb[1])) // 2
b_draw.text((sx, sy), sub_text, font=f_sub, fill=(148, 163, 184, 210))

sub_final = b_im.resize((W, H), Image.Resampling.LANCZOS)
sub_final.save(os.path.join(OUTPUT_DIR, "branding_sub.png"), "PNG", optimize=True)

# 2. progress_box.png (Track)
BAR_W, BAR_H = 320, 4
track_im = Image.new("RGBA", (BAR_W * SS, BAR_H * SS), (0, 0, 0, 0))
t_draw = ImageDraw.Draw(track_im)
r = 2 * SS
t_draw.rounded_rectangle([0, 0, BAR_W * SS - 1, BAR_H * SS - 1], radius=r, fill=(30, 41, 59, 220), outline=(51, 65, 85, 200), width=1*SS)
track_final = track_im.resize((BAR_W, BAR_H), Image.Resampling.LANCZOS)
track_final.save(os.path.join(OUTPUT_DIR, "progress_box.png"), "PNG", optimize=True)

# 3. progress_bar.png (Fill gradient Royal Blue -> Emerald Green)
fill_im = Image.new("RGBA", (BAR_W * SS, BAR_H * SS), (0, 0, 0, 0))
f_draw = ImageDraw.Draw(fill_im)

BLUE = (41, 98, 255)    # #2962FF
GREEN = (96, 176, 28)   # #60B01C

for x in range(BAR_W * SS):
    ratio = x / (BAR_W * SS)
    r_val = int(BLUE[0] + (GREEN[0] - BLUE[0]) * ratio)
    g_val = int(BLUE[1] + (GREEN[1] - BLUE[1]) * ratio)
    b_val = int(BLUE[2] + (GREEN[2] - BLUE[2]) * ratio)
    f_draw.line([(x, 0), (x, BAR_H * SS - 1)], fill=(r_val, g_val, b_val, 255))

mask = Image.new("L", (BAR_W * SS, BAR_H * SS), 0)
m_draw = ImageDraw.Draw(mask)
m_draw.rounded_rectangle([0, 0, BAR_W * SS - 1, BAR_H * SS - 1], radius=r, fill=255)
fill_im.putalpha(mask)

fill_final = fill_im.resize((BAR_W, BAR_H), Image.Resampling.LANCZOS)
fill_final.save(os.path.join(OUTPUT_DIR, "progress_bar.png"), "PNG", optimize=True)

print("Generated branding_sub.png, progress_box.png, and progress_bar.png successfully.")
