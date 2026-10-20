"""Render the exported frame tree for offline layout inspection (not a game screenshot)."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = 'C:/Windows/Fonts/msyh.ttc'
SCALE = 2
LAYERS = {'BACKGROUND': 0, 'BORDER': 1, 'ARTWORK': 2, 'OVERLAY': 3}

def render(path):
    scene = json.loads(path.read_text('utf-8'))
    width, height = scene['width'], scene['height']
    canvas = Image.new('RGBA', (round(width*SCALE), round(height*SCALE)), '#101010')
    nodes = sorted(scene['nodes'], key=lambda n: (n['level'], LAYERS[n['layer']], n['sub'], n['order']))
    for node in nodes:
        x, y, w, h = node['rect']
        if w <= 0 or h <= 0:
            continue
        clip = [0, 0, width, height]
        for cx, cy, cw, ch in node['clips']:
            clip = [max(clip[0], cx), max(clip[1], cy), min(clip[2], cx+cw), min(clip[3], cy+ch)]
        if clip[2] <= clip[0] or clip[3] <= clip[1]:
            continue
        layer = Image.new('RGBA', canvas.size)
        draw = ImageDraw.Draw(layer)
        rgba = node.get('color', [1, 1, 1, 1])
        rgba = rgba + [1] * (4-len(rgba))
        color = tuple(round(min(1, max(0, c))*255) for c in rgba[:3]) + (round(rgba[3]*node['alpha']*255),)
        if node['kind'] == 'Texture':
            draw.rectangle((round(x*SCALE), round(y*SCALE), round((x+w)*SCALE)-1, round((y+h)*SCALE)-1), fill=color)
        else:
            text = node.get('text', '').replace('||', '|')
            font = ImageFont.truetype(FONT, round(node.get('size', 14)*SCALE))
            # WoW FontString handles this with SetMaxLines(1), without cutting UTF-8 bytes.
            if node.get('clamp') and draw.textlength(text, font=font) > w*SCALE:
                while text and draw.textlength(text+'...', font=font) > w*SCALE:
                    text = text[:-1]
                text += '...'
            tw = draw.textlength(text, font=font)
            tx = x*SCALE + (w*SCALE-tw if node.get('justify') == 'RIGHT' else 0)
            draw.text((tx, y*SCALE+(h*SCALE)/2), text, font=font, fill=color, anchor='lm')
        bounds = tuple(round(v*SCALE) for v in clip)
        region = layer.crop(bounds)
        canvas.alpha_composite(region, (bounds[0], bounds[1]))
    target = path.with_suffix('.png')
    canvas.convert('RGB').save(target)
    canvas.convert('RGB').resize((round(width), round(height)), Image.Resampling.LANCZOS).save(
        path.with_name(path.stem + '-preview.png'))
    print(target)

for path in (ROOT/'test'/'output').glob('layout-*.json'):
    render(path)
