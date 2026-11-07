import math
import os
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFilter

SRC_DIR = "/home/alvin/Desktop/personal/custom_quickshell/workspace/ami_source"
SVG_FILE = os.path.join(SRC_DIR, "logo.svg")
OUTPUT_DIR = "/tmp/askmeidentity-plymouth"
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(SRC_DIR, exist_ok=True)

# 1. Parse original SVG
tree = ET.parse(SVG_FILE)
root = tree.getroot()
ET.register_namespace('', 'http://www.w3.org/2000/svg')
defs = root.find('{http://www.w3.org/2000/svg}defs')
paths = root.findall('.//{http://www.w3.org/2000/svg}path')

print("Extracting and rendering SVG letter steps...")

# Render Shield SVG (paths 13 to 18)
shield_svg = ET.Element('{http://www.w3.org/2000/svg}svg', {
    'width': '240', 'height': '41', 'viewBox': '0 0 240 41', 'fill': 'none'
})
g_shield = ET.SubElement(shield_svg, '{http://www.w3.org/2000/svg}g')
for p in paths[13:19]:
    g_shield.append(p)
shield_svg.append(defs)

shield_svg_path = os.path.join(SRC_DIR, "shield_only.svg")
shield_png_path = os.path.join(SRC_DIR, "shield_only.png")
ET.ElementTree(shield_svg).write(shield_svg_path)
os.system(f"magick -background none -density 400 {shield_svg_path} {shield_png_path}")

# Render cumulative letter SVGs (13 steps)
for k in range(13):
    step_svg = ET.Element('{http://www.w3.org/2000/svg}svg', {
        'width': '240', 'height': '41', 'viewBox': '0 0 240 41', 'fill': 'none'
    })
    g_step = ET.SubElement(step_svg, '{http://www.w3.org/2000/svg}g')
    for p in paths[:k+1]:
        g_step.append(p)
    step_svg_path = os.path.join(SRC_DIR, f"text_step_{k}.svg")
    step_png_path = os.path.join(SRC_DIR, f"text_step_{k}.png")
    ET.ElementTree(step_svg).write(step_svg_path)
    os.system(f"magick -background none -density 400 {step_svg_path} {step_png_path}")

print("Pre-rendering animation frames...")

shield_canvas = Image.open(shield_png_path).convert("RGBA")
tight_shield = shield_canvas.crop((25, 12, 141, 159))
sw, sh = tight_shield.size # (116, 147)

text_crops = []
for k in range(13):
    step_im = Image.open(os.path.join(SRC_DIR, f"text_step_{k}.png")).convert("RGBA")
    tc = step_im.crop((25, 12, 874, 159))
    text_crops.append(tc)

CW, CH = 540, 220
CCX, CCY = CW // 2, CH // 2

S_INITIAL = 1.15
S_FINAL = 0.56
X_DOCKED = CCX + int((83 - 449.5) * S_FINAL) # ~65

# Timing:
# Stage 1: Shield Solo Scan (Frames 0..119, 120 frames = ~3-4s hold!)
# Stage 2: Zoom & Glide (Frames 120..149, 30 frames = ~1s smooth ease)
# Stage 3: Letter reveal (Frames 150..201, 52 frames = 13 letters * 4 frames each)
# Stage 4: Final locked frame (Frame 202)
F_SCAN_END = 120
F_ZOOM_END = 150
F_TYPE_END = 202
TOTAL_FRAMES = 203

