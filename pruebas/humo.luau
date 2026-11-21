-- Prueba de humo: Lune puede cargar los módulos compartidos del juego.
local Modulos = require("../src/shared/Modulos")
local n = 0
for _ in Modulos do
	n += 1
end
assert(n == 6, "se esperaban 6 módulos, hay " .. n)
assert(Modulos.lava.habilidades[1] == "deductivo")
print("ok: " .. n .. " módulos")
