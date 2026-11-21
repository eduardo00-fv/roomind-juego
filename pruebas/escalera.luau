-- Pruebas de la escalera de dificultad: lune run pruebas/escalera.luau
local Escalera = require("../src/shared/Logica/Escalera")

local e = Escalera.nueva(3)
assert(Escalera.registrar(e, true) == "nada")
assert(Escalera.registrar(e, true) == "sube" and e.nivel == 2)
assert(Escalera.registrar(e, false) == "nada")
assert(Escalera.registrar(e, false) == "ayuda" and e.nivel == 2)
assert(Escalera.registrar(e, false) == "baja" and e.nivel == 1)
assert(Escalera.registrar(e, false) == "nada")
assert(Escalera.registrar(e, false) == "ayuda")
assert(Escalera.registrar(e, false) == "ayuda" and e.nivel == 1, "no baja del 1")
-- un acierto corta la racha de fallos
assert(Escalera.registrar(e, true) == "nada" and e.fallosSeguidos == 0)
-- no pasa del máximo
local m = Escalera.nueva(2, 2)
Escalera.registrar(m, true)
assert(Escalera.registrar(m, true) == "nada" and m.nivel == 2)
print("ok: escalera")
