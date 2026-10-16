// Password (salvar sem SRAM): formato, alfabeto e tabela de campos
//
// 160 bits = 32 simbolos de 5 bits (8 blocos de 4 para anotar):
//   bits 0..2     versao do formato (VERSAO)
//   bits 3..148   campos do save, cada um so com os bits do seu intervalo real
//   bits 149..159 verificacao (CRC-16 CCITT dos 20 bytes com estes bits zerados,
//                 11 bits de baixo) XOR CHAVE_VER
// Os bits 0..148 sao embaralhados com um LFSR semeado pela verificacao, entao
// dois saves quase iguais dao passwords totalmente diferentes, e um caractere
// trocado quase nunca passa (verificacao + faixas validas de cada campo).
//
// Ficam de fora (so na SRAM): opcoes do jogo, historico de lucro (zera) e os
// trofeus que o jogo recalcula sozinho (TrophyCheck): so entram os 3 que nao
// da para refazer (bits 5..7 de s_trof: dia sem perder cliente, R$ 5.000, R$ 20.000).
// Contadores so precisam chegar ao maior limite que o jogo confere (missoes,
// trofeus), entao sao guardados com teto.
'use strict';

// sem O/0 e I/1 (parecidos demais para anotar)
const ALFABETO = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const VERSAO = 1, BITS_VERSAO = 3, BITS_VER = 11, TOTAL = 160;
const CHAVE_VER = 0x5A3, CHAVE_LFSR = 0x9E37;

// [variavel, bytes, minimo, maximo]  (pw_trof e pw_tflags sao montados pelo codigo)
const CAMPOS = [
  ['s_day', 2, 1, 1024],
  ['s_money', 4, 0, 1048575],
  ['s_stock', 2, 0, 1023],
  ['s_level', 1, 1, 99],
  ['s_xp', 2, 0, 4095],
  ['s_rep', 1, 0, 100],
  ['s_fryer', 1, 1, 3],
  ['s_counter', 1, 1, 3],
  ['s_attend', 1, 0, 1],
  ['s_ads', 1, 0, 1],
  ['s_stores', 1, 0, 4],
  ['s_fran', 1, 0, 5],
  ['s_boss', 1, 0, 4],
  ['s_mission', 1, 0, 14],
  ['s_promo', 1, 0, 1],
  ['s_upgrades', 1, 0, 1],
  ['s_ending', 1, 0, 1],
  ['s_chapter', 1, 0, 7],
  ['s_tot_fried', 2, 0, 7],        // missao 0: 5 pasteis
  ['s_tot_sales', 4, 0, 127],      // missao 1: R$ 100
  ['s_tot_happy', 2, 0, 511],      // trofeu: 500 satisfeitos
  ['s_tot_perf', 2, 0, 511],       // trofeu: 300 perfeitos
  ['s_price', 1, 0, 3],
  ['pw_trof', 1, 0, 7],            // s_trof bits 5..7
  ['s_duels', 1, 0, 7],            // trofeu: 5 duelos
  ['pw_tflags', 1, 0, 15],         // s_tflags bits 0..3
  ['s_tot_dlv', 2, 0, 127],        // trofeu: 100 entregas
  ['s_pc', 1, 0, 1],
  ['s_moto', 1, 0, 1],
  ['s_freezer', 1, 0, 1],
  ['s_ar', 1, 0, 1],
  ['s_musica', 1, 0, 1],
  ['s_unif', 1, 0, 1],
  ['s_reforma', 1, 0, 2],
];

const bitsDe = (n) => { let b = 0; while ((1 << b) < n) b++; return b; };
const campos = CAMPOS.map(([v, tam, min, max]) => ({ v, tam, min, max, bits: bitsDe(max - min + 1) }));
const BITS_CAMPOS = campos.reduce((s, c) => s + c.bits, 0);
if (BITS_VERSAO + BITS_CAMPOS + BITS_VER !== TOTAL) {
  throw new Error(`password: ${BITS_VERSAO}+${BITS_CAMPOS}+${BITS_VER} bits, precisa dar ${TOTAL}`);
}

// gen/senha.inc: constantes, tabela de campos (lida por SenhaGera/SenhaLe no banco 28)
// e o alfabeto em codigos da fonte
function inc(CODE) {
  const L = ['; gerado por build.js (gerador/senha.js) - formato do password'];
  L.push(`SENHA_VERSAO = ${VERSAO}`, `SENHA_BITS_VERSAO = ${BITS_VERSAO}`, `SENHA_BITS_VER = ${BITS_VER}`,
    `SENHA_POS_VER = ${TOTAL - BITS_VER}`, `SENHA_CHAVE_VER = $${CHAVE_VER.toString(16)}`,
    `SENHA_CHAVE_LFSR = $${CHAVE_LFSR.toString(16)}`, `SENHA_N = ${TOTAL / 5}`, `SENHA_CAMPOS = ${campos.length}`);
  L.push('; por campo: endereco (2), bytes (1), bits (1), minimo (4), maximo (4)');
  L.push('SenhaCampos:');
  for (const c of campos) {
    L.push(`    .word ${c.v}`, `    .byte ${c.tam}, ${c.bits}`, `    .dword ${c.min}, ${c.max}`);
  }
  L.push(`SENHA_TRACO = ${CODE['-']}`, `SENHA_BLOCO = ${CODE['■']}`);
  L.push('SenhaAlfa:', '    .byte ' + [...ALFABETO].map((ch) => CODE[ch]).join(', '));
  return L.join('\n') + '\n';
}

module.exports = { ALFABETO, VERSAO, TOTAL, BITS_VER, campos, BITS_CAMPOS, inc };
