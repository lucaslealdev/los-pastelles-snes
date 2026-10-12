BOTCFG = "botcfg_ui.lua"
local dir = "C:/Users/ramon/Desktop/Jogo Snes/teste/"
dofile(dir .. "bot.lua")
local L = {}
for line in io.lines("C:/Users/ramon/Desktop/Jogo Snes/gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n, i) return emu.read(0x7E0000 + L[n] + (i or 0), emu.memType.snesMemory) end
local last, c = -1, 0
emu.addEventCallback(function()
  if r8("state") ~= 6 then last = -1 return end
  local sel = r8("menu_sel")
  if sel ~= last then last = sel; c = 0 end
  c = c + 1
  if c == 105 then
    local fh = io.open(dir .. "ui/quieto_" .. string.format("%02d", sel) .. ".png", "wb"); fh:write(emu.takeScreenshot()); fh:close()
  end
end, emu.eventType.endFrame)
