-- Pruebas de «¿Qué se esconde?»: lune run pruebas/escondido.luau
local E = require("../src/shared/Logica/Escondido")

math.randomseed(21)
local azar = math.random

local function iguales(a, b)
	for f = 1, E.ALTO do
		for c = 1, E.ANCHO do
			if a[f][c] ~= b[f][c] then
				return false
			end
		end
	end
	return true
end

local function bloquesDistintos(a, b)
	local n = 0
	for k = 1, E.BLOQUES do
		if not E.igualEnBloque(a, b, k) then
			n += 1
		end
	end
	return n
end

for nivel = 1, E.NIVELES do
	for _, dos in { false, true } do
		for _ = 1, 500 do
			local e = E.generar(nivel, azar, dos)
			local n = if dos then 2 else 3
			assert(#e.opciones == n, "cantidad de opciones")
			assert(e.correcta >= 1 and e.correcta <= n)
			local buena = e.opciones[e.correcta]
			-- Opciones todas distintas, y cada equivocada difiere de la buena en un solo bloque.
			for i = 1, n do
				for j = i + 1, n do
					assert(not iguales(e.opciones[i], e.opciones[j]), "opciones repetidas")
				end
				if i ~= e.correcta then
					assert(bloquesDistintos(e.opciones[i], buena) == 1, "una equivocada difiere en más de un bloque")
					-- Lo que la distingue está tapado al empezar: si no, no habría nada que pensar.
					assert(E.coincide(e, i), "nivel " .. nivel .. ": una opción ya se descarta sin destapar")
				end
			end
			-- Tapados: nivel 1 = 4 (3 con ayuda); nivel 2 = todos.
			local tapados = 0
			for k = 1, E.BLOQUES do
				if e.tapado[k] then
					tapados += 1
				end
			end
			if nivel == 1 then
				assert(tapados == n + 1, "nivel 1 con " .. tapados .. " tapados")
			else
				assert(tapados == E.BLOQUES)
			end
			assert(e.minimo == n - 1, "mínimo esperado " .. (n - 1) .. ", da " .. e.minimo)

			-- Jugando perfecto (destapando solo lo que ayuda) se llega a una sola opción con el mínimo y 3 estrellas.
			local copia = E.generar(nivel, function()
				return 1
			end, dos)
			local k = E.bloqueQueAyuda(copia)
			while k do
				assert(E.destapar(copia, k))
				k = E.bloqueQueAyuda(copia)
			end
			local quedan = 0
			for j = 1, #copia.opciones do
				if E.coincide(copia, j) then
					quedan += 1
				end
			end
			assert(quedan == 1, "después de destapar lo que ayuda queda más de una opción")
			assert(copia.destapados == copia.minimo)
			assert(E.adivinar(copia, copia.correcta) and copia.resuelto)
			assert(E.estrellas(copia) == 3)
			assert(not E.destapar(copia, 1), "no se destapa después de resolver")

			-- Adivinar mal: descarta, cuenta como destapado y destapa un bloque que ayuda.
			local equivocada = if e.correcta == 1 then 2 else 1
			local antes = e.destapados
			local ok, ayuda = E.adivinar(e, equivocada)
			assert(not ok and e.descartada[equivocada] and e.errores == 1)
			assert(e.destapados == antes + 1, "el error cuenta como un bloque destapado")
			assert(ayuda == nil or not e.tapado[ayuda])
			assert(not (E.adivinar(e, equivocada)), "una descartada no se puede volver a elegir")
			assert(e.errores == 1)
			assert(E.adivinar(e, e.correcta))
			assert(E.estrellas(e) >= 1 and E.estrellas(e) <= 2, "con un error no hay 3 estrellas")
			assert(not E.buenaHipotesis(e))
			assert(E.buenaHipotesis(copia))
		end
	end
end

-- Destapar un bloque ya destapado no cuenta dos veces.
local e = E.generar(2, azar)
assert(E.destapar(e, 5) and not E.destapar(e, 5) and e.destapados == 1)

-- Estrellas: se pasan del mínimo → bajan.
e.minimo = 2
e.destapados = 2
assert(E.estrellas(e) == 3)
e.destapados = 4
assert(E.estrellas(e) == 2)
e.destapados = 9
assert(E.estrellas(e) == 1)

print("ok: escondido")
