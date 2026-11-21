-- Arma un portal por juego (arco de madera + alfombra + letrero) en entregas/Portal_<Nombre>.rbxm.
-- Uso: lune run plantillas/portales.luau   (lo corre plantillas/armar.sh)
-- Se importa en la plaza y se mueve/rota a gusto. La alfombra tiene el tag «Portal» y el atributo «Modulo»:
-- al pisarla arranca el juego (src/client/init.client.luau).

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local MADERA = Color3.fromHex("7A4A2A")
local JUEGOS = {
	{ "Mandadero", "mandadero", "El Mandadero", "🛵", Color3.fromHex("D7263D") },
	{ "Balanza", "balanza", "La Balanza", "⚖️", Color3.fromHex("1B6CA8") },
	{ "Escondido", "escondido", "¿Qué se esconde?", "🧩", Color3.fromHex("2E9E4F") },
	{ "Colado", "colado", "El Colado", "💃", Color3.fromHex("F2B705") },
	{ "Lava", "lava", "¡El suelo es lava!", "🌋", Color3.fromRGB(255, 90, 20) },
	{ "Mensajero", "mensajero", "El Mensajero", "✉️", Color3.fromHex("C9A227") },
}

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

local function texto(t: string, tam: any, pos: any, letra: any, color: any, padre: Instance)
	local l = Instance.new("TextLabel")
	l.Size = tam
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = t
	l.TextScaled = true
	l.FontFace = roblox.Font.fromEnum(letra)
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.2
	l.TextStrokeColor3 = color:Lerp(Color3.new(0, 0, 0), 0.5)
	l.Parent = padre
end

for _, j in JUEGOS do
	local nombre, id, titulo, icono, color = j[1], j[2], j[3], j[4], j[5]
	local m = Instance.new("Model")
	m.Name = "Portal_" .. nombre

	local alfombra = parte({
		Name = "Alfombra",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 14, 14),
		CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, m)
	alfombra:SetAttribute("Modulo", id)
	alfombra:AddTag("Portal")
	local luz = Instance.new("PointLight")
	luz.Color = color
	luz.Range = 18
	luz.Brightness = 2
	luz.Parent = alfombra

	for _, lado in { -1, 1 } do
		parte({
			Name = "Pilar",
			Size = Vector3.new(2, 16, 2),
			CFrame = CFrame.new(lado * 8, 8, -4),
			Color = MADERA,
			Material = Enum.Material.Wood,
		}, m)
	end
	local dintel = parte({
		Name = "Dintel",
		Size = Vector3.new(19, 3, 2.4),
		CFrame = CFrame.new(0, 17, -4),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
	}, m)

	local b = Instance.new("BillboardGui")
	b.Size = roblox.UDim2.fromOffset(260, 110)
	b.StudsOffset = Vector3.new(0, 4, 0)
	b.MaxDistance = 140
	texto(
		icono .. " " .. titulo,
		roblox.UDim2.fromScale(1, 0.62),
		roblox.UDim2.fromScale(0, 0),
		Enum.Font.FredokaOne,
		color,
		b
	)
	texto(
		"Pisá la alfombra para jugar",
		roblox.UDim2.fromScale(1, 0.36),
		roblox.UDim2.fromScale(0, 0.64),
		Enum.Font.GothamMedium,
		color,
		b
	)
	b.Parent = dintel

	m.PrimaryPart = alfombra
	fs.writeFile("entregas/Portal_" .. nombre .. ".rbxm", roblox.serializeModel({ m }))
end
print("ok: " .. #JUEGOS .. " portales")
