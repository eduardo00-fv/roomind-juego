-- Arma el modelo del volcán de «¡El suelo es lava!» y lo guarda en entregas/Lava.rbxm.
-- Uso: lune run plantillas/lava_modelo.luau   (lo corre plantillas/armar.sh)
--
-- El modelo es el escenario fijo (se ve en el editor y se puede mover, no rotar). El código del juego
-- (src/client/Juegos/Lava.luau) arma las baldosas encima de la parte «Origen» del modelo.
-- Coordenadas relativas a Origen: el piso de baldosas crece hacia -Z desde Origen (hasta 50 de largo en 5×5),
-- la salida queda en +Z y la meta en -Z.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local O = Vector3.new(600, 40, 0) -- dónde queda Origen al insertarlo (lejos del lobby)
local C = O + Vector3.new(0, 0, -25) -- centro del cráter = centro del piso más grande

local LAVA = Color3.fromRGB(255, 90, 20)
local ROCAS = { Color3.fromRGB(58, 48, 44), Color3.fromRGB(74, 60, 52), Color3.fromRGB(50, 42, 40) }

local modelo = Instance.new("Model")
modelo.Name = "Lava"

local function parte(props: { [string]: any }, padre: Instance): any
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = padre
	return p
end

-- Origen: el código del juego lee su posición.
parte({
	Name = "Origen",
	Size = Vector3.new(2, 2, 2),
	CFrame = CFrame.new(O),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
}, modelo)

