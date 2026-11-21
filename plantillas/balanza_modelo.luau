-- Arma el modelo de «La Balanza» (una pulpería con la balanza en el mostrador) y lo guarda en entregas/Balanza.rbxm.
-- Uso: lune run plantillas/balanza_modelo.luau   (lo corre plantillas/armar.sh)
--
-- El código del juego (src/client/Juegos/Balanza.luau) mueve la Viga, los Platos y las Cuerdas alrededor del
-- Pivote, pone los bloques encima de los platos y de la Bandeja, mira desde la parte Camara y deja al jugador en
-- la parte Jugador. Esas partes tienen que conservar el nombre; todo lo demás se puede decorar o cambiar.
-- La izquierda de la balanza es -X y la cámara mira hacia -Z.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local O = Vector3.new(0, 40, -800) -- lejos del lobby y de las demás zonas

local MADERA = Color3.fromRGB(122, 74, 42)
local MADERA_CLARA = Color3.fromRGB(176, 120, 72)
local AZUL = Color3.fromRGB(27, 108, 168)
local ORO = Color3.fromRGB(201, 162, 39)
local ROJO = Color3.fromRGB(215, 38, 61)
local CREMA = Color3.fromRGB(240, 228, 200)
local HIERRO = Color3.fromRGB(38, 44, 62) -- la balanza: oscura para que contraste con la pared amarilla

local modelo = Instance.new("Model")
modelo.Name = "Balanza"

local function parte(props: { [string]: any }, padre: Instance?): any
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = padre or modelo
	return p
end
local function en(x: number, y: number, z: number): any
	return CFrame.new(O + Vector3.new(x, y, z))
end
local VERTICAL = CFrame.Angles(0, 0, math.rad(90)) -- cilindros con el eje hacia arriba

local function letrero(p: any, texto: string, cara: any, color: any)
	local s = Instance.new("SurfaceGui")
	s.Face = cara
	s.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	s.PixelsPerStud = 25
	local t = Instance.new("TextLabel")
	t.Size = roblox.UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = texto
	t.TextScaled = true
	t.FontFace = roblox.Font.fromEnum(Enum.Font.FredokaOne)
	t.TextColor3 = color
	t.Parent = s
	s.Parent = p
end

-- Partes que usa el código ---------------------------------------------------------------------------
parte({
	Name = "Origen",
	Size = Vector3.new(2, 2, 2),
	CFrame = en(0, 0, 0),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
})

-- Terreno grande alrededor: Play Here suelta al jugador donde está la cámara y tiene que caer en algo.
parte({
	Name = "Terreno",
	Size = Vector3.new(260, 4, 260),
	CFrame = en(0, -2.6, 10),
	Color = Color3.fromRGB(106, 168, 79),
	Material = Enum.Material.Grass,
})
-- Piso de la pulpería.
parte({
	Name = "Piso",
	Size = Vector3.new(70, 2, 70),
	CFrame = en(0, -1, 5),
	Color = Color3.fromRGB(200, 170, 130),
	Material = Enum.Material.WoodPlanks,
})

-- Mostrador (la balanza va encima) y su frente pintado.
local mostrador = parte({
	Name = "Mostrador",
	Size = Vector3.new(36, 5, 9),
	CFrame = en(0, 2.5, 0),
	Color = MADERA,
	Material = Enum.Material.Wood,
})
letrero(mostrador, "⚖️", Enum.NormalId.Back, CREMA)

