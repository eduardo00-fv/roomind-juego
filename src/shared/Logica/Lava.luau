--!strict
-- Lógica pura de «¡El suelo es lava!» (sin APIs de Roblox: se prueba con Lune en pruebas/lava.luau).
--
-- Coordenadas: fila 1 = la de abajo (junto a la salida), fila n = la de arriba (llegar ahí es ganar).
-- Columnas 1..n de izquierda a derecha. Regla del piso: exactamente una lava por fila y por columna.
--
-- `azar(a, b)` devuelve un entero entre a y b (incluidos). En Roblox: Random.new():NextInteger;
-- en las pruebas: math.random.

export type Azar = (number, number) -> number

export type Piso = {
	n: number,
	lava: { number }, -- lava[fila] = columna con lava
	conNumeros: boolean, -- nivel alto: las baldosas de piso dicen cuántas lavas tienen al lado
}

export type Estado = {
	piso: Piso,
	tanteadas: { [number]: boolean },
	lavasConocidas: { [number]: boolean },
	segurasConocidas: { [number]: boolean }, -- piso visto (tanteado o pisado)
	camino: { number }, -- baldosas pisadas en este intento (se borra al quemarse)
	posicion: number?, -- índice de la baldosa; nil = en la orilla de salida
	tanteos: number,
	quemadas: number,
	erroresMemoria: number, -- quiso pisar una lava que ya conocía
	ayudaChecks: boolean, -- después de 2 quemadas se marcan las seguras con ✓
	ganado: boolean,
}

export type ResultadoTanteo = "lava" | "piso" | "repetida"
export type ResultadoPaso = "piso" | "meta" | "quemada" | "lavaConocida" | "igual"
export type Razon = "fila" | "columna" | "adivino"

local Lava = {}

Lava.NIVELES = {
	{ n = 3, conNumeros = false },
	{ n = 4, conNumeros = false },
	{ n = 5, conNumeros = true },
}

Lava.QUEMADAS_PARA_CHECKS = 2
Lava.QUEMADAS_PARA_CAMBIAR = 4 -- «más de 3»

function Lava.indice(n: number, fila: number, col: number): number
	return (fila - 1) * n + col
end

function Lava.celda(n: number, i: number): (number, number)
	return (i - 1) // n + 1, (i - 1) % n + 1
end

function Lava.dentro(n: number, fila: number, col: number): boolean
	return fila >= 1 and fila <= n and col >= 1 and col <= n
end

function Lava.esLava(piso: Piso, fila: number, col: number): boolean
	return piso.lava[fila] == col
end

local VECINOS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- Vecinas de lado (arriba, abajo, izquierda, derecha), sin diagonales.
function Lava.vecinas(n: number, fila: number, col: number): { { number } }
	local r = {}
	for _, d in VECINOS do
		local f, c = fila + d[1], col + d[2]
		if Lava.dentro(n, f, c) then
			table.insert(r, { f, c })
		end
	end
	return r
end

function Lava.lavasAlLado(piso: Piso, fila: number, col: number): number
	local k = 0
	for _, v in Lava.vecinas(piso.n, fila, col) do
		if Lava.esLava(piso, v[1], v[2]) then
			k += 1
		end
	end
	return k
end

-- ¿Se puede ir de la fila 1 a la fila n pisando solo piso, paso a paso de lado?
function Lava.tieneCamino(piso: Piso): boolean
	local n = piso.n
	local visto: { [number]: boolean } = {}
	local cola: { { number } } = {}
	for c = 1, n do
		if not Lava.esLava(piso, 1, c) then
			visto[Lava.indice(n, 1, c)] = true
			table.insert(cola, { 1, c })
		end
	end
	local k = 1
	while k <= #cola do
		local f, c = cola[k][1], cola[k][2]
		k += 1
		if f == n then
			return true
		end
		for _, v in Lava.vecinas(n, f, c) do
			local i = Lava.indice(n, v[1], v[2])
			if not visto[i] and not Lava.esLava(piso, v[1], v[2]) then
				visto[i] = true
				table.insert(cola, v)
			end
		end
	end
	return false
end

function Lava.generar(n: number, conNumeros: boolean, azar: Azar): Piso
	for _ = 1, 200 do
		local perm = {}
		for i = 1, n do
			perm[i] = i
		end
		for i = n, 2, -1 do
			local j = azar(1, i)
			perm[i], perm[j] = perm[j], perm[i]
		end
		local piso = { n = n, lava = perm, conNumeros = conNumeros }
		if Lava.tieneCamino(piso) then
			return piso
		end
	end
	error("no se encontró un piso con camino")
end

function Lava.nuevo(piso: Piso): Estado
	return {
		piso = piso,
		tanteadas = {},
		lavasConocidas = {},
		segurasConocidas = {},
		camino = {},
		posicion = nil,
		tanteos = 0,
		quemadas = 0,
		erroresMemoria = 0,
		ayudaChecks = false,
		ganado = false,
	}
end

