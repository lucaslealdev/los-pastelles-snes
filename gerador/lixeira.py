# Quadros-chave da animacao de erro (melhoria 11): o pastel que abriu no
# minijogo cai na lixeira. Referencia de composicao: arte_fonte/lixeira/
# gemini_referencia.png (gerada no Gemini). A arte e desenhada aqui em pixel art
# (pastel aberto, lata e tampa) mais o emoji 💨 (Twemoji) para a poeirinha.
#
# Saida neutra, ainda fora do build (o morph e o player vem da melhoria 10):
#   gen/lixeira/camadas/<nome>.png   cada camada solta (RGBA, contorno escuro)
#   gen/lixeira/quadros.json         5 quadros-chave: camadas com x, y (centro),
#                                    angulo (graus), escala e recorte
#   gen/lixeira/quadro_<n>.png       cada quadro-chave montado (QUADRO x QUADRO)
#   gen/lixeira/tira.png             os 5 lado a lado, ampliados (conferencia)
# Uso: python3 gerador/lixeira.py
import json, os
from PIL import Image
from icones import icone, ROOT, CONTORNO

QUADRO = 64                                 # tamanho de cada quadro (px)
SAIDA = os.path.join(ROOT, 'gen', 'lixeira')

# cores (mesma familia do pastel do jogo: dourado, sombra e recheio)
C = {
    'k': CONTORNO, 'o1': (248, 208, 96), 'o2': (232, 160, 48), 'o3': (184, 112, 24),
    'r1': (160, 56, 32), 'r2': (104, 40, 24), 'r3': (200, 96, 48),
    'g1': (200, 208, 216), 'g2': (152, 160, 176), 'g3': (104, 112, 128), 'g4': (64, 72, 88),
    'w': (248, 248, 248),
}


def desenha(linhas, mapa):
    h, w = len(linhas), max(len(l) for l in linhas)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for y, l in enumerate(linhas):
        for x, ch in enumerate(l):
            if ch in mapa:
                im.putpixel((x, y), C[mapa[ch]] + (255,))
    return im


