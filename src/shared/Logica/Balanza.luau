--!strict
-- Lógica pura de «La Balanza» (instrucciones.md §2). Sin APIs de Roblox: se prueba con Lune (pruebas/balanza.luau).
--
-- Dos platos («izq» y «der») y una bandeja con bloques sueltos. Cada bloque tiene un peso; las cajas misteriosas
-- esconden el suyo. La balanza se inclina hacia el lado que pesa más. El niño:
--   nivel 1  predice hacia dónde se inclina (sin tocar nada);
--   nivel 2  empareja una caja sola con bloques de la bandeja y dice cuánto pesa;
--   nivel 3  igual, pero la caja tiene bloques al lado (hay que restar);
--   nivel 4  «dame 2 y quedamos iguales»: predice cuántos bloques pasar de un plato al otro y los pasa;
--   nivel 5  dos cajas iguales en un plato: dice cuánto pesa UNA.
--
-- `azar(a, b)` devuelve un entero entre a y b (incluidos). En Roblox: Random.new():NextInteger; en pruebas: math.random.

export type Azar = (number, number) -> number
export type Lado = "izq" | "der" | "bandeja"
export type Tipo = "predecir" | "caja" | "pasar"

-- fijo = venía puesto en un plato al empezar (en «caja» no se mueve).
export type Bloque = { id: number, peso: number, misterio: boolean, lado: Lado, fijo: boolean }

export type Reto = {
	nivel: number,
	tipo: Tipo,
	bloques: { Bloque },
	pesoCaja: number?, -- peso de UNA caja misteriosa (todas pesan igual en un reto)
	movidas: number, -- bloques que el niño movió
}

local Balanza = {}

Balanza.NIVELES = 5
Balanza.TITULOS = {
	"¿Qué lado pesa más?",
	"La caja misteriosa",
	"La caja con compañía",
	"Dame y quedamos iguales",
	"Dos cajas iguales",
}

local function nuevoReto(nivel: number, tipo: Tipo): Reto
	return { nivel = nivel, tipo = tipo, bloques = {}, pesoCaja = nil, movidas = 0 }
end

