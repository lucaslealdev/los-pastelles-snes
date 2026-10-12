dofile("C:/Users/ramon/Desktop/Jogo Snes/teste/botcfg.lua")
ENDF = 7900
GRAVA_NOME = "b"
function GRAVA_QUANDO(st, ef, t) return st == 9 or (st == 4 and t < 3200) or st == 5 or st == 6 or st == 7 or st == 12 end