-- La balanza: pedestal, poste, pivote, viga, cuerdas y platos.
parte({
	Name = "Pedestal",
	Size = Vector3.new(7, 1, 5),
	CFrame = en(0, 5.5, 0),
	Color = HIERRO,
	Material = Enum.Material.Metal,
})
parte({
	Name = "Poste",
	Size = Vector3.new(1.4, 12, 1.4),
	CFrame = en(0, 12, 0),
	Color = HIERRO,
	Material = Enum.Material.Metal,
})
parte({
	Name = "Pivote",
	Size = Vector3.new(1, 1, 1),
	CFrame = en(0, 18, 0),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
})
parte({
	Name = "Corona",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(2.4, 2.4, 2.4),
	CFrame = en(0, 18.6, 0),
	Color = HIERRO,
	Material = Enum.Material.Metal,
})
parte({
	Name = "Viga",
	Size = Vector3.new(27, 0.9, 0.9),
	CFrame = en(0, 18, 0),
	Color = HIERRO,
	Material = Enum.Material.Metal,
})
for _, lado in { { "Izq", -1 }, { "Der", 1 } } do
	local x = 12.5 * lado[2]
	parte({
		Name = "Cuerda" .. lado[1],
		Size = Vector3.new(0.25, 6.5, 0.25),
		CFrame = en(x, 14.75, 0),
		Color = Color3.fromRGB(20, 20, 24),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	})
	local plato = parte({
		Name = "Plato" .. lado[1],
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 9.5, 9.5),
		CFrame = en(x, 11.2, 0) * VERTICAL,
		Color = if lado[2] < 0 then AZUL else ROJO,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	plato:SetAttribute("Lado", string.lower(lado[1]))
end

-- Bandeja: mesa baja delante del mostrador, con los bloques sueltos.
parte({
	Name = "MesaBandeja",
	Size = Vector3.new(30, 6, 5),
	CFrame = en(0, 3, 8.5),
	Color = MADERA_CLARA,
	Material = Enum.Material.Wood,
})
local bandeja = parte({
	Name = "Bandeja",
	Size = Vector3.new(30, 0.4, 5),
	CFrame = en(0, 6.2, 8.5),
	Color = CREMA,
	Material = Enum.Material.Fabric,
})
bandeja:SetAttribute("Lado", "bandeja")

-- Dónde se para el jugador y desde dónde mira la cámara.
parte({
	Name = "Jugador",
	Size = Vector3.new(4, 1, 4),
	CFrame = CFrame.lookAt(O + Vector3.new(0, 0.5, 20), O + Vector3.new(0, 0.5, 0)),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
})
parte({
	Name = "Camara",
	Size = Vector3.new(1, 1, 1),
	CFrame = CFrame.lookAt(O + Vector3.new(0, 17, 34), O + Vector3.new(0, 10, 2)),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
})

-- Decoración: la pulpería ---------------------------------------------------------------------------
local deco = Instance.new("Model")
deco.Name = "Pulperia"
deco.Parent = modelo
parte({
	Name = "Pared",
	Size = Vector3.new(60, 28, 2),
	CFrame = en(0, 14, -14),
	Color = Color3.fromRGB(242, 183, 5),
	Material = Enum.Material.Concrete,
}, deco)
parte({
	Name = "Zocalo",
	Size = Vector3.new(60, 6, 2.2),
	CFrame = en(0, 3, -13.9),
	Color = Color3.fromRGB(46, 158, 79),
	Material = Enum.Material.Concrete,
}, deco)
for _, x in { -29, 29 } do
	parte({
		Name = "ParedLado",
		Size = Vector3.new(2, 28, 30),
		CFrame = en(x, 14, 0),
		Color = Color3.fromRGB(242, 183, 5),
		Material = Enum.Material.Concrete,
	}, deco)
end
parte({
	Name = "Techo",
	Size = Vector3.new(64, 1.5, 40),
	CFrame = en(0, 29, 2) * CFrame.Angles(math.rad(-8), 0, 0),
	Color = Color3.fromRGB(170, 60, 40),
	Material = Enum.Material.CorrodedMetal,
}, deco)
local rotulo = parte({
	Name = "Rotulo",
	Size = Vector3.new(30, 5, 0.6),
	CFrame = en(0, 24, -12.6),
	Color = AZUL,
	Material = Enum.Material.SmoothPlastic,
}, deco)
letrero(rotulo, "Pulpería La Balanza", Enum.NormalId.Back, Color3.new(1, 1, 1))
-- Estantes con mercadería (cajitas de colores).
local colores = { ROJO, AZUL, ORO, Color3.fromRGB(46, 158, 79), CREMA }
for fila = 0, 2 do
	local y = 9 + fila * 5
	parte({
		Name = "Estante",
		Size = Vector3.new(44, 0.6, 3),
		CFrame = en(0, y, -11.6),
		Color = MADERA,
		Material = Enum.Material.Wood,
	}, deco)
	for k = 0, 9 do
		local h = 1.6 + ((k + fila) % 3) * 0.6
		parte({
			Name = "Producto",
			Size = Vector3.new(2.4, h, 1.8),
			CFrame = en(-19.5 + k * 4.3, y + 0.3 + h / 2, -11.6),
			Color = colores[(k + fila * 2) % #colores + 1],
			Material = Enum.Material.SmoothPlastic,
		}, deco)
	end
end
-- Sacos de granos a los lados del mostrador.
for _, x in { -22, 22 } do
	parte({
		Name = "Saco",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6),
		CFrame = en(x, 3, 2),
		Color = Color3.fromRGB(196, 170, 120),
		Material = Enum.Material.Fabric,
	}, deco)
end
local luz = Instance.new("PointLight")
luz.Range = 40
luz.Brightness = 1.5
luz.Color = Color3.fromRGB(255, 240, 210)
luz.Parent = parte({
	Name = "Bombillo",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(1.4, 1.4, 1.4),
	CFrame = en(0, 26, 4),
	Color = Color3.fromRGB(255, 250, 220),
	Material = Enum.Material.Neon,
	CanCollide = false,
}, deco)

-- Mirador para probar: alfombra «Probar» (Play Here aquí) -------------------------------------------
local probar = parte({
	Name = "Probar",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, 10, 10),
	CFrame = en(22, 0.5, 30) * VERTICAL,
	Color = AZUL,
	Material = Enum.Material.Neon,
	CanCollide = false,
})
probar:SetAttribute("Modulo", "balanza")
probar:AddTag("Portal")
local cartel = Instance.new("BillboardGui")
cartel.Size = roblox.UDim2.fromOffset(260, 80)
cartel.StudsOffset = Vector3.new(0, 7, 0)
cartel.MaxDistance = 160
local texto = Instance.new("TextLabel")
texto.Size = roblox.UDim2.fromScale(1, 1)
texto.BackgroundTransparency = 1
texto.Text = "⚖️ La Balanza"
texto.TextScaled = true
texto.FontFace = roblox.Font.fromEnum(Enum.Font.FredokaOne)
texto.TextColor3 = Color3.new(1, 1, 1)
texto.TextStrokeTransparency = 0.2
texto.Parent = cartel
cartel.Parent = probar

