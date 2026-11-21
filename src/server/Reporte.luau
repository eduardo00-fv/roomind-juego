--!strict
-- Lleva la cuenta de cada partida y se la manda a nuestro servidor (papas/servidor, ver papas/API.md).
--
-- Uso desde el código de un módulo (solo en el servidor):
--   local Reporte = require(script.Parent.Reporte)
--   Reporte.empezar(jugador, "lava")
--   Reporte.reto(jugador, { reto = "lava-3x3", habilidad = "deductivo", aciertos = 2, intentos = 3, pistas = 1, segundos = 40 })
--   Reporte.terminar(jugador, true)   -- true = completó el módulo
-- Si el jugador se va a medias, se manda solo con completo = false.
--
-- Configuración (una vez por juego):
--   * Game Settings > Security > Allow HTTP Requests = activado.
--   * Secreto "clave_juego" con el valor de CLAVE_JUEGO de papas/.env:
--       - para publicar: Creator Hub > el juego > Secrets, con el dominio del servidor;
--       - para probar en Studio: Game Settings > Security > Secrets (JSON {"clave_juego": ["valor", "dominio"]}).
--   * La URL pública del servidor en el atributo "UrlServidor" de ServerScriptService
--     (ej. https://mi-maquina.tail1234.ts.net). Roblox no puede llegar a localhost.
--   * El juego NUNCA le muestra al niño la URL ni habla de premios en dinero (reglas de Roblox).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modulos = require(ReplicatedStorage.Shared.Modulos)

export type Reto = {
	reto: string,
	habilidad: string,
	aciertos: number,
	intentos: number,
	pistas: number,
	segundos: number,
}

type Partida = { modulo: string, inicio: number, retos: { Reto } }

local Reporte = {}
local partidas: { [Player]: Partida } = {}

local function enviar(cuerpo: { [string]: any })
	local url = ServerScriptService:GetAttribute("UrlServidor")
	if type(url) ~= "string" or url == "" then
		warn("[Reporte] Falta el atributo UrlServidor en ServerScriptService; no se envía")
		return
	end
	local okSecreto, clave = pcall(function()
		return HttpService:GetSecret("clave_juego")
	end)
	if not okSecreto then
		warn("[Reporte] Falta el secreto clave_juego; no se envía")
		return
	end
	local json = HttpService:JSONEncode(cuerpo)
	for intento = 1, 3 do
		local ok, resp = pcall(function()
			return HttpService:RequestAsync({
				Url = url .. "/api/juego/reporte",
				Method = "POST",
				Headers = { ["content-type"] = "application/json", ["x-api-key"] = clave },
				Body = json,
			})
		end)
		if ok and resp.Success then
			return
		end
		warn(("[Reporte] intento %d falló: %s"):format(intento, ok and tostring(resp.StatusCode) or tostring(resp)))
		task.wait(2 ^ intento)
	end
end

function Reporte.empezar(jugador: Player, modulo: string)
	assert(Modulos[modulo], "Módulo desconocido: " .. modulo)
	partidas[jugador] = { modulo = modulo, inicio = os.clock(), retos = {} }
end

function Reporte.reto(jugador: Player, r: Reto)
	local p = partidas[jugador]
	if not p then
		warn("[Reporte] reto sin partida empezada")
		return
	end
	table.insert(p.retos, {
		reto = r.reto,
		habilidad = r.habilidad,
		aciertos = math.max(0, math.floor(r.aciertos)),
		intentos = math.max(0, math.floor(r.intentos)),
		pistas = math.max(0, math.floor(r.pistas)),
		segundos = math.max(0, math.floor(r.segundos)),
	})
end

function Reporte.terminar(jugador: Player, completo: boolean)
	local p = partidas[jugador]
	if not p then
		return
	end
	partidas[jugador] = nil
	local cuerpo = {
		robloxId = jugador.UserId,
		modulo = p.modulo,
		completo = completo,
		segundos = math.floor(os.clock() - p.inicio),
		retos = p.retos,
	}
	task.spawn(enviar, cuerpo)
end

Players.PlayerRemoving:Connect(function(jugador)
	Reporte.terminar(jugador, false)
end)

return Reporte