for f in range(TOTAL_FRAMES):
    im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    
    # ── STAGE 1: Shield Solo + 2 Biometric Laser Passes (Frames 0..119) ──────
    if f < F_SCAN_END:
        sweep_frame = f % 60
        t_sweep = sweep_frame / 59.0 # 0 to 1
        
        pulse = (math.sin((f / 60.0) * 2 * math.pi) + 1.0) / 2.0
        
        s_w = int(sw * S_INITIAL)
        s_h = int(sh * S_INITIAL)
        s_img = tight_shield.resize((s_w, s_h), Image.Resampling.LANCZOS)
        
        glow_scale = 1.3 + 0.1 * pulse
        glow_w = int(s_w * glow_scale)
        glow_h = int(s_h * glow_scale)
        glow = s_img.resize((glow_w, glow_h), Image.Resampling.LANCZOS)
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        g_layer.paste(glow, (CCX - glow_w // 2, CCY - glow_h // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=int(12 + 4 * pulse)))
        im = Image.alpha_composite(im, g_layer)
        
        im.paste(s_img, (CCX - s_w // 2, CCY - s_h // 2), s_img)
        
        scan_y = int((CCY - s_h // 2) + s_h * t_sweep)
        
        scan_im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(scan_im)
        line_w = int(s_w * 0.95)
        lx1 = CCX - line_w // 2
        lx2 = CCX + line_w // 2
        s_draw.line([(lx1, scan_y), (lx2, scan_y)], fill=(103, 232, 249, 240), width=2)
        s_draw.line([(lx1 - 10, scan_y), (lx2 + 10, scan_y)], fill=(6, 182, 212, 160), width=5)
        scan_glow = scan_im.filter(ImageFilter.GaussianBlur(radius=3))
        im = Image.alpha_composite(im, scan_glow)
        im = Image.alpha_composite(im, scan_im)

    # ── STAGE 2: Zoom & Glide (Frames 120..149) ──────────────────────────────
    elif f < F_ZOOM_END:
        progress = (f - F_SCAN_END) / float(F_ZOOM_END - F_SCAN_END - 1)
        ease = progress * progress * (3.0 - 2.0 * progress)
        
        cur_scale = S_INITIAL + (S_FINAL - S_INITIAL) * ease
        cur_cx = CCX + int((X_DOCKED - CCX) * ease)
        cur_cy = CCY
        
        s_w = int(sw * cur_scale)
        s_h = int(sh * cur_scale)
        s_img = tight_shield.resize((s_w, s_h), Image.Resampling.LANCZOS)
        
        glow = s_img.resize((int(s_w * 1.25), int(s_h * 1.25)), Image.Resampling.LANCZOS)
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        g_layer.paste(glow, (cur_cx - glow.width // 2, cur_cy - glow.height // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=9))
        im = Image.alpha_composite(im, g_layer)
        
        im.paste(s_img, (cur_cx - s_w // 2, cur_cy - s_h // 2), s_img)

    # ── STAGE 3: Slow Deliberate Letter-by-Letter Reveal (Frames 150..201) ───
    elif f < F_TYPE_END:
        s_w = int(sw * S_FINAL)
        s_h = int(sh * S_FINAL)
        s_img = tight_shield.resize((s_w, s_h), Image.Resampling.LANCZOS)
        
        step_idx = min(12, (f - F_ZOOM_END) // 4)
        sub_frame = (f - F_ZOOM_END) % 4
        
        t_crop = text_crops[step_idx]
        tw_scaled = int(t_crop.width * S_FINAL)
        th_scaled = int(t_crop.height * S_FINAL)
        t_img = t_crop.resize((tw_scaled, th_scaled), Image.Resampling.LANCZOS)
        
        logo_x = CCX - int(849 * S_FINAL) // 2
        logo_y = CCY - th_scaled // 2
        
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        glow = s_img.resize((int(s_w * 1.2), int(s_h * 1.2)), Image.Resampling.LANCZOS)
        g_layer.paste(glow, (X_DOCKED - glow.width // 2, CCY - glow.height // 2), glow)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=8))
        im = Image.alpha_composite(im, g_layer)
        
        im.paste(s_img, (X_DOCKED - s_w // 2, CCY - s_h // 2), s_img)
        im.paste(t_img, (logo_x, logo_y), t_img)
        
        if sub_frame < 2:
            glint_im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            g_draw = ImageDraw.Draw(glint_im)
            char_ratio = (step_idx + 0.5) / 13.0
            glint_x = logo_x + int(140 * S_FINAL) + int((700 * S_FINAL) * char_ratio)
            glint_y = CCY
            color = (103, 232, 249, 190) if step_idx < 5 else (140, 240, 60, 190)
            g_draw.ellipse([glint_x - 10, glint_y - 10, glint_x + 10, glint_y + 10], fill=color)
            glint_blur = glint_im.filter(ImageFilter.GaussianBlur(radius=5))
            im = Image.alpha_composite(im, glint_blur)

    # ── STAGE 4: Final Locked Assembled State (Frame 202) ────────────────────
    else:
        tw_scaled = int(text_crops[12].width * S_FINAL)
        th_scaled = int(text_crops[12].height * S_FINAL)
        
        composed = Image.alpha_composite(shield_canvas, Image.open(os.path.join(SRC_DIR, "text_step_12.png")).convert("RGBA"))
        full_crop = composed.crop((25, 12, 874, 159))
        full_scaled = full_crop.resize((tw_scaled, th_scaled), Image.Resampling.LANCZOS)
        
        logo_x = CCX - tw_scaled // 2
        logo_y = CCY - th_scaled // 2
        
        glow_im = full_scaled.resize((int(tw_scaled * 1.08), int(th_scaled * 1.25)), Image.Resampling.LANCZOS)
        g_layer = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        gx = CCX - glow_im.width // 2
        gy = CCY - glow_im.height // 2
        g_layer.paste(glow_im, (gx, gy), glow_im)
        g_layer = g_layer.filter(ImageFilter.GaussianBlur(radius=12))
        
        im = Image.alpha_composite(im, g_layer)
        im.paste(full_scaled, (logo_x, logo_y), full_scaled)
        
    im.save(os.path.join(OUTPUT_DIR, f"frame-{f:03d}.png"), "PNG", optimize=True)

print(f"Generated {TOTAL_FRAMES} frames successfully in {OUTPUT_DIR}!")
