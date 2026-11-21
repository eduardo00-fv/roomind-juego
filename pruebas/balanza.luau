-- Pruebas de la lógica de la balanza: lune run pruebas/balanza.luau
local B = require("../src/shared/Logica/Balanza")

math.randomseed(11)
local azar = math.random

local function contiene(t, x)
	for _, v in t do
		if v == x then
			return true
		end
	end
	return false
end

for nivel = 1, B.NIVELES do
	for _ = 1, 400 do
		local r = B.generar(nivel, azar)
		assert(r.nivel == nivel)
		if r.tipo == "caja" then
			assert(r.pesoCaja and r.pesoCaja > 0)
			assert(not B.parejas(r), "una caja arranca desemparejada")
			assert(B.tieneSolucion(r), "nivel " .. nivel .. " sin solución")
			local ops = B.opcionesPeso(r, azar)
			assert(#ops == 3 and contiene(ops, r.pesoCaja))
			-- Siguiendo la ayuda siempre se llega a parejas.
			local pasos = 0
			while not B.parejas(r) do
				local id, lado = B.ayuda(r)
				assert(id and lado, "la ayuda no encontró bloque")
				assert(B.mover(r, id, lado))
				pasos += 1
				assert(pasos < 30, "la ayuda da vueltas")
			end
			-- Con la balanza pareja, el peso de la caja sale de restar.
			local cajas, sueltosIzq = 0, 0
			for _, b in r.bloques do
				if b.misterio then
					cajas += 1
				elseif b.lado == "izq" then
					sueltosIzq += b.peso
				end
			end
			assert((B.total(r, "der") - sueltosIzq) / cajas == r.pesoCaja)
		elseif r.tipo == "pasar" then
			local k = B.pasarNecesarios(r)
			assert(k >= 1 and k <= 3)
			local ops = B.opcionesPasar(r, azar)
			assert(#ops == 3 and contiene(ops, k))
			for _ = 1, k do
				local id, lado = B.ayuda(r)
				assert(B.mover(r, id, lado))
			end
			assert(B.parejas(r), "pasando la mitad de la diferencia quedan parejas")
		else
			assert(B.opcionInclina(r) >= 1 and B.opcionInclina(r) <= 3)
		end
	end
end

-- Las cajas y los bloques puestos de entrada no se mueven en «caja».
local r = B.generar(3, azar)
for _, b in r.bloques do
	if b.lado ~= "bandeja" then
		assert(not B.mover(r, b.id, "der") and not B.mover(r, b.id, "bandeja"))
	end
end
-- En «predecir» no se mueve nada.
local p = B.generar(1, azar)
assert(not B.mover(p, 1, "der"))
-- Ejemplo concreto: caja de 5 + 2 a la izquierda, 3 a la derecha → faltan 4 a la derecha.
local c = { nivel = 3, tipo = "caja", bloques = {}, pesoCaja = 5, movidas = 0 }
table.insert(c.bloques, { id = 1, peso = 5, misterio = true, lado = "izq", fijo = true })
table.insert(c.bloques, { id = 2, peso = 2, misterio = false, lado = "izq", fijo = true })
table.insert(c.bloques, { id = 3, peso = 3, misterio = false, lado = "der", fijo = true })
table.insert(c.bloques, { id = 4, peso = 2, misterio = false, lado = "bandeja", fijo = false })
table.insert(c.bloques, { id = 5, peso = 2, misterio = false, lado = "bandeja", fijo = false })
assert(B.inclinacion(c) == 1 and B.diferencia(c) == 4)
local id = B.ayuda(c)
assert(id == 4, "la ayuda da el bloque de 2")
B.mover(c, 4, "der")
B.mover(c, 5, "der")
assert(B.parejas(c) and c.movidas == 2)
local ops = B.opcionesPeso(c, function(a)
	return a
end)
assert(contiene(ops, 5) and contiene(ops, 7), "el total de la derecha (7) es un distractor")
print("ok: balanza")