-- Isla de basalto que sostiene todo.
parte({
	Name = "Isla",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(4, 340, 340),
	CFrame = CFrame.new(C + Vector3.new(0, -42, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = ROCAS[1],
	Material = Enum.Material.Basalt,
}, modelo)

-- Cráter: anillos de rocas, más bajos hacia afuera (la ladera del volcán).
local crater = Instance.new("Model")
crater.Name = "Crater"
crater.Parent = modelo
local ANCHO = 14
for k = 0, 6 do
	local r = 72 + k * 9
	local arriba = 16 - k * 7
	local abajo = -41
	local h = arriba - abajo
	local n = math.ceil(2 * math.pi * r / ANCHO)
	for j = 0, n - 1 do
		local t = 2 * math.pi * j / n
		local alto = h + ((j * 7 + k * 3) % 5) - 2 -- un poco disparejo, como roca
		parte({
			Name = "Roca",
			Size = Vector3.new(2 * math.pi * r / n + 1.5, alto, 11),
			CFrame = CFrame.new(C + Vector3.new(math.sin(t) * r, abajo + alto / 2, math.cos(t) * r))
				* CFrame.Angles(0, t, 0),
			Color = ROCAS[(j + k) % 3 + 1],
			Material = if k == 0 then Enum.Material.Basalt else Enum.Material.Rock,
		}, crater)
	end
end

-- Lago de lava dentro del cráter, con luz, fuego y humo.
local lago = parte({
	Name = "LagoDeLava",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, 146, 146),
	CFrame = CFrame.new(C + Vector3.new(0, -16, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = LAVA,
	Material = Enum.Material.Neon,
	CanCollide = false,
	CanQuery = false,
}, modelo)
local luz = Instance.new("PointLight")
luz.Color = LAVA
luz.Range = 60
luz.Brightness = 3
luz.Parent = lago

local burbujas = { { -45, -30 }, { 40, -50 }, { -38, 30 }, { 48, 22 }, { 0, -62 }, { -55, -2 } }
for k, xz in burbujas do
	local b = parte({
		Name = "Burbuja" .. k,
		Size = Vector3.new(4, 1, 4),
		CFrame = CFrame.new(C + Vector3.new(xz[1], -15.5, xz[2])),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
	}, modelo)
	local fuego = Instance.new("Fire")
	fuego.Size = 9
	fuego.Heat = 12
	fuego.Color = LAVA
	fuego.SecondaryColor = Color3.fromRGB(255, 200, 60)
	fuego.Parent = b
end
for k, t in { 0.6, 2.4, 4.2 } do
	local h = parte({
		Name = "Humo" .. k,
		Size = Vector3.new(4, 1, 4),
		CFrame = CFrame.new(C + Vector3.new(math.sin(t) * 76, 18, math.cos(t) * 76)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
	}, modelo)
	local humo = Instance.new("Smoke")
	humo.Size = 14
	humo.RiseVelocity = 6
	humo.Opacity = 0.25
	humo.Color = Color3.fromRGB(120, 110, 105)
	humo.Parent = h
end

-- Bandera de la meta al fondo del cráter.
local asta = parte({
	Name = "Asta",
	Size = Vector3.new(1.2, 30, 1.2),
	CFrame = CFrame.new(C + Vector3.new(0, 6, -74)),
	Color = Color3.fromRGB(230, 230, 230),
	Material = Enum.Material.Metal,
}, modelo)
asta.Name = "Asta"
parte({
	Name = "Bandera",
	Size = Vector3.new(10, 6, 0.4),
	CFrame = CFrame.new(C + Vector3.new(5.6, 18, -74)),
	Color = Color3.fromRGB(201, 162, 39),
	Material = Enum.Material.Fabric,
}, modelo)

-- Mirador afuera del cráter: letrero y alfombra «Probar» (Play Here aquí para probar el juego solo).
local mirador = parte({
	Name = "Mirador",
	Size = Vector3.new(44, 2, 30),
	CFrame = CFrame.new(C + Vector3.new(0, -39, 150)),
	Color = Color3.fromRGB(122, 74, 42),
	Material = Enum.Material.WoodPlanks,
}, modelo)
local probar = parte({
	Name = "Probar",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, 12, 12),
	CFrame = CFrame.new(C + Vector3.new(0, -37.4, 146)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = LAVA,
	Material = Enum.Material.Neon,
	CanCollide = false,
}, modelo)
probar:SetAttribute("Modulo", "lava")
probar:AddTag("Portal")

local cartel = Instance.new("BillboardGui")
cartel.Name = "Cartel"
cartel.Size = roblox.UDim2.fromOffset(300, 90)
cartel.StudsOffset = Vector3.new(0, 12, 0)
cartel.MaxDistance = 220
local texto = Instance.new("TextLabel")
texto.Size = roblox.UDim2.fromScale(1, 1)
texto.BackgroundTransparency = 1
texto.Text = "🌋 ¡El suelo es lava!"
texto.TextScaled = true
texto.FontFace = roblox.Font.fromEnum(Enum.Font.FredokaOne)
texto.TextColor3 = Color3.new(1, 1, 1)
texto.TextStrokeTransparency = 0.2
texto.TextStrokeColor3 = Color3.fromRGB(120, 40, 10)
texto.Parent = cartel
cartel.Parent = mirador

-- Portal de vuelta al lobby (tag «Lobby»).
local alLobby = parte({
	Name = "AlLobby",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, 10, 10),
	CFrame = CFrame.new(C + Vector3.new(14, -37.4, 156)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(46, 158, 79),
	Material = Enum.Material.Neon,
	CanCollide = false,
}, modelo)
alLobby:AddTag("Lobby")
local cartelLobby = Instance.new("BillboardGui")
cartelLobby.Size = roblox.UDim2.fromOffset(220, 70)
cartelLobby.StudsOffset = Vector3.new(0, 6, 0)
cartelLobby.MaxDistance = 120
local textoLobby = Instance.new("TextLabel")
textoLobby.Size = roblox.UDim2.fromScale(1, 1)
textoLobby.BackgroundTransparency = 1
textoLobby.Text = "🏠 Al lobby"
textoLobby.TextScaled = true
textoLobby.FontFace = roblox.Font.fromEnum(Enum.Font.FredokaOne)
textoLobby.TextColor3 = Color3.new(1, 1, 1)
textoLobby.TextStrokeTransparency = 0.2
textoLobby.Parent = cartelLobby
cartelLobby.Parent = alLobby

local IDS = {
	Ambiente = "rbxassetid://9125615158",
	Tanteo = "rbxassetid://9119604982",
	Piso = "rbxassetid://9126076030",
	Lava = "rbxassetid://9119165650",
	Quemada = "rbxassetid://9114446277",
	Ganar = "rbxassetid://1836473422",
	Estrella = "rbxassetid://9126073001",
}
-- Sonidos: el juego toca el que tenga SoundId. Elegilos en el Toolbox (Audio) y pegá el id en SoundId.
local sonidos = Instance.new("Folder")
sonidos.Name = "Sonidos"
sonidos.Parent = modelo
for _, s in
	{
		{ "Ambiente", "burbujeo de lava, en bucle, bajito" },
		{ "Tanteo", "toc del palo en la piedra" },
		{ "Piso", "acierto corto: la baldosa es piso" },
		{ "Lava", "chisporroteo: encontró una lava con el palo" },
		{ "Quemada", "¡fsss! se quemó" },
		{ "Ganar", "fanfarria corta al llegar a la meta" },
		{ "Estrella", "ding de cada estrella" },
	}
do
	local snd = Instance.new("Sound")
	snd.Name = s[1]
	snd.SoundId = IDS[s[1]] or ""
	snd.Volume = if s[1] == "Ambiente" then 0.25 else 0.6
	snd.Looped = s[1] == "Ambiente"
	snd:SetAttribute("Que", s[2])
	snd.Parent = sonidos
end

modelo.PrimaryPart = modelo:FindFirstChild("Origen")
-- Siempre cargado en todos los jugadores (con StreamingEnabled, si no, desde el lobby no se encuentra).
modelo.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

fs.writeFile("entregas/Lava.rbxm", roblox.serializeModel({ modelo }))
print("ok: entregas/Lava.rbxm (" .. #crater:GetChildren() .. " rocas)")
