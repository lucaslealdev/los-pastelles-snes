-- password (melhoria 12), cartucho com SRAM: o robo joga ate a loja; o teste poe
-- valores variados no save (alguns acima do teto), abre VER PASSWORD e anota os
-- 32 simbolos; volta ao titulo, zera o save na RAM, entra em PASSWORD e digita
-- pelo teclado da tela: primeiro com um caractere errado (tem que recusar),
-- depois o certo. Escolhe o espaco 1 para salvar e confere o save na RAM (com os
-- tetos aplicados) e na SRAM. Fotos em teste/foto_senha_*.png. Sai com 0 se passou.
local dir = (debug and debug.getinfo and (debug.getinfo(1, "S").source or ""):match("^@(.*[/\\])")) or "teste/"
dofile(dir .. "bot.lua")
ENDF = 1e9                      -- quem encerra e este script
local L = {}
for line in io.lines(dir .. "../gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local M = emu.memType.snesMemory
local function r8(n, i) return emu.read(0x7E0000 + L[n] + (i or 0), M) end
local function r16(n) return r8(n) + 256 * r8(n, 1) end
local function r32(n) return r16(n) + 65536 * (r8(n, 2) + 256 * r8(n, 3)) end
local function w(n, v, tam)
  for i = 0, (tam or 1) - 1 do emu.write(0x7E0000 + L[n] + i, (v >> (8 * i)) & 0xFF, M) end
end
local function foto(nome)
  local fh = io.open(dir .. "foto_senha_" .. nome .. ".png", "wb"); fh:write(emu.takeScreenshot()); fh:close()
end
local ok = true
local function erro(s) ok = false; print("ERRO: " .. s) end

-- [variavel, bytes, valor posto, valor esperado depois do password]
local CASOS = {
  {"s_day", 2, 37, 37}, {"s_money", 4, 123456, 123456}, {"s_stock", 2, 88, 88},
  {"s_level", 1, 12, 12}, {"s_xp", 2, 300, 300}, {"s_rep", 1, 77, 77},
  {"s_fryer", 1, 3, 3}, {"s_counter", 1, 2, 2}, {"s_attend", 1, 1, 1}, {"s_ads", 1, 0, 0},
  {"s_stores", 1, 2, 2}, {"s_fran", 1, 1, 1}, {"s_boss", 1, 2, 2}, {"s_mission", 1, 9, 9},
  {"s_promo", 1, 1, 1}, {"s_upgrades", 1, 3, 1}, {"s_ending", 1, 0, 0}, {"s_chapter", 1, 2, 2},
  {"s_tot_fried", 2, 900, 7}, {"s_tot_sales", 4, 5000, 127}, {"s_tot_happy", 2, 600, 511},
  {"s_tot_perf", 2, 42, 42}, {"s_price", 1, 2, 2}, {"s_duels", 1, 9, 7}, {"s_tflags", 1, 9, 9},
  {"s_tot_dlv", 2, 55, 55}, {"s_pc", 1, 1, 1}, {"s_moto", 1, 0, 0}, {"s_freezer", 1, 1, 1},
  {"s_ar", 1, 0, 0}, {"s_musica", 1, 1, 1}, {"s_unif", 1, 0, 0}, {"s_reforma", 1, 1, 1},
}
local function le(n, tam) if tam == 1 then return r8(n) elseif tam == 2 then return r16(n) else return r32(n) end end

-- entrada: uma corrotina devolve os botoes de cada leitura do controle
local function idle(n) for _ = 1, n do coroutine.yield({}) end end
local function press(b) for _ = 1, 4 do coroutine.yield({ [b] = true }) end idle(4) end
local function espera(st, max)
  local t = 0
  while r8("state") ~= st do idle(1); t = t + 1; if t > (max or 3000) then erro("estado " .. st .. " nao chegou"); return false end end
  return true
end
local function digita(s)
  for t = 1, 300 do
    local k = r8("pw_tecla")
    if k == s then break end
    if k % 8 ~= s % 8 then press("right") else press("down") end
  end
  press("a")
end

local function roteiro()
  if not espera(6, 20000) then return end
  idle(60)
  for _, c in ipairs(CASOS) do w(c[1], c[3], c[2]) end
  w("s_trof", 0x00A5, 2)
  -- mostrar o password (como VER PASSWORD na loja)
  w("senha_modo", 1); w("next_state", 14)
  if not espera(14) then return end
  idle(60); foto("mostrar")
  local sym = {}
  for i = 0, 31 do sym[i] = r8("pw_sym", i) end
  press("a")
  if not espera(6) then return end
  -- titulo, com o save da RAM zerado
  w("next_state", 0)
  if not espera(0) then return end
  idle(120)
  for _, c in ipairs(CASOS) do w(c[1], 0, c[2]) end
  w("s_trof", 0, 2)
  for _ = 1, 6 do if r8("menu_sel") == 2 then break end press("down") end
  idle(10); foto("titulo")
  press("a")
  if not espera(14) then return end
  idle(30)
  -- com o ultimo caractere errado
  for i = 0, 30 do digita(sym[i]) end
  digita((sym[31] + 1) % 32)
  press("start"); idle(20)
  if r8("pw_msg") ~= 1 or r8("state") ~= 14 then erro("password errado foi aceito") end
  foto("invalido")
  press("b")
  digita(sym[31])
  idle(20); foto("digitado")
  press("start")
  if not espera(10) then return end
  if r8("sl_mode") ~= 3 then erro("slots sem o modo do password") end
  idle(30); foto("slots")
  press("a"); idle(10)
  if r8("sl_conf") == 1 then idle(20); foto("slots_conf"); press("a") end
  for _ = 1, 200 do if r8("state") ~= 10 then break end idle(1) end
  local st = r8("state")                     -- dia, carta ou escolha da loja do dia
  if st ~= 2 and st ~= 3 and st ~= 4 and st ~= 9 then erro("nao foi para o dia (estado " .. r8("state") .. ")") end
  for _, c in ipairs(CASOS) do
    local v = le(c[1], c[2])
    if v ~= c[4] then erro(string.format("%s = %d (esperado %d)", c[1], v, c[4])) end
  end
  local trof = r16("s_trof")
  -- bits 5 e 7 vem do password; o 6 (R$ 5.000) o TrophyCheck refaz com o dinheiro atual
  if trof & 0xE0 ~= 0xE0 then erro(string.format("s_trof bits 5..7: %04X", trof)) end
  if trof & 0x05 ~= 0x05 then erro(string.format("s_trof nao refez os trofeus de satisfeitos: %04X", trof)) end
  -- SRAM, espaco escolhido: 'LPST' e o dia
  local base = ({ [0] = 0, 0x80, 0x100 })[r8("save_slot")]
  local S = emu.memType.snesSaveRam
  local magic = string.char(emu.read(base, S), emu.read(base + 1, S), emu.read(base + 2, S), emu.read(base + 3, S))
  local dia = emu.read(base + 4, S) + 256 * emu.read(base + 5, S)
  if magic ~= "LPST" or dia ~= 37 then erro("SRAM sem o jogo do password (" .. magic .. ", dia " .. dia .. ")") end
end

local co, fim = nil, false
emu.addEventCallback(function()
  if fim then return end
  if not co and r8("state") == 6 then
    BOT_DESLIGADO = true                      -- daqui em diante o teste controla
    co = coroutine.create(roteiro)
  end
  if co then
    local vivo, inp = coroutine.resume(co)
    if coroutine.status(co) == "dead" then
      if not vivo then erro(tostring(inp)) end
      print(ok and "PASSOU" or "FALHOU")
      fim = true
      emu.stop(ok and 0 or 1)
      return
    end
    emu.setInput(inp or {}, 0)
  end
end, emu.eventType.inputPolled)
local q = 0
emu.addEventCallback(function() q = q + 1; if q > 60000 then print("ERRO: tempo esgotado"); emu.stop(1) end end, emu.eventType.endFrame)
