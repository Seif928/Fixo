"""Export the app's existing FixoBrandMark glyph (no new logo or remote art).

Usage: python tool/generate_brand_icons.py <Flutter SDK>/bin/cache/artifacts/material_fonts/materialicons-regular.otf
Requires Pillow. Material Icons is supplied and licensed by the Flutter SDK.
"""
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
font_path = sys.argv[1]

def icon(size: int, maskable: bool = False) -> Image.Image:
    scale = 4
    canvas = Image.new('RGB', (size * scale, size * scale), '#173F35')
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(font_path, int(size * scale * (.55 if maskable else .625)))
    glyph = chr(0xF7CC)  # Icons.handyman_rounded, matching FixoBrandMark.
    box = draw.textbbox((0, 0), glyph, font=font)
    draw.text(((size * scale - box[2] - box[0]) / 2,
               (size * scale - box[3] - box[1]) / 2), glyph,
              font=font, fill='#D5EE76')
    return canvas.resize((size, size), Image.Resampling.LANCZOS)

targets = [ROOT / 'web/favicon.png']
targets += list((ROOT / 'web/icons').glob('*.png'))
targets += list((ROOT / 'android/app/src/main/res').glob('mipmap-*/ic_launcher.png'))
targets += list((ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset').glob('*.png'))
for target in targets:
    with Image.open(target) as original:
        size = original.width
        if size != original.height:
            raise ValueError(f'Expected square app icon: {target.name}')
    icon(size, 'maskable' in target.name).save(target)
print(f'Exported {len(targets)} FIXO brand icons.')
