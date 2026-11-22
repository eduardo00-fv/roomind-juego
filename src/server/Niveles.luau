--!strict
-- Guarda en qué nivel quedó cada niño en cada juego (DataStore), para que la próxima vez arranque ahí.
-- Clave: el UserId; valor: { [modulo] = nivel }. Si el DataStore no está disponible (en Studio hay que activar
-- Game Settings > Security > Enable Studio Access to API Services), se guarda solo mientras dure el servidor.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Niveles = {}

local okStore, store = pcall(function()
	return DataStoreService:GetDataStore("RooMindNiveles")
end)
if not okStore then
	warn("[Niveles] Sin DataStore (¿Enable Studio Access to API Services?); los niveles no se guardan entre sesiones")
end

local cache: { [number]: { [string]: number } } = {}
local cargando: { [number]: boolean } = {}

local function datos(uid: number): { [string]: number }
	while cargando[uid] do
		task.wait(0.1)
	end
	if cache[uid] then
		return cache[uid]
	end
	cargando[uid] = true
	local t: { [string]: number } = {}
	if okStore then
		local ok, v = pcall(function()
			return store:GetAsync(tostring(uid))
		end)
		if ok and type(v) == "table" then
			for k, n in v do
				if type(k) == "string" and type(n) == "number" then
					t[k] = n
				end
			end
		elseif not ok then
			warn("[Niveles] no se pudo leer: " .. tostring(v))
		end
	end
	cache[uid] = t
	cargando[uid] = nil
	return t
end

function Niveles.leer(jugador: Player, modulo: string): number
	return datos(jugador.UserId)[modulo] or 1
end

local pendientes: { [number]: boolean } = {}
local function guardar(uid: number)
	if not okStore or pendientes[uid] then
		return
	end
	pendientes[uid] = true
	task.delay(3, function() -- junta varios cambios seguidos en una sola escritura
		pendientes[uid] = nil
		local t = cache[uid]
		if t then
			local ok, err = pcall(function()
				store:SetAsync(tostring(uid), t)
			end)
			if not ok then
				warn("[Niveles] no se pudo guardar: " .. tostring(err))
			end
		end
	end)
end

function Niveles.poner(jugador: Player, modulo: string, nivel: number)
	local t = datos(jugador.UserId)
	if t[modulo] ~= nivel then
		t[modulo] = nivel
		guardar(jugador.UserId)
	end
end

Players.PlayerRemoving:Connect(function(jugador)
	local uid = jugador.UserId
	task.delay(5, function()
		if not Players:GetPlayerByUserId(uid) then
			cache[uid] = nil
		end
	end)
end)

return Niveles
