// Exporta personagens e cenarios do jogo como PNG com transparencia (para a capa/etiqueta)
'use strict';
const fs = require('fs'), path = require('path'), zlib = require('zlib');
const A = require('./arte');
const { hex } = require('./gfx');

const out = path.join(__dirname, '..', 'cartucho', 'arte'); fs.mkdirSync(out, { recursive: true });

const crcT = (() => { const t = []; for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
const crc32 = (b) => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const chunk = (t, d) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(td)); return Buffer.concat([l, td, c]); };
// img: {w,h,get(x,y)} ; pal: array de cores; indice 0 = transparente
function pngRGBA(w, h, getRGBA) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) { raw[y * (w * 4 + 1)] = 0; for (let x = 0; x < w; x++) { const [r, g, b, a] = getRGBA(x, y); const o = y * (w * 4 + 1) + 1 + x * 4; raw[o] = r; raw[o + 1] = g; raw[o + 2] = b; raw[o + 3] = a; } }
  const ih = Buffer.alloc(13); ih.writeUInt32BE(w, 0); ih.writeUInt32BE(h, 4); ih[8] = 8; ih[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ih), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
function salva(nome, img, pal) {
  fs.writeFileSync(path.join(out, nome + '.png'), pngRGBA(img.w, img.h, (x, y) => {
    const c = img.get(x, y); if (!c) return [0, 0, 0, 0]; const [r, g, b] = hex(pal[c]); return [r, g, b, 255];
  }));
}

const S = A.buildSprites();
const sheet = S.sheet;
// recorta da folha de sprites (cada pixel guarda (paleta<<4)|cor) usando a paleta indicada
function recorte(tile, tam, pal) {
  const tx = (tile % 16) * 8, ty = Math.floor(tile / 16) * 8;
  return { w: tam, h: tam, get: (x, y) => sheet.get(tx + x, ty + y) & 15, pal };
}
const ID = S.ids;
const portPal = S.portPals;
const custPal = (v) => S.pals[3 + v];
['fundador', 'mestre', 'gerente', 'concorrente'].forEach((nome, i) => salva(nome, { w: 32, h: 32, get: (x, y) => S.portImg.get(i * 32 + x, y) }, portPal[i]));
const exp = [
  ['misterioso', ID.CUST_4_1, 32, custPal(4)],
  ['cliente0', ID.CUST_0_1, 32, custPal(0)],
  ['cliente1', ID.CUST_1_1, 32, custPal(1)],
  ['cliente2', ID.CUST_2_1, 32, custPal(2)],
  ['cliente3', ID.CUST_3_1, 32, custPal(3)],
  ['mascote', ID.MASCOTE_1, 32, S.pals[1]],
  ['pastel', ID.PASTEL_1, 16, S.pals[1]],
  ['moeda', ID.MOEDA, 16, S.pals[0]],
  ['coracao', ID.CORACAO, 16, S.pals[0]],
  ['estrela', ID.ESTRELA, 16, S.pals[0]],
  ['refri', ID.REFRI, 16, S.pals[0]],
];
for (const [nome, tile, tam, pal] of exp) { const r = recorte(tile, tam, pal); salva(nome, r, pal); }
// cenarios
const tit = A.titleScene();
const palT = A.PAL_TITLE.slice(); palT[14] = '#FDF1E0'; palT[15] = '#FAA61E';
salva('fachada_noite', { w: tit.w, h: tit.h, get: (x, y) => tit.get(x, y) || 1 }, palT);
const loja = A.shopScene(0);
salva('loja', { w: loja.w, h: loja.h, get: (x, y) => loja.get(x, y) || 1 }, A.shopPal(0));
console.log('arte exportada em', out);
