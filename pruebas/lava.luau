-- Pruebas de la lógica de la lava: lune run pruebas/lava.luau
local Lava = require("../src/shared/Logica/Lava")

local function piso(lava, conNumeros)
	return { n = #lava, lava = lava, conNumeros = conNumeros or false }
end

-- Una lava por fila y por columna, siempre con camino, en todos los tamaños.
math.randomseed(7)
for _, nivel in Lava.NIVELES do
	for _ = 1, 300 do
		local p = Lava.generar(nivel.n, nivel.conNumeros, math.random)
		local cols = {}
		for f = 1, p.n do
			assert(p.lava[f] >= 1 and p.lava[f] <= p.n)
			assert(not cols[p.lava[f]], "columna repetida")
			cols[p.lava[f]] = true
		end
		assert(Lava.tieneCamino(p))
	end
end

-- Las dos diagonales del 3×3 tapan el paso (por eso se filtran); {2,3,1} sí tiene camino.
assert(not Lava.tieneCamino(piso({ 3, 2, 1 })))
assert(not Lava.tieneCamino(piso({ 1, 2, 3 })))
assert(Lava.tieneCamino(piso({ 2, 3, 1 })))

-- Tantear cuesta una vez; repetir no cuesta.
local e = Lava.nuevo(piso({ 2, 3, 1 }))
assert(Lava.tantear(e, 1, 2) == "lava")
assert(Lava.tantear(e, 1, 2) == "repetida")
assert(Lava.tantear(e, 1, 1) == "piso")
assert(e.tanteos == 2)

-- La lava de (1,2) vuelve seguras su fila y su columna.
local seguras, lavas = Lava.deducir(e)
assert(seguras[Lava.indice(3, 1, 3)] and seguras[Lava.indice(3, 3, 2)] and seguras[Lava.indice(3, 2, 2)])
assert(lavas[Lava.indice(3, 1, 2)])
assert(Lava.razon(e, 2, 2) == "columna" and Lava.razon(e, 1, 3) == "fila" and Lava.razon(e, 2, 1) == "adivino")
assert(Lava.razonCorrecta(e, 2, 2, "columna") and not Lava.razonCorrecta(e, 2, 2, "fila"))
assert(Lava.razonCorrecta(e, 2, 1, "adivino") and not Lava.razonCorrecta(e, 1, 3, "adivino"))

-- Deducción encadenada: con la lava de la fila 1 en col 2, en la fila 2 quedan cols 1 y 3;
-- si además (2,1) es piso, la lava de la fila 2 tiene que estar en (2,3).
Lava.tantear(e, 2, 1)
local _, lavas2 = Lava.deducir(e)
assert(lavas2[Lava.indice(3, 2, 3)], "debió deducir la lava de la fila 2")
assert(lavas2[Lava.indice(3, 3, 1)], "y con eso la de la fila 3")

-- Pisar: lava conocida avisa sin quemar; lava nueva quema, borra el camino y marca.
assert(Lava.pisar(e, 1, 1) == "piso")
assert(Lava.pisar(e, 1, 1) == "igual")
assert(Lava.pisar(e, 1, 2) == "lavaConocida" and e.quemadas == 0 and e.erroresMemoria == 1)
assert(Lava.pisar(e, 2, 1) == "piso" and #e.camino == 2)
assert(Lava.pisar(e, 3, 1) == "quemada")
assert(e.quemadas == 1 and #e.camino == 0 and e.posicion == nil and e.lavasConocidas[Lava.indice(3, 3, 1)])
assert(not e.ayudaChecks)
assert(Lava.pisar(e, 2, 3) == "quemada" and e.ayudaChecks, "2 quemadas activan los ✓")
assert(Lava.pisar(e, 1, 3) == "piso")
assert(Lava.pisar(e, 2, 2) == "piso")
assert(Lava.pisar(e, 3, 2) == "meta" and e.ganado)

-- Estrellas: quemada = 2 tanteos.
local s = Lava.nuevo(piso({ 1, 2, 3 }))
assert(Lava.estrellas(s) == 3)
s.tanteos = 1
assert(Lava.estrellas(s) == 3)
s.tanteos = 3
assert(Lava.estrellas(s) == 2)
s.quemadas = 1
assert(Lava.estrellas(s) == 1)

-- Números: lavas al lado (sin diagonales).
local p5 = piso({ 1, 3, 5, 2, 4 }, true)
assert(Lava.lavasAlLado(p5, 1, 2) == 1) -- (1,1)
assert(Lava.lavasAlLado(p5, 2, 2) == 1) -- (2,3)
assert(Lava.lavasAlLado(p5, 1, 3) == 1) -- (2,3)
assert(Lava.lavasAlLado(p5, 4, 3) == 1) -- (4,2)
assert(Lava.lavasAlLado(piso({ 1, 2, 3 }), 1, 2) == 2) -- (1,1) y (2,2)

-- Más de 3 quemadas: piso nuevo con la lava de la fila 1 regalada.
local q = Lava.nuevo(piso({ 1, 2, 3 }))
for _ = 1, 4 do
	q.quemadas += 1
end
assert(Lava.hayQueCambiar(q))
local r, i = Lava.pisoDeRegalo(q, math.random)
local f, c = Lava.celda(3, i)
assert(f == 1 and r.piso.lava[1] == c and r.lavasConocidas[i] and r.tanteos == 0)

print("ok: lava")
