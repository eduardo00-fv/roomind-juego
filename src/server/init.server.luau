--!strict
-- Servidor: recibe del cliente el avance de cada partida para mandarlo a la web de papás.
-- Los minijuegos corren en el cliente (src/client/Juegos); aquí solo se valida lo que llega.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modulos = require(ReplicatedStorage.Shared.Modulos)
local Niveles = require(script.Niveles)
local Reporte = require(script.Reporte)

local partida = Instance.new("RemoteEvent")
partida.Name = "Partida"
partida.Parent = ReplicatedStorage

-- El cliente pregunta en qué nivel quedó antes de empezar un juego.
local nivelGuardado = Instance.new("RemoteFunction")
nivelGuardado.Name = "NivelGuardado"
nivelGuardado.Parent = ReplicatedStorage
nivelGuardado.OnServerInvoke = function(jugador: Player, modulo: any): number
	if type(modulo) ~= "string" or not Modulos[modulo] then
		return 1
	end
	return Niveles.leer(jugador, modulo)
end
local moduloActual: { [Player]: string } = {}

local HABILIDADES = { memoria = true, inductivo = true, deductivo = true, geometrico = true }
local MAX_RETOS = 80
local retosPorJugador: { [Player]: number } = {}

local function numero(v: any): number?
	if type(v) == "number" and v == v and v >= 0 and v < 1e6 then
		return v
	end
	return nil
end

partida.OnServerEvent:Connect(function(jugador: Player, accion: any, datos: any)
	if accion == "empezar" and type(datos) == "string" and Modulos[datos] then
		Reporte.empezar(jugador, datos)
		retosPorJugador[jugador] = 0
		moduloActual[jugador] = datos
	elseif accion == "reto" and type(datos) == "table" then
		local k = (retosPorJugador[jugador] or 0) + 1
		if k > MAX_RETOS then
			return
		end
		retosPorJugador[jugador] = k
		local aciertos, intentos = numero(datos.aciertos), numero(datos.intentos)
		local pistas, segundos = numero(datos.pistas), numero(datos.segundos)
		if
			type(datos.reto) ~= "string"
			or #datos.reto > 40
			or not HABILIDADES[datos.habilidad]
			or not (aciertos and intentos and pistas and segundos)
		then
			return
		end
		Reporte.reto(jugador, {
			reto = datos.reto,
			habilidad = datos.habilidad,
			aciertos = math.min(aciertos :: number, intentos :: number),
			intentos = intentos :: number,
			pistas = pistas :: number,
			segundos = segundos :: number,
		})
	elseif accion == "nivel" and type(datos) == "table" then
		local modulo = moduloActual[jugador]
		local n, max = datos.nivel, datos.niveles
		if modulo and type(n) == "number" and type(max) == "number" and max >= 1 and max <= 20 then
			n = math.clamp(math.floor(n), 1, math.floor(max))
			Niveles.poner(jugador, modulo, n)
			Reporte.nivel(jugador, n, math.floor(max))
		end
	elseif accion == "terminar" then
		Reporte.terminar(jugador, datos == true)
		retosPorJugador[jugador] = nil
		moduloActual[jugador] = nil
	end
end)
