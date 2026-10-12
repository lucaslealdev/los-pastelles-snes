# Sintetiza as musicas do jogo em WAV (para o trailer), a partir das mesmas
# partituras que vao para a ROM (gerador/audio.js).
import json, os, subprocess, sys, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RATE = 32000
dados = json.loads(subprocess.check_output(['node', '-e', '''
const A=require("./gerador/audio");
const m=A.musicData();
console.log(JSON.stringify({songs:m.songs, inst:A.INSTR}));
'''], cwd=ROOT))

def onda(sample, n):
    t = (np.arange(n) % 32) / 32.0
    if sample == 0: return np.where(t < 0.5, 0.8, -0.8)
    if sample == 2: return np.where(t < 0.25, 0.8, -0.8)
    return 1.6 * (np.abs(((t + 0.25) % 1.0) - 0.5) * 2 - 0.5)   # triangulo

def envelope(adsr2, n):
    sl = (((adsr2 >> 5) & 7) + 1) / 8.0
    env = np.ones(n)
    ataque = min(n, 40)
    env[:ataque] = np.linspace(0, 1, ataque)
    dec = min(n, 600)
    env[:dec] *= np.linspace(1, max(sl, 0.35), dec) if adsr2 != 0xF0 else 1
    rel = min(n, 300)
    env[-rel:] *= np.linspace(1, 0, rel)
    return env

def render(nome, segundos):
    song = next(s for s in dados['songs'] if s['name'] == nome)
    total = int(segundos * RATE)
    mix = np.zeros(total)
    for trilha in song['tracks']:
        pos, i, inst, vol = 0, 0, 0, 0x40
        bytes_ = trilha
        while pos < total:
            b = bytes_[i]; i += 1
            if b == 0xF0: inst = bytes_[i]; i += 1; continue
            if b == 0xF1: vol = bytes_[i]; i += 1; continue
            if b == 0xFE: i = 0; continue
            if b == 0xFF: break
            dur = bytes_[i]; i += 1
            n = int(dur / 60.0 * RATE)
            if b:
                f = 440 * 2 ** ((b + 35 - 69) / 12)
                smp, _, adsr2 = dados['inst'][inst]
                fase = (np.arange(n) * f * 32 / RATE)
                t = (fase % 32) / 32.0
                if smp == 0: w = np.where(t < 0.5, 0.8, -0.8)
                elif smp == 2: w = np.where(t < 0.25, 0.8, -0.8)
                else: w = 1.6 * (np.abs(((t + 0.25) % 1.0) - 0.5) * 2 - 0.5)
                w = w * envelope(adsr2, n) * (vol / 127.0)
                fim = min(total, pos + n)
                mix[pos:fim] += w[:fim - pos]
            pos += n
    # eco curto, como no jogo
    atraso = int(0.048 * RATE)
    eco = np.zeros_like(mix); eco[atraso:] = mix[:-atraso] * 0.3
    mix = mix + eco
    mix = mix / (np.max(np.abs(mix)) + 1e-9) * 0.85
    return mix

def salva(nome_arq, sinal):
    pcm = (sinal * 32767).astype(np.int16)
    with wave.open(nome_arq, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(pcm.tobytes())

if __name__ == '__main__':
    out = os.path.join(ROOT, 'trailer', 'audio'); os.makedirs(out, exist_ok=True)
    for nome, seg in [('titulo', 40), ('dia', 40), ('dia3', 40), ('vitoria', 6)]:
        salva(os.path.join(out, nome + '.wav'), render(nome, seg))
        print('musica', nome)