local function poner(r: Reto, peso: number, lado: Lado, misterio: boolean?)
	table.insert(
		r.bloques,
		{ id = #r.bloques + 1, peso = peso, misterio = misterio == true, lado = lado, fijo = false }
	)
end

local function bandeja(r: Reto, pesos: { number })
	for _, p in pesos do
		poner(r, p, "bandeja")
	end
end

function Balanza.total(r: Reto, lado: Lado): number
	local s = 0
	for _, b in r.bloques do
		if b.lado == lado then
			s += b.peso
		end
	end
	return s
end

-- 1 = baja la izquierda, -1 = baja la derecha, 0 = parejas.
function Balanza.inclinacion(r: Reto): number
	local d = Balanza.total(r, "izq") - Balanza.total(r, "der")
	return if d > 0 then 1 elseif d < 0 then -1 else 0
end

function Balanza.diferencia(r: Reto): number
	return Balanza.total(r, "izq") - Balanza.total(r, "der")
end

function Balanza.parejas(r: Reto): boolean
	return Balanza.diferencia(r) == 0
end

function Balanza.bloque(r: Reto, id: number): Bloque?
	return r.bloques[id]
end

-- Mueve un bloque. En «caja» los bloques de la bandeja van a un plato y vuelven a la bandeja; las cajas y los
-- bloques que venían puestos no se mueven. En «pasar» un bloque de un plato salta al otro. Devuelve si se movió.
function Balanza.mover(r: Reto, id: number, destino: Lado): boolean
	local b = r.bloques[id]
	if not b or b.misterio or b.lado == destino or r.tipo == "predecir" then
		return false
	end
	if r.tipo == "caja" and b.fijo then
		return false
	end
	if r.tipo == "pasar" and destino == "bandeja" then
		return false
	end
	b.lado = destino
	r.movidas += 1
	return true
end

local function fijar(r: Reto)
	for _, b in r.bloques do
		if b.lado ~= "bandeja" then
			b.fijo = true
		end
	end
end

function Balanza.esFijo(b: Bloque): boolean
	return b.fijo or b.misterio
end

function Balanza.generar(nivel: number, azar: Azar): Reto
	if nivel <= 1 then
		local r = nuevoReto(1, "predecir")
		local nI, nD = azar(1, 3), azar(1, 3)
		for _ = 1, nI do
			poner(r, azar(1, 5), "izq")
		end
		for _ = 1, nD do
			poner(r, azar(1, 5), "der")
		end
		-- A veces quedan parejas a propósito (que «parejas» también sea una respuesta posible).
		if azar(1, 4) == 1 then
			local d = Balanza.diferencia(r)
			if d ~= 0 then
				poner(r, math.abs(d), if d > 0 then "der" else "izq")
			end
		end
		return r
	elseif nivel == 2 then
		local r = nuevoReto(2, "caja")
		local w = azar(3, 9)
		r.pesoCaja = w
		poner(r, w, "izq", true)
		fijar(r)
		bandeja(r, { 1, 1, 2, 2, 5 })
		return r
	elseif nivel == 3 then
		local r = nuevoReto(3, "caja")
		local w = azar(2, 7)
		r.pesoCaja = w
		poner(r, w, "izq", true)
		local a = azar(1, 3)
		poner(r, a, "izq")
		-- A la derecha ya hay algo, pero menos que la izquierda: falta completar con la bandeja.
		poner(r, azar(1, math.max(1, w + a - 2)), "der")
		fijar(r)
		bandeja(r, { 1, 1, 2, 2, 5 })
		return r
	elseif nivel == 4 then
		local r = nuevoReto(4, "pasar")
		local menos = azar(2, 4)
		local d = 2 * azar(1, 3) -- diferencia par: 2, 4 o 6
		local izqMas = azar(0, 1) == 1
		for _ = 1, menos + d do
			poner(r, 1, if izqMas then "izq" else "der")
		end
		for _ = 1, menos do
			poner(r, 1, if izqMas then "der" else "izq")
		end
		return r
	else
		local r = nuevoReto(5, "caja")
		local w = azar(2, 5)
		r.pesoCaja = w
		poner(r, w, "izq", true)
		poner(r, w, "izq", true)
		if azar(0, 1) == 1 then
			poner(r, 1, "izq")
		end
		fijar(r)
		bandeja(r, { 1, 1, 2, 2, 5, 5 })
		return r
	end
end

-- Opciones para «¿hacia dónde se inclina?»: 1 = izquierda, 2 = parejas, 3 = derecha.
Balanza.OPCIONES_INCLINA = { "⬅ Baja la izquierda", "Quedan parejas", "Baja la derecha ➡" }
function Balanza.opcionInclina(r: Reto): number
	local i = Balanza.inclinacion(r)
	return if i > 0 then 1 elseif i == 0 then 2 else 3
end

local function mezclar(t: { number }, azar: Azar): { number }
	for i = #t, 2, -1 do
		local j = azar(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

-- Tres opciones de respuesta (números distintos, positivos) con la correcta y los errores típicos.
local function tres(correcta: number, distractores: { number }, azar: Azar): { number }
	local usadas = { [correcta] = true }
	local ops = { correcta }
	for _, d in distractores do
		if #ops < 3 and d > 0 and not usadas[d] then
			usadas[d] = true
			table.insert(ops, d)
		end
	end
	local k = 1
	while #ops < 3 do
		for _, d in { correcta + k, correcta - k } do
			if #ops < 3 and d > 0 and not usadas[d] then
				usadas[d] = true
				table.insert(ops, d)
			end
		end
		k += 1
	end
	return mezclar(ops, azar)
end

-- «¿Cuánto pesa la caja?» (niveles 2, 3 y 5). Errores típicos: decir el total del otro plato (no restar),
-- o el peso de las dos cajas juntas.
function Balanza.opcionesPeso(r: Reto, azar: Azar): { number }
	local w = r.pesoCaja :: number
	local der = Balanza.total(r, "der")
	local juntas = 0
	for _, b in r.bloques do
		if b.misterio then
			juntas += b.peso
		end
	end
	return tres(w, { der, juntas, w + 1 }, azar)
end

-- «¿Cuántos bloques hay que pasar?» (nivel 4). Error típico: pasar toda la diferencia.
function Balanza.pasarNecesarios(r: Reto): number
	return math.abs(Balanza.diferencia(r)) // 2
end

function Balanza.opcionesPasar(r: Reto, azar: Azar): { number }
	local k = Balanza.pasarNecesarios(r)
	return tres(k, { 2 * k, k + 1 }, azar)
end

-- Ayuda: un bloque que acerca a emparejar.
--   «caja»: de la bandeja, el más pesado que cabe en lo que le falta al lado liviano; si se pasó, uno que sobra.
--   «pasar»: uno del plato pesado.
-- Devuelve el id del bloque y a qué lado conviene llevarlo, o nil si ya están parejas.
function Balanza.ayuda(r: Reto): (number?, Lado?)
	local d = Balanza.diferencia(r)
	if d == 0 then
		return nil, nil
	end
	local liviano: Lado = if d > 0 then "der" else "izq"
	local pesado: Lado = if d > 0 then "izq" else "der"
	local falta = math.abs(d)
	if r.tipo == "pasar" then
		for _, b in r.bloques do
			if b.lado == pesado then
				return b.id, liviano
			end
		end
		return nil, nil
	end
	local mejor: Bloque? = nil
	for _, b in r.bloques do
		if b.lado == "bandeja" and b.peso <= falta and (not mejor or b.peso > (mejor :: Bloque).peso) then
			mejor = b
		end
	end
	if mejor then
		return mejor.id, liviano
	end
	-- Nada cabe: quitar del lado pesado un bloque suelto que se haya puesto.
	for _, b in r.bloques do
		if b.lado == pesado and not Balanza.esFijo(b) then
			return b.id, "bandeja"
		end
	end
	-- Sacar uno chico del liviano y probar otra combinación.
	for _, b in r.bloques do
		if b.lado == liviano and not Balanza.esFijo(b) then
			return b.id, "bandeja"
		end
	end
	return nil, nil
end

-- ¿Se puede emparejar con lo que hay? (para las pruebas: todo reto de «caja» tiene solución)
function Balanza.tieneSolucion(r: Reto): boolean
	if r.tipo ~= "caja" then
		return true
	end
	local fijoI, fijoD = 0, 0
	local sueltos = {}
	for _, b in r.bloques do
		if Balanza.esFijo(b) then
			if b.lado == "izq" then
				fijoI += b.peso
			elseif b.lado == "der" then
				fijoD += b.peso
			end
		else
			table.insert(sueltos, b.peso)
		end
	end
	-- Cada bloque suelto va a la izquierda, a la derecha o se queda: 3^n combinaciones (n ≤ 6).
	local function probar(k: number, d: number): boolean
		if k > #sueltos then
			return d == 0
		end
		local p = sueltos[k]
		return probar(k + 1, d) or probar(k + 1, d + p) or probar(k + 1, d - p)
	end
	return probar(1, fijoI - fijoD)
end

return Balanza