def contorno(im):
    # contorno escuro de 1 px em volta (como os icones e os sprites de emoji)
    w, h = im.size
    out = Image.new('RGBA', (w + 2, h + 2), (0, 0, 0, 0))
    out.paste(im, (1, 1))
    px = out.load()
    cheio = [[px[x, y][3] > 0 for x in range(w + 2)] for y in range(h + 2)]
    for y in range(h + 2):
        for x in range(w + 2):
            if not cheio[y][x] and any(0 <= x + dx < w + 2 and 0 <= y + dy < h + 2 and cheio[y + dy][x + dx]
                                       for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                px[x, y] = CONTORNO + (255,)
    return out


# pastel aberto (meia-lua dourada com a borda de garfo; a massa rachou e o
# recheio aparece/vaza pela abertura)
PASTEL = [
    '.......aaaaaaaaaa.......',
    '....aaabbbbbbbbbbaaa....',
    '..aabbbbbbbbbbbbbbbbaa..',
    '.abbbbbbbbbbbbbbbbbbbba.',
    'abbbbbbbbbbbbbbbbbbbbbba',
    'abbbbbbbbbrrrrbbbbbbbbba',
    'abbbbbbbrRRRRRRrbbbbbbba',
    'cbcbcbcrRRsRRsRRrcbcbcbc',
    '.cbcbcrRRRRRRRRRRrcbcbc.',
    '..ccc..rRRsRRRRRr..ccc..',
    '........rRRRRsRr........',
    '.........rRRRRr.........',
    '...........rr...........',
]
PASTEL_MAPA = {'a': 'o1', 'b': 'o2', 'c': 'o3', 'r': 'r1', 'R': 'r2', 's': 'r3'}

# lata de lixo (corpo com frisos) e tampa separada (ela gira para abrir/fechar)
LATA = [
    'aaaaaaaaaaaaaaaaaaaa',
    'abcbbcbbcbbcbbcbbcba',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '.bcbbcbbcbbcbbcbbcb.',
    '..dddddddddddddddd..',
]
LATA_MAPA = {'a': 'g1', 'b': 'g2', 'c': 'g3', 'd': 'g4'}
TAMPA = [
    '........aa........',
    '.......abba.......',
    '..aaaaaaaaaaaaaa..',
    'abbbbbbbbbbbbbbbba',
    'cccccccccccccccccc',
]
TAMPA_MAPA = {'a': 'g1', 'b': 'g2', 'c': 'g3'}


def camadas():
    poeira = icone('1f4a8')                                 # 💨 (16x16 ja com contorno)
    return {
        'pastel': desenha(PASTEL, PASTEL_MAPA),
        'lata': desenha(LATA, LATA_MAPA),
        'tampa': desenha(TAMPA, TAMPA_MAPA),
        'poeira': poeira,
        'farelo': desenha(['ab', 'b.'], {'a': 'o2', 'b': 'r1'}),
    }


# quadros-chave. Cada camada: nome, x, y (centro no quadro), angulo (graus,
# anti-horario), escala, e 'atras': desenhada antes da lata (o pastel entrando
# fica escondido pela borda). A tampa gira em volta da dobradica (canto esquerdo).
LATA_XY = (34, 50)
TAMPA_FECHADA = (34, 40, 0)
TAMPA_ABERTA = (21, 34, 80)          # em pe na borda esquerda da lata
QUADROS = [
    {'nome': 'abriu', 'camadas': [
        {'c': 'pastel', 'x': 18, 'y': 12, 'ang': 0, 'esc': 1},
        {'c': 'farelo', 'x': 22, 'y': 24, 'ang': 0, 'esc': 1},
        {'c': 'tampa', 'x': TAMPA_ABERTA[0], 'y': TAMPA_ABERTA[1], 'ang': TAMPA_ABERTA[2], 'esc': 1},
    ]},
    {'nome': 'caindo', 'camadas': [
        {'c': 'pastel', 'x': 26, 'y': 16, 'ang': -35, 'esc': 1},
        {'c': 'farelo', 'x': 18, 'y': 22, 'ang': 0, 'esc': 1},
        {'c': 'farelo', 'x': 22, 'y': 30, 'ang': 0, 'esc': 1},
        {'c': 'tampa', 'x': TAMPA_ABERTA[0], 'y': TAMPA_ABERTA[1], 'ang': TAMPA_ABERTA[2], 'esc': 1},
    ]},
    {'nome': 'sobre_a_lata', 'camadas': [
        {'c': 'pastel', 'x': 36, 'y': 24, 'ang': -110, 'esc': 1},
        {'c': 'tampa', 'x': TAMPA_ABERTA[0], 'y': TAMPA_ABERTA[1], 'ang': TAMPA_ABERTA[2], 'esc': 1},
    ]},
    {'nome': 'entrando', 'camadas': [
        {'c': 'pastel', 'x': 35, 'y': 40, 'ang': -160, 'esc': 1, 'atras': True},
        {'c': 'tampa', 'x': 26, 'y': 37, 'ang': 35, 'esc': 1},
    ]},
    {'nome': 'tampa_fechada', 'camadas': [
        {'c': 'tampa', 'x': TAMPA_FECHADA[0], 'y': TAMPA_FECHADA[1], 'ang': 0, 'esc': 1},
        {'c': 'poeira', 'x': 46, 'y': 30, 'ang': 0, 'esc': 1},
    ]},
]


def transforma(im, ang, esc, nome):
    if esc != 1:
        im = im.resize((round(im.width * esc), round(im.height * esc)), Image.NEAREST)
    if ang:
        im = im.rotate(ang, resample=Image.NEAREST, expand=True)   # sem borrar: so pixels inteiros
    # contorno depois de girar (girado junto ele fica serrilhado); o emoji ja tem
    return im if nome == 'poeira' else contorno(im)


def monta(q, cam):
    out = Image.new('RGBA', (QUADRO, QUADRO), (0, 0, 0, 0))
    def cola(nome, x, y, ang=0, esc=1):
        im = transforma(cam[nome], ang, esc, nome)
        out.alpha_composite(im, (x - im.width // 2, y - im.height // 2))
    for l in q['camadas']:
        if l.get('atras'):
            cola(l['c'], l['x'], l['y'], l['ang'], l['esc'])
    cola('lata', *LATA_XY)
    for l in q['camadas']:
        if not l.get('atras'):
            cola(l['c'], l['x'], l['y'], l['ang'], l['esc'])
    return out


def main():
    os.makedirs(os.path.join(SAIDA, 'camadas'), exist_ok=True)
    cam = camadas()
    for n, im in cam.items():
        (im if n == 'poeira' else contorno(im)).save(os.path.join(SAIDA, 'camadas', n + '.png'))
    quadros = [monta(q, cam) for q in QUADROS]
    for i, im in enumerate(quadros):
        im.save(os.path.join(SAIDA, 'quadro_%d.png' % (i + 1)))
    json.dump({'quadro': QUADRO, 'lata': {'c': 'lata', 'x': LATA_XY[0], 'y': LATA_XY[1]},
               'quadros': QUADROS}, open(os.path.join(SAIDA, 'quadros.json'), 'w'), indent=1, ensure_ascii=False)
    # tira de conferencia: fundo creme, ampliada 4x
    z = 4
    tira = Image.new('RGBA', (QUADRO * 5 * z + 4 * z * 4, QUADRO * z), (255, 248, 236, 255))
    for i, im in enumerate(quadros):
        tira.alpha_composite(im.resize((QUADRO * z, QUADRO * z), Image.NEAREST), (i * (QUADRO + 4) * z, 0))
    tira.save(os.path.join(SAIDA, 'tira.png'))
    print('lixeira: %d quadros-chave em %s' % (len(quadros), SAIDA))


if __name__ == '__main__':
    main()
