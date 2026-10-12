// Tabelas HDMA da interface:
//  - degrade do painel (subtracao de cor por linha, so dentro da janela do painel)
//  - brilho "de vidro" nas faixas do HUD do expediente (soma de cor)
//  - faixa de selecao pulsante com chanfro 3D (16 niveis de pulso, 8 e 16 linhas)
//  - abertura elastica da caixa (rolagem vertical por linha esticando a tela)
'use strict';

// tabela HDMA modo 2 (2 bytes por linha, 224 linhas): $F0 + 112 linhas, $F0 + 112 linhas, $00
function hdma2(linhas) {
  const out = [];
  for (let b = 0; b < 2; b++) {
    out.push(0x80 | 112);
    for (let s = b * 112; s < b * 112 + 112; s++) out.push(...linhas[s]);
  }
  out.push(0);
  return Buffer.from(out);
}
const clamp = (v) => Math.max(0, Math.min(31, Math.round(v)));
const G = (v) => 0x40 | clamp(v), B = (v) => 0x80 | clamp(v);
const R = (v) => 0x20 | clamp(v), GB = (v) => 0xC0 | clamp(v);

function panelGrad() {
  const l = [];
  for (let s = 0; s < 224; s++) {
    const t = Math.max(0, Math.min(1, (s - 13) / 192));
    l.push([G(t * 1.5), B(t * 4)]);
  }
  return hdma2(l);
}

function hudGloss() {
  const l = [];
  for (let s = 0; s < 224; s++) {
    let v = 0;
    if (s <= 25) v = s < 2 ? 12 : s < 14 ? 9 - (s - 2) * 0.7 : (s >= 23 ? 4 : 0);
    else if (s >= 200) { const k = s - 200; v = k < 2 ? 11 : k < 12 ? 8 - (k - 2) * 0.75 : 0; }
    l.push([R(v), GB(v * 0.75)]);
  }
  return hdma2(l);
}

// faixa: [pulso 0..15][linha 0..h-1][G, B] - mais clara em cima, borda escura embaixo
function band(h) {
  const out = [];
  for (let p = 0; p < 16; p++) {
    const I = 8 + p * 0.65;
    for (let j = 0; j < h; j++) {
      const t = j / (h - 1);
      let g, b;
      if (j === 0) { g = 0; b = I * 0.35; }
      else if (j === h - 1) { g = I * 0.75 + 5; b = I + 9; }
      else if (j === h - 2) { g = I * 0.55 + 2; b = I + 4; }
      else { g = I * (0.25 + 0.25 * t); b = I * (0.65 + 0.35 * t); }
      out.push(G(g), B(b));
    }
  }
  return Buffer.from(out);
}

// abertura: escala vertical elastica em torno do centro da tela
const ESCALAS = [0.06, 0.16, 0.32, 0.52, 0.74, 0.94, 1.08, 1.13, 1.09, 1.02, 0.97, 0.96, 0.99, 1.01, 1.0];
function openTabs() {
  const tabs = [];
  for (const k of ESCALAS) {
    const l = [];
    for (let s = 0; s < 224; s++) {
      const d = (s - 112) / k;
      const f = Math.abs(d) > 112 ? 2 : Math.round(112 + d);
      const v = (0x3FF + f - s) & 0x3FF;
      l.push([v & 255, v >> 8]);
    }
    tabs.push(hdma2(l));
  }
  return Buffer.concat(tabs);
}

// seno para o pulso (32 passos, 0..15)
const PULSO = Array.from({ length: 32 }, (_, i) => Math.round(7.5 + 7.5 * Math.sin(i / 32 * 2 * Math.PI)));
// balanco do icone escolhido (32 passos, -2..+1 px)
const BALANCO = Array.from({ length: 32 }, (_, i) => Math.round(-1.5 * Math.abs(Math.sin(i / 32 * 2 * Math.PI)) * 1.4));

module.exports = { panelGrad, hudGloss, band, openTabs, N_OPEN: ESCALAS.length, PULSO, BALANCO, TAB_LEN: 451 };
