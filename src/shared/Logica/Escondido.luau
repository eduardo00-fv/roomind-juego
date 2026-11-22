--!strict
-- Lógica pura de «¿Qué se esconde?» (instrucciones.md §3), niveles 1 y 2. Sin APIs de Roblox: se prueba con Lune
-- en pruebas/escondido.luau.
--
-- Una figura de 8×6 cuadritos está tapada por 4×3 bloques (cada bloque tapa 2×2 cuadritos). Al lado hay 3 figuras
-- para elegir que se parecen mucho: cada figura equivocada difiere de la escondida en UN solo bloque. Destapar el
-- bloque justo descarta una opción, así que pensar dónde mirar (formular una hipótesis) vale más que destapar todo.
--   nivel 1: casi destapada; quedan tapados 4 bloques, entre ellos los que deciden;
--   nivel 2: el tablero de 4×3 todo tapado.
-- Adivinar mal descarta esa opción y destapa un bloque que ayuda, y eso cuenta como un bloque destapado
-- (si fuera gratis, adivinar al azar convendría más que pensar). Con ayuda (2 fallos seguidos) hay solo 2 opciones.
--
-- `azar(a, b)` devuelve un entero entre a y b (incluidos). En Roblox: Random.new():NextInteger; en las pruebas:
-- math.random.

export type Azar = (number, number) -> number
export type Figura = { { boolean } } -- figura[fila][columna]; fila 1 = la de arriba

export type Estado = {
	nivel: number,
	nombre: string, -- de qué dibujo salió (no se le dice al niño hasta el final)
	opciones: { Figura },
	correcta: number,
	tapado: { boolean }, -- por bloque (1..12): true = sigue tapado
	descartada: { boolean },
	destapados: number, -- los que destapó el niño (los que ya venían destapados no cuentan)
	errores: number,
	minimo: number, -- la menor cantidad de bloques que hay que destapar para estar seguro
	resuelto: boolean,
}

local Escondido = {}

Escondido.ANCHO = 8
Escondido.ALTO = 6
Escondido.BX = 4 -- bloques por fila
Escondido.BY = 3 -- filas de bloques
Escondido.BLOQUES = 12
Escondido.NIVELES = 2

