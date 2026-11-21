--!strict
-- Arma la plaza de inicio: punto de aparición y un portal por minijuego, en semicírculo.
-- Cada portal tiene una alfombra con la etiqueta «Portal» y el atributo «Modulo»: el cliente
-- (src/client/init.client.luau) arranca el juego cuando el personaje la pisa.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Estilo = require(ReplicatedStorage.Shared.Estilo)
local Modulos = require(ReplicatedStorage.Shared.Modulos)

local Plaza = {}

local RADIO = 46

local function parte(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function cartel(padre: BasePart, titulo: string, sub: string, color: Color3)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(260, 110)
	b.StudsOffset = Vector3.new(0, 4, 0)
	b.AlwaysOnTop = false
	b.MaxDistance = 140
	b.Adornee = padre
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 0.62)
	t.BackgroundTransparency = 1
	t.Text = titulo
	t.TextScaled = true
	t.Font = Estilo.letra
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.TextStrokeColor3 = color:Lerp(Color3.new(0, 0, 0), 0.5)
	t.Parent = b
	local s = t:Clone()
	s.Size = UDim2.fromScale(1, 0.36)
	s.Position = UDim2.fromScale(0, 0.64)
	s.Text = sub
	s.Font = Estilo.letraTexto
	s.Parent = b
	b.Parent = padre
end

local function portal(carpeta: Folder, id: string, angulo: number)
	local estilo = Estilo.portal[id]
	local modulo = Modulos[id]
	local centro = Vector3.new(math.sin(angulo) * RADIO, 0, -math.cos(angulo) * RADIO)
	local mira = CFrame.lookAt(centro, Vector3.new(0, 0, 0))

	local m = Instance.new("Model")
	m.Name = "Portal_" .. id

	local alfombra = parte({
		Name = "Alfombra",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 14, 14),
		CFrame = CFrame.new(centro + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = estilo.color,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	alfombra:SetAttribute("Modulo", id)
	CollectionService:AddTag(alfombra, "Portal")
	alfombra.Parent = m

	-- Arco de madera con los colores de la carreta.
	for _, lado in { -1, 1 } do
		parte({
			Name = "Pilar",
			Size = Vector3.new(2, 16, 2),
			CFrame = mira * CFrame.new(lado * 8, 8, 4),
			Color = Estilo.color.madera,
			Material = Enum.Material.Wood,
		}).Parent = m
	end
	local dintel = parte({
		Name = "Dintel",
		Size = Vector3.new(19, 3, 2.4),
		CFrame = mira * CFrame.new(0, 17, 4),
		Color = estilo.color,
		Material = Enum.Material.SmoothPlastic,
	})
	dintel.Parent = m
	cartel(dintel, estilo.icono .. " " .. modulo.nombre, "Pisá la alfombra para jugar", estilo.color)

	local luz = Instance.new("PointLight")
	luz.Color = estilo.color
	luz.Range = 18
	luz.Brightness = 2
	luz.Parent = alfombra

	m.Parent = carpeta
end

function Plaza.construir()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Plaza"

	local base = workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base.Color = Estilo.color.grama
		base.Material = Enum.Material.Grass
	end

	-- Piso de la plaza: una rueda de carreta (anillos de colores) bajo los pies.
	local colores = { Estilo.color.memoria, Estilo.color.inductivo, Estilo.color.deductivo, Estilo.color.geometrico }
	for k = 4, 1, -1 do
		parte({
			Name = "Anillo" .. k,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4 + k * 0.01, 16 + k * 12, 16 + k * 12),
			CFrame = CFrame.new(0, 0.2 + k * 0.01, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = colores[k],
			Material = Enum.Material.SmoothPlastic,
		}).Parent = carpeta
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 18)
	spawn.Color = Estilo.color.oro
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Parent = carpeta

	local n = #Estilo.ordenPortales
	for k, id in Estilo.ordenPortales do
		local angulo = math.rad(-70 + (k - 1) * 140 / (n - 1))
		portal(carpeta, id, angulo)
	end

	carpeta.Parent = workspace
end

return Plaza
