# Narracao do trailer (edge-tts, pt-BR)
import asyncio, os, edge_tts
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'trailer', 'audio'); os.makedirs(OUT, exist_ok=True)
VOZ = 'pt-BR-AntonioNeural'
FALAS = [
    ('v1', 'Todo grande império... começa com uma primeira venda.'),
    ('v2', 'Los Pastelles: O Império do Pastel! Um jogo novo, de verdade, para o seu Super Nintendo!'),
    ('v3', 'Feche o pastel no combo de botões... e tire do óleo no ponto certo!'),
    ('v4', 'Crianças com pressa, idosos pacientes e turistas que pagam mais!'),
    ('v5', 'O telefone toca, o aplicativo apita... e o motoboy sai buzinando!'),
    ('v6', 'Reforme a pastelaria, abra lojas em cinco bairros e venda franquias!'),
    ('v7', 'Administre o caixa, compre equipamentos e conquiste dezesseis troféus!'),
    ('v8', 'Cartucho com bateria, três jogos salvos e música de dezesseis bits.'),
    ('v9', 'Los Pastelles: O Império do Pastel. Garanta já o seu cartucho!'),
]
async def main():
    for nome, texto in FALAS:
        await edge_tts.Communicate(texto, VOZ, rate='+8%', pitch='+2Hz').save(os.path.join(OUT, nome + '.mp3'))
        print('voz', nome)
asyncio.run(main())
