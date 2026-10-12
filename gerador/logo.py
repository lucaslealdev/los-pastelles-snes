# Converte a logo (PNG) em imagem indexada 256x224 com 15 cores para o SNES.
# Saida: gen/logo_idx.bin (256*224 bytes, indices 1..15) e gen/logo_pal.json
import json, os, sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = [f for f in os.listdir(ROOT) if f.lower().endswith('.png') and 'pastelles' in f.lower()]
if not src:
    sys.exit('logo nao encontrada')
im = Image.open(os.path.join(ROOT, src[0])).convert('RGB')

# recorta pelo conteudo (tudo que difere do fundo creme)
bg = im.getpixel((5, 5))
W, H = im.size
px = im.load()
xs, ys = [], []
for y in range(0, H, 2):
    for x in range(0, W, 2):
        r, g, b = px[x, y]
        if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) > 60:
            xs.append(x); ys.append(y)
box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
im = im.crop(box)

ALT = 176
w = round(im.width * ALT / im.height)
im = im.resize((w, ALT), Image.LANCZOS)

canvas = Image.new('RGB', (256, 224), bg)
canvas.paste(im, ((256 - w) // 2, 2))

# achata tons proximos do fundo creme para nao gastar cores da paleta
cp = canvas.load()
for y in range(224):
    for x in range(256):
        r, g, b = cp[x, y]
        if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) < 36:
            cp[x, y] = bg
q = canvas.quantize(colors=15, method=Image.MEDIANCUT, kmeans=4, dither=Image.FLOYDSTEINBERG)
pal = q.getpalette()[:45]
cores = ['#%02X%02X%02X' % tuple(pal[i * 3:i * 3 + 3]) for i in range(15)]
idx = bytes(v + 1 for v in q.tobytes())
os.makedirs(os.path.join(ROOT, 'gen'), exist_ok=True)
open(os.path.join(ROOT, 'gen', 'logo_idx.bin'), 'wb').write(idx)
# indice da cor de fundo (para o texto do menu)
fundo = idx[223 * 256 + 2]
json.dump({'cores': cores, 'fundo': fundo}, open(os.path.join(ROOT, 'gen', 'logo_pal.json'), 'w'))
print('logo:', w, 'x', ALT, 'cores', cores)
