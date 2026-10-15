-- fim do dia com todas as linhas preenchidas (ver resultado.lua)
CHEIO = true
local dir = (debug and debug.getinfo and (debug.getinfo(1, "S").source or ""):match("^@(.*[/\\])")) or "teste/"
dofile(dir .. "resultado.lua")
