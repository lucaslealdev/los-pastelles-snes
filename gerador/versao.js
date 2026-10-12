// Versao do jogo (semantic versioning: MAIOR.MENOR.CORRECAO).
//  - VERSION: versao minima da proxima versao lancada (mude para subir MAIOR/MENOR)
//  - tags vX.Y.Z: versoes ja lancadas (o CI cria uma a cada mudanca na main)
// Uso: node gerador/versao.js            -> versao desta compilacao
//      node gerador/versao.js --proxima  -> proxima versao a lancar (usado pelo CI)
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const SEMVER = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/;
const parte = (v) => { const m = SEMVER.exec(v); return m ? [+m[1], +m[2], +m[3]] : null; };
const cmp = (a, b) => a[0] - b[0] || a[1] - b[1] || a[2] - b[2];

function git(args) {
  try { return execFileSync('git', args, { cwd: ROOT, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(); } catch (e) { return null; }
}

function base() {
  const v = fs.readFileSync(path.join(ROOT, 'VERSION'), 'utf8').trim();
  if (!/^\d+\.\d+\.\d+$/.test(v) || !parte(v)) throw new Error('VERSION invalido (use MAIOR.MENOR.CORRECAO): "' + v + '"');
  return parte(v);
}

// maior tag vX.Y.Z (so versoes finais; ignora outras tags)
function ultimaLancada() {
  const out = git(['tag', '--list', 'v*']);
  const vs = (out ? out.split('\n') : []).filter((t) => /^v\d+\.\d+\.\d+$/.test(t)).map((t) => parte(t.slice(1))).filter(Boolean);
  return vs.sort(cmp).pop() || null;
}

// proxima versao: a do VERSION, se for maior que a ultima lancada; senao, CORRECAO + 1
function proxima() {
  const b = base(), u = ultimaLancada();
  return (!u || cmp(b, u) > 0 ? b : [u[0], u[1], u[2] + 1]).join('.');
}

// versao desta compilacao: GAME_VERSION (o CI define) ou, localmente, a ultima tag
// mais os commits desde ela (git describe); sem git, a do VERSION com "-dev"
function versaoDoJogo() {
  const env = (process.env.GAME_VERSION || '').trim();
  if (env) {
    if (!SEMVER.test(env)) throw new Error('GAME_VERSION nao e semver: "' + env + '"');
    return env;
  }
  const d = git(['describe', '--tags', '--match', 'v[0-9]*', '--abbrev=7']);
  const m = d && /^v(\d+\.\d+\.\d+)(?:-(\d+)-g([0-9a-f]+))?$/.exec(d);
  if (m) return m[2] ? `${m[1]}-dev.${m[2]}+${m[3]}` : m[1];
  return base().join('.') + '-dev';
}

// texto para a tela de creditos: so caracteres com glifo na fonte e no maximo 19
// (cabe na caixa depois de "VERSAO "); se faltar espaco, sai o "+metadados"
const MAX_TELA = 19;
function versaoNaTela(v) {
  let s = String(v).toUpperCase().replace(/[^0-9A-Z.+-]/g, '');
  if (s.length > MAX_TELA) s = s.replace(/\+.*$/, '');
  if (s.length > MAX_TELA) s = s.slice(0, MAX_TELA);
  return s || '?';
}

module.exports = { versaoDoJogo, proxima, versaoNaTela, SEMVER };

if (require.main === module) console.log(process.argv[2] === '--proxima' ? proxima() : versaoDoJogo());
