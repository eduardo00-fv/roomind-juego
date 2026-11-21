--!strict
-- Cliente: escucha los portales y corre el minijuego que toque.
--
-- De dónde salen los juegos (pueden estar en cualquiera de los dos lados):
--   * src/client/Juegos/<Nombre>.luau (Rojo; hoy la Lava).
--   * ReplicatedStorage.Juegos.<Nombre> (ModuleScripts hechos en Studio por el equipo; Rojo no toca esa carpeta).
-- El nombre del módulo en minúscula es el id (Balanza -> balanza). Cada uno exporta jugar(ctx) -> completo.
--
-- Portales: cualquier parte con la etiqueta «Portal» y el atributo «Modulo». Están en la plaza y, para probar
-- cada juego por aparte, en su zona (Workspace.Zonas.<Nombre>.Probar): Play Here al lado y pisarla.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Estilo = require(ReplicatedStorage.Shared.Estilo)
local Modulos = require(ReplicatedStorage.Shared.Modulos)
local Interfaz = require(script.Interfaz)

local Juegos: { [string]: any } = {}

local function cargar(m: Instance, origen: string)
	if not m:IsA("ModuleScript") then
		return
	end
	local id = string.lower(m.Name)
	local ok, juego = pcall(require, m)
	if ok and type(juego) == "table" and type(juego.jugar) == "function" then
		Juegos[id] = juego
	else
		warn(("[Juegos] %s.%s no cargó: %s"):format(origen, m.Name, if ok then "no exporta jugar(ctx)" else tostring(juego)))
	end
end

for _, m in script.Juegos:GetChildren() do
	cargar(m, "Client.Juegos")
end
local equipo = ReplicatedStorage:FindFirstChild("Juegos")
if equipo then
	for _, m in equipo:GetChildren() do
		cargar(m, "ReplicatedStorage.Juegos")
	end
end

local partida = ReplicatedStorage:WaitForChild("Partida") :: RemoteEvent
local jugador = Players.LocalPlayer
local enJuego = false
local avisado: { [string]: number } = {}

local function llevar(destino: BasePart | CFrame)
	local ch = jugador.Character
	if ch then
		local cf = if typeof(destino) == "CFrame" then destino else (destino :: BasePart).CFrame
		ch:PivotTo(cf + Vector3.new(0, 4, 0))
	end
end

local function zona(id: string): Instance?
	local zonas = workspace:FindFirstChild("Zonas")
	if not zonas then
		return nil
	end
	for _, z in zonas:GetChildren() do
		if string.lower(z.Name) == id then
			return z
		end
	end
	return nil
end

local function entrar(id: string, alfombra: BasePart)
	if enJuego then
		return
	end
	local juego = Juegos[id]
	if not juego then
		if os.clock() - (avisado[id] or -10) > 4 then
			avisado[id] = os.clock()
			local nombre = if Modulos[id] then Modulos[id].nombre else id
			Interfaz.mensaje(nombre .. " está en construcción. ¡Probá la lava!", nil, 3)
		end
		return
	end
	enJuego = true
	partida:FireServer("empezar", id)
	local ctx = {
		id = id,
		reto = function(datos: { [string]: any })
			partida:FireServer("reto", datos)
		end,
		interfaz = Interfaz,
		estilo = Estilo,
		zona = zona(id),
		llevar = llevar,
	}
	local ok, completo = pcall(juego.jugar, ctx)
	if not ok then
		warn("[" .. id .. "] " .. tostring(completo))
		completo = false
	end
	partida:FireServer("terminar", completo == true)
	local plaza = workspace:FindFirstChild("Plaza")
	local enPlaza = plaza ~= nil and alfombra:IsDescendantOf(plaza)
	Interfaz.telon(if enPlaza then "De vuelta a la plaza" else "De vuelta a la zona", function()
		if enPlaza then
			-- Unos pasos delante del portal y mirando al centro.
			local p = alfombra.Position * Vector3.new(0.7, 0, 0.7) + Vector3.new(0, 4, 0)
			llevar(CFrame.lookAt(p, Vector3.new(0, 4, 0)))
		else
			-- Alfombra de prueba en una zona: al lado, para volver a probar.
			llevar(alfombra.CFrame + Vector3.new(12, 0, 0))
		end
	end)
	task.wait(1)
	enJuego = false
end

local function conectar(alfombra: Instance)
	if not alfombra:IsA("BasePart") then
		return
	end
	local id = alfombra:GetAttribute("Modulo")
	if type(id) ~= "string" then
		return
	end
	alfombra.Touched:Connect(function(otro)
		local ch = jugador.Character
		if ch and otro:IsDescendantOf(ch) then
			task.spawn(entrar, id, alfombra)
		end
	end)
end

for _, a in CollectionService:GetTagged("Portal") do
	conectar(a)
end
CollectionService:GetInstanceAddedSignal("Portal"):Connect(conectar)
