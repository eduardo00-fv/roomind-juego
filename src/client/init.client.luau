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

-- Sin chat: es un juego para niños de 8 a 10 años y no hace falta hablar con desconocidos para jugar.
-- Se apagan la ventana, la barra para escribir y las burbujas. Para cortarlo también del lado del servidor,
-- en Studio: TextChatService > CreateDefaultTextChannels = false.
do
	local StarterGui = game:GetService("StarterGui")
	local TextChatService = game:GetService("TextChatService")
	pcall(function()
		TextChatService.ChatWindowConfiguration.Enabled = false
		TextChatService.ChatInputBarConfiguration.Enabled = false
		TextChatService.BubbleChatConfiguration.Enabled = false
	end)
	task.spawn(function()
		-- SetCoreGuiEnabled puede fallar si el CoreGui todavía no cargó: se reintenta unos segundos.
		for _ = 1, 10 do
			if pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			end) then
				break
			end
			task.wait(0.5)
		end
	end)
end

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
		-- Con StreamingEnabled: que cargue el piso del destino antes de llegar (si no, se cae).
		pcall(function()
			jugador:RequestStreamAroundAsync(cf.Position, 5)
		end)
		ch:PivotTo(cf + Vector3.new(0, 4, 0))
	end
end

-- Portales en pausa: después de volver de un juego, ese portal no arranca otra vez hasta que el jugador
-- se aleje (si no, cae encima y vuelve a entrar).
local enPausa: { [BasePart]: boolean } = {}
local function pausar(alfombra: BasePart)
	enPausa[alfombra] = true
	task.spawn(function()
		local radio = math.max(alfombra.Size.X, alfombra.Size.Y, alfombra.Size.Z) / 2 + 3
		local limite = os.clock() + 60
		while os.clock() < limite do
			task.wait(0.3)
			local ch = jugador.Character
			local raiz = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart?
			if raiz and (raiz.Position - alfombra.Position).Magnitude > radio then
				break
			end
		end
		enPausa[alfombra] = nil
	end)
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

-- El lobby: la parte con el tag «LobbyDestino» o, si no hay, el SpawnLocation del lobby
-- (el primero que no esté dentro de Zonas).
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

local function entrar(id: string, alfombra: BasePart)
	if enJuego or enPausa[alfombra] then
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
	local okNivel, guardado = pcall(function()
		return (ReplicatedStorage:WaitForChild("NivelGuardado") :: RemoteFunction):InvokeServer(id)
	end)
	local ctx = {
		id = id,
		-- Nivel en el que quedó la vez pasada (1 si es la primera vez).
		nivelInicial = if okNivel and type(guardado) == "number" then guardado else 1,
		-- El juego avisa su nivel cada vez que cambia (y al empezar): se guarda y va en el reporte al papá.
		nivel = function(n: number, niveles: number)
			partida:FireServer("nivel", { nivel = n, niveles = niveles })
		end,
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
	-- Si entró por un portal del lobby, vuelve a su lado. Si entró desde adentro del juego (la alfombra
	-- «Probar» de su modelo o zona), va al lobby.
	local adentro = false
	local x: Instance? = alfombra.Parent
	while x and x ~= workspace do
		if string.lower(x.Name) == id or x.Name == "Zonas" then
			adentro = true
			break
		end
		x = x.Parent
	end
	local lobby = if adentro then destinoLobby() else nil
	Interfaz.telon(if lobby then "De vuelta a la plaza" else "¡De vuelta!", function()
		if lobby then
			llevar(lobby)
		else
			-- Al lado del portal, fuera de su borde (los portales del equipo pueden ser grandes).
			local radio = math.max(alfombra.Size.X, alfombra.Size.Y, alfombra.Size.Z) / 2
			llevar(CFrame.new(alfombra.Position + Vector3.new(0, 0, radio + 6)))
		end
	end)
	pausar(alfombra)
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

-- Portales de vuelta al lobby: partes con el tag «Lobby» (destino: ver destinoLobby).
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