function Lava.tantear(e: Estado, fila: number, col: number): ResultadoTanteo
	local n = e.piso.n
	assert(Lava.dentro(n, fila, col), "baldosa fuera del piso")
	local i = Lava.indice(n, fila, col)
	if e.tanteadas[i] or e.lavasConocidas[i] or e.segurasConocidas[i] then
		return "repetida" -- ya se sabía: no cuesta
	end
	e.tanteadas[i] = true
	e.tanteos += 1
	if Lava.esLava(e.piso, fila, col) then
		e.lavasConocidas[i] = true
		return "lava"
	end
	e.segurasConocidas[i] = true
	return "piso"
end

-- El personaje entra a la baldosa (fila, col). En 3D se camina libre, así que no se exige que sea vecina.
function Lava.pisar(e: Estado, fila: number, col: number): ResultadoPaso
	local n = e.piso.n
	assert(Lava.dentro(n, fila, col), "baldosa fuera del piso")
	local i = Lava.indice(n, fila, col)
	if e.posicion == i then
		return "igual"
	end
	if e.lavasConocidas[i] then
		e.erroresMemoria += 1
		return "lavaConocida" -- se avisa y no se quema
	end
	if Lava.esLava(e.piso, fila, col) then
		e.quemadas += 1
		e.lavasConocidas[i] = true
		e.camino = {}
		e.posicion = nil
		if e.quemadas >= Lava.QUEMADAS_PARA_CHECKS then
			e.ayudaChecks = true
		end
		return "quemada"
	end
	e.segurasConocidas[i] = true
	e.posicion = i
	table.insert(e.camino, i)
	if fila == n then
		e.ganado = true
		return "meta"
	end
	return "piso"
end

-- Volver a la orilla sin quemarse (por ejemplo, si camina de regreso a la salida).
function Lava.alaOrilla(e: Estado)
	e.posicion = nil
end

-- Lo que se puede deducir con lo que ya se vio: devuelve (seguras, lavas) como conjuntos de índices.
-- Reglas: una lava conocida vuelve piso el resto de su fila y su columna; si en una fila (o columna)
-- todas menos una son piso, la que queda es lava. Se repite hasta que no cambie nada.
function Lava.deducir(e: Estado): ({ [number]: boolean }, { [number]: boolean })
	local n = e.piso.n
	local seguras: { [number]: boolean } = table.clone(e.segurasConocidas)
	local lavas: { [number]: boolean } = table.clone(e.lavasConocidas)
	local cambio = true
	while cambio do
		cambio = false
		for i in lavas do
			local f, c = Lava.celda(n, i)
			for k = 1, n do
				for _, j in { Lava.indice(n, f, k), Lava.indice(n, k, c) } do
					if j ~= i and not seguras[j] then
						seguras[j] = true
						cambio = true
					end
				end
			end
		end
		for linea = 1, n do
			for _, porFila in { true, false } do
				local libres, tieneLava, ultima = 0, false, 0
				for k = 1, n do
					local j = if porFila then Lava.indice(n, linea, k) else Lava.indice(n, k, linea)
					if lavas[j] then
						tieneLava = true
					elseif not seguras[j] then
						libres += 1
						ultima = j
					end
				end
				if not tieneLava and libres == 1 then
					lavas[ultima] = true
					cambio = true
				end
			end
		end
	end
	return seguras, lavas
end

-- Por qué una baldosa es segura, usando solo las lavas que ya se ven (lo que el niño puede decir).
function Lava.razon(e: Estado, fila: number, col: number): Razon
	local n = e.piso.n
	for k = 1, n do
		if k ~= col and e.lavasConocidas[Lava.indice(n, fila, k)] then
			return "fila"
		end
	end
	for k = 1, n do
		if k ~= fila and e.lavasConocidas[Lava.indice(n, k, col)] then
			return "columna"
		end
	end
	return "adivino"
end

-- ¿La respuesta del niño a «¿por qué es segura?» es correcta?
function Lava.razonCorrecta(e: Estado, fila: number, col: number, eleccion: Razon): boolean
	local n = e.piso.n
	if eleccion == "adivino" then
		return Lava.razon(e, fila, col) == "adivino"
	end
	for k = 1, n do
		local j = if eleccion == "fila" then Lava.indice(n, fila, k) else Lava.indice(n, k, col)
		local propia = if eleccion == "fila" then k == col else k == fila
		if not propia and e.lavasConocidas[j] then
			return true
		end
	end
	return false
end

-- Cada quemada cuenta como dos tanteos.
function Lava.costo(e: Estado): number
	return e.tanteos + 2 * e.quemadas
end

function Lava.estrellas(e: Estado): number
	local n, costo = e.piso.n, Lava.costo(e)
	if costo <= n - 2 then
		return 3
	elseif costo <= n then
		return 2
	end
	return 1
end

function Lava.hayQueCambiar(e: Estado): boolean
	return e.quemadas >= Lava.QUEMADAS_PARA_CAMBIAR
end

-- Piso nuevo del mismo tamaño con la lava de la primera fila ya descubierta (el regalo).
-- Devuelve el estado nuevo y el índice de la lava regalada.
function Lava.pisoDeRegalo(e: Estado, azar: Azar): (Estado, number)
	local piso = Lava.generar(e.piso.n, e.piso.conNumeros, azar)
	local nuevo = Lava.nuevo(piso)
	local i = Lava.indice(piso.n, 1, piso.lava[1])
	nuevo.lavasConocidas[i] = true
	return nuevo, i
end

return Lava