-- Portal de vuelta al lobby (tag «Lobby»).
local alLobby = parte({
	Name = "AlLobby",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, 10, 10),
	CFrame = CFrame.new(O + Vector3.new(-22, 0.5, 30)) * CFrame.Angles(0, 0, math.rad(90)),
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
	Ambiente = "rbxassetid://1845909886",
	Poner = "rbxassetid://9120917813",
	Inclina = "rbxassetid://9120839010",
	Pareja = "rbxassetid://9116395085",
	Bien = "rbxassetid://9126073318",
	Mal = "rbxassetid://9112752910",
	Estrella = "rbxassetid://9126073001",
}
-- Sonidos: el juego toca el que tenga SoundId (elegilos en el Toolbox, pestaña Audio).
local sonidos = Instance.new("Folder")
sonidos.Name = "Sonidos"
sonidos.Parent = modelo
for _, s in
	{
		{ "Ambiente", "música o ruido de pulpería, en bucle, bajito" },
		{ "Poner", "toc de un bloque sobre el plato" },
		{ "Inclina", "crujido de la balanza al moverse" },
		{ "Pareja", "el guiño: «¡Six-Seven!» o un ¡tadá! cuando quedan parejas" },
		{ "Bien", "acierto corto" },
		{ "Mal", "boing chistoso (nunca un buzzer de error)" },
		{ "Estrella", "ding de cada estrella" },
	}
do
	local snd = Instance.new("Sound")
	snd.Name = s[1]
	snd.SoundId = IDS[s[1]] or ""
	snd.Volume = if s[1] == "Ambiente" then 0.2 else 0.6
	snd.Looped = s[1] == "Ambiente"
	snd:SetAttribute("Que", s[2])
	snd.Parent = sonidos
end

modelo.PrimaryPart = modelo:FindFirstChild("Origen")
-- Siempre cargado en todos los jugadores (con StreamingEnabled, si no, desde el lobby no se encuentra).
modelo.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
fs.writeFile("entregas/Balanza.rbxm", roblox.serializeModel({ modelo }))
print("ok: entregas/Balanza.rbxm")
