--!strict
-- Cliente: escucha los portales y corre el minijuego que toque.
--
-- De dónde salen los juegos (pueden estar en cualquiera de los dos lados):
--   * src/client/Juegos/<Nombre>.luau (Rojo; hoy la Lava).
--   * ReplicatedStorage.Juegos.<Nombre> (ModuleScripts hechos en Studio por el equipo; Rojo no toca esa carpeta).
-- El nombre del módulo en minúscula es el id (Balanza -> balanza). Cada uno exporta jugar(ctx) -> completo.
--
-- Vuelta al lobby: partes con la etiqueta «Lobby» (ver abajo).
-- Portales: cualquier parte con la etiqueta «Portal» y el atributo «Modulo» (texto: el id del juego, ej. balanza).
-- El lobby lo arma el equipo en Studio: para que una parte sea portal, en sus Properties agregar el Tag «Portal»
-- y el atributo «Modulo». Cada zona de prueba trae su alfombra (Workspace.Zonas.<Nombre>.Probar).

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
		warn(
			("[Juegos] %s.%s no cargó: %s"):format(
				origen,
				m.Name,
				if ok then "no exporta jugar(ctx)" else tostring(juego)
			)
		)
	end
end

-- Primero los del equipo y después los de Rojo: si hay dos con el mismo nombre, gana el de Rojo
-- (así una plantilla vacía en ReplicatedStorage no tapa un juego terminado).
local equipo = ReplicatedStorage:FindFirstChild("Juegos")
if equipo then
	for _, m in equipo:GetChildren() do
		cargar(m, "ReplicatedStorage.Juegos")
	end
end
for _, m in script.Juegos:GetChildren() do
	cargar(m, "Client.Juegos")
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

-- La zona (escenario) de un juego: Workspace.Zonas.<Nombre> o, si no, Workspace.<Nombre>.
local function zona(id: string): Instance?
	for _, lugar in { workspace:FindFirstChild("Zonas"), workspace } do
		if lugar then
			for _, z in lugar:GetChildren() do
				if string.lower(z.Name) == id and (z:IsA("Model") or z:IsA("Folder")) then
					return z
				end
			end
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
	-- De vuelta al lado del portal por el que entró (en el lobby o en la zona de prueba).
	Interfaz.telon("¡De vuelta!", function()
		llevar(alfombra.CFrame + Vector3.new(0, 0, 12))
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

-- Portales de vuelta al lobby: partes con el tag «Lobby». Llevan a la parte con el tag «LobbyDestino» o, si no
-- hay, al SpawnLocation del lobby (el primero que no esté dentro de un juego).
local function destinoLobby(): BasePart?
	local marcado = CollectionService:GetTagged("LobbyDestino")[1]
	if marcado and marcado:IsA("BasePart") then
		return marcado
	end
	local zonas = workspace:FindFirstChild("Zonas")
	for _, x in workspace:GetDescendants() do
		if x:IsA("SpawnLocation") and not (zonas and x:IsDescendantOf(zonas)) then
			return x
		end
	end
	return nil
end

local yendo = false
local function conectarLobby(p: Instance)
	if not p:IsA("BasePart") then
		return
	end
	p.Touched:Connect(function(otro)
		local ch = jugador.Character
		if yendo or enJuego or not (ch and otro:IsDescendantOf(ch)) then
			return
		end
		local destino = destinoLobby()
		if not destino then
			Interfaz.mensaje(
				"No encuentro el lobby: falta un SpawnLocation o una parte con el tag LobbyDestino.",
				nil,
				4
			)
			return
		end
		yendo = true
		Interfaz.telon("Al lobby", function()
			llevar(destino :: BasePart)
		end)
		yendo = false
	end)
end
for _, p in CollectionService:GetTagged("Lobby") do
	conectarLobby(p)
end
CollectionService:GetInstanceAddedSignal("Lobby"):Connect(conectarLobby)