-- Dibujos de 8×6 («#» = lleno). Contextos de acá: animales y cosas del barrio.
local DIBUJOS: { { nombre: string, filas: { string } } } = {
	{ nombre = "tortuga", filas = { "........", "..###...", ".#####.#", "########", ".#...#..", "........" } },
	{ nombre = "pez", filas = { "........", "..####.#", ".#######", "########", "..####.#", "........" } },
	{ nombre = "gato", filas = { "#.#.....", "###.....", "###..#..", ".###.#..", ".#####..", ".#..#..." } },
	{ nombre = "casa", filas = { "...##...", "..####..", ".######.", ".##..##.", ".##..##.", ".######." } },
	{ nombre = "barco", filas = { "...#....", "...##...", "...###..", "...#....", "########", ".######." } },
	{ nombre = "tucán", filas = { "..##....", ".##.####", ".#####..", "..###...", "..##....", "..#.#..." } },
	{ nombre = "árbol", filas = { ".######.", "########", ".######.", "...##...", "...##...", "..####.." } },
}

local function leer(filas: { string }, espejo: boolean): Figura
	local f: Figura = {}
	for i, texto in filas do
		local fila: { boolean } = {}
		for j = 1, Escondido.ANCHO do
			local c = if espejo then Escondido.ANCHO + 1 - j else j
			fila[j] = string.sub(texto, c, c) == "#"
		end
		f[i] = fila
	end
	return f
end

local function copiar(f: Figura): Figura
	local g: Figura = {}
	for i, fila in f do
		g[i] = table.clone(fila)
	end
	return g
end

-- Cuadritos {fila, columna} que tapa el bloque k (1..12, de izquierda a derecha y de arriba abajo).
function Escondido.celdas(k: number): { { number } }
	local bx = (k - 1) % Escondido.BX + 1
	local by = (k - 1) // Escondido.BX + 1
	local t = {}
	for df = 0, 1 do
		for dc = 0, 1 do
			table.insert(t, { (by - 1) * 2 + 1 + df, (bx - 1) * 2 + 1 + dc })
		end
	end
	return t
end

local function llenos(f: Figura, k: number): number
	local n = 0
	for _, p in Escondido.celdas(k) do
		if f[p[1]][p[2]] then
			n += 1
		end
	end
	return n
end

local function total(f: Figura): number
	local n = 0
	for _, fila in f do
		for _, v in fila do
			if v then
				n += 1
			end
		end
	end
	return n
end

-- ¿Algún cuadrito pegado al bloque (por fuera) está lleno? Sirve para que lo que se agregue quede pegado a la figura.
local function tocaFigura(f: Figura, k: number): boolean
	local dentro: { [string]: boolean } = {}
	for _, p in Escondido.celdas(k) do
		dentro[p[1] .. "," .. p[2]] = true
	end
	for _, p in Escondido.celdas(k) do
		for _, d in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
			local fi, co = p[1] + d[1], p[2] + d[2]
			if
				fi >= 1
				and fi <= Escondido.ALTO
				and co >= 1
				and co <= Escondido.ANCHO
				and not dentro[fi .. "," .. co]
				and f[fi][co]
			then
				return true
			end
		end
	end
	return false
end

-- La figura con el bloque k cambiado: si estaba casi vacío se llena, si no, se vacía.
local function mutar(f: Figura, k: number): Figura
	local g = copiar(f)
	local poner = llenos(f, k) < 2
	for _, p in Escondido.celdas(k) do
		g[p[1]][p[2]] = poner
	end
	return g
end

-- Bloques donde un cambio se ve como parte de la figura (un pedazo de más o de menos en el borde).
local function candidatos(f: Figura): { number }
	local t = {}
	for k = 1, Escondido.BLOQUES do
		local n = llenos(f, k)
		local cambiada = total(f) - n + (if n < 2 then 4 else 0)
		if cambiada >= 8 and ((n > 0 and n < 4) or (n == 0 and tocaFigura(f, k)) or (n == 4 and tocaFigura(mutar(f, k), k))) then
			table.insert(t, k)
		end
	end
	return t
end

local function barajar<T>(t: { T }, azar: Azar)
	for i = #t, 2, -1 do
		local j = azar(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

function Escondido.igualEnBloque(a: Figura, b: Figura, k: number): boolean
	for _, p in Escondido.celdas(k) do
		if a[p[1]][p[2]] ~= b[p[1]][p[2]] then
			return false
		end
	end
	return true
end

-- ¿La opción j coincide con todo lo que ya está destapado?
function Escondido.coincide(e: Estado, j: number): boolean
	for k = 1, Escondido.BLOQUES do
		if not e.tapado[k] and not Escondido.igualEnBloque(e.opciones[j], e.opciones[e.correcta], k) then
			return false
		end
	end
	return true
end

-- La menor cantidad de bloques tapados que hay que destapar para que solo quede la opción correcta.
function Escondido.minimo(e: Estado): number
	local rivales: { number } = {}
	for j = 1, #e.opciones do
		if j ~= e.correcta and not e.descartada[j] and Escondido.coincide(e, j) then
			table.insert(rivales, j)
		end
	end
	if #rivales == 0 then
		return 0
	end
	local tapados: { number } = {}
	for k = 1, Escondido.BLOQUES do
		if e.tapado[k] then
			table.insert(tapados, k)
		end
	end
	local buena = e.opciones[e.correcta]
	local function descarta(elegidos: { number }): boolean
		for _, j in rivales do
			local distinta = false
			for _, k in elegidos do
				if not Escondido.igualEnBloque(e.opciones[j], buena, k) then
					distinta = true
					break
				end
			end
			if not distinta then
				return false
			end
		end
		return true
	end
	-- Hay a lo sumo 2 rivales y cada uno difiere en un bloque: alcanza con probar grupos de hasta 2.
	for _, k in tapados do
		if descarta({ k }) then
			return 1
		end
	end
	for a = 1, #tapados do
		for b = a + 1, #tapados do
			if descarta({ tapados[a], tapados[b] }) then
				return 2
			end
		end
	end
	return #rivales
end

-- Ronda nueva. `dos` = ayuda: solo 2 opciones.
function Escondido.generar(nivel: number, azar: Azar, dos: boolean?): Estado
	local dibujo = DIBUJOS[azar(1, #DIBUJOS)]
	local base = leer(dibujo.filas, azar(1, 2) == 1)
	local cand = candidatos(base)
	barajar(cand, azar)
	local cuantas = if dos then 1 else 2
	local decisivos: { number } = {}
	for i = 1, cuantas do
		decisivos[i] = cand[i]
	end

	local opciones: { Figura } = { base }
	for _, k in decisivos do
		table.insert(opciones, mutar(base, k))
	end
	local orden: { number } = {}
	for i = 1, #opciones do
		orden[i] = i
	end
	barajar(orden, azar)
	local mezcladas: { Figura } = {}
	local correcta = 1
	for i, o in orden do
		mezcladas[i] = opciones[o]
		if o == 1 then
			correcta = i
		end
	end

	local tapado: { boolean } = {}
	for k = 1, Escondido.BLOQUES do
		tapado[k] = nivel >= 2
	end
	if nivel < 2 then
		-- Casi destapada: quedan tapados los bloques que deciden y 2 más, para que haya que elegir dónde mirar.
		for _, k in decisivos do
			tapado[k] = true
		end
		local resto: { number } = {}
		for k = 1, Escondido.BLOQUES do
			if not tapado[k] then
				table.insert(resto, k)
			end
		end
		barajar(resto, azar)
		tapado[resto[1]] = true
		tapado[resto[2]] = true
	end

	local descartada: { boolean } = {}
	for j = 1, #mezcladas do
		descartada[j] = false
	end
	local e: Estado = {
		nivel = nivel,
		nombre = dibujo.nombre,
		opciones = mezcladas,
		correcta = correcta,
		tapado = tapado,
		descartada = descartada,
		destapados = 0,
		errores = 0,
		minimo = 0,
		resuelto = false,
	}
	e.minimo = Escondido.minimo(e)
	return e
end

-- Destapa el bloque k. Devuelve false si ya estaba destapado.
function Escondido.destapar(e: Estado, k: number): boolean
	if not e.tapado[k] or e.resuelto then
		return false
	end
	e.tapado[k] = false
	e.destapados += 1
	return true
end

-- Un bloque tapado que todavía descarta alguna opción (o nil si ya no hace falta destapar nada).
function Escondido.bloqueQueAyuda(e: Estado): number?
	for k = 1, Escondido.BLOQUES do
		if e.tapado[k] then
			for j = 1, #e.opciones do
				if
					j ~= e.correcta
					and not e.descartada[j]
					and not Escondido.igualEnBloque(e.opciones[j], e.opciones[e.correcta], k)
				then
					return k
				end
			end
		end
	end
	return nil
end

-- Elige la opción j. Si se equivoca: se descarta, se destapa un bloque que ayuda y cuenta como destapado.
-- Devuelve si acertó y, si falló, qué bloque se destapó de ayuda.
function Escondido.adivinar(e: Estado, j: number): (boolean, number?)
	if e.resuelto or e.descartada[j] then
		return false, nil
	end
	if j == e.correcta then
		e.resuelto = true
		return true, nil
	end
	e.descartada[j] = true
	e.errores += 1
	e.destapados += 1
	local k = Escondido.bloqueQueAyuda(e)
	if k then
		e.tapado[k] = false
	end
	return false, k
end

-- 3 estrellas si destapó lo mínimo sin equivocarse, 2 si se pasó por poco, 1 si no. Con un error, 2 como mucho:
-- acertar entre las que quedan sin destapar lo que decide es adivinar, no deducir.
function Escondido.estrellas(e: Estado): number
	local extra = e.destapados - e.minimo
	local s = if extra <= 0 then 3 elseif extra <= 2 then 2 else 1
	if e.errores > 0 then
		s = math.min(s, 2)
	end
	return s
end

-- ¿Supo dónde mirar? Acertó a la primera y sin destapar mucho más de lo justo.
function Escondido.buenaHipotesis(e: Estado): boolean
	return e.errores == 0 and e.destapados <= e.minimo + 1
end

return Escondido
