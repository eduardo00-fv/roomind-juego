--!strict
-- «¡El suelo es lava!» en 3D (instrucciones.md §5). La regla vive en Shared.Logica.Lava (probada con Lune);
-- aquí solo se dibuja el piso, se leen los toques y se camina.
--
-- Cómo se juega en Roblox:
--   * Tocar (o hacer clic en) una baldosa = tantearla con el palo. Cada tanteo cuenta.
--   * Caminar con el joystick o las teclas. No se puede saltar (no vale brincarse la lava).
--   * Las baldosas vecinas a donde estás brillan. Llegar a la fila de arriba es ganar.
-- El piso es solo de este jugador (se crea en el cliente).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Estilo = require(ReplicatedStorage.Shared.Estilo)
local Escalera = require(ReplicatedStorage.Shared.Logica.Escalera)
local L = require(ReplicatedStorage.Shared.Logica.Lava)
local Interfaz = require(script.Parent.Parent.Interfaz)

type Estado = L.Estado

export type Contexto = {
	reto: (datos: { [string]: any }) -> (),
	zona: Instance?,
	nivelInicial: number?,
	nivel: ((n: number, niveles: number) -> ())?,
}

local Juego = {}

-- El escenario es el modelo «Lava» del mundo (Workspace.Zonas.Lava o Workspace.Lava, ver plantillas/lava_modelo.luau):
-- las baldosas se arman encima de su parte «Origen» y crecen hacia -Z. Sin modelo, se usa este punto y un mar simple.
local ORIGEN = Vector3.new(600, 40, 0)
local escenario: Instance? = nil
local T = 10 -- lado de una baldosa
local COLOR = Estilo.color.lava

local azar = Random.new()
local function rnd(a: number, b: number): number
	return azar:NextInteger(a, b)
end

-- Sonidos: los del modelo (carpeta Sonidos) y, si están vacíos, estos de respaldo (bibliotecas con licencia de
-- Roblox: ProSoundEffects y APMOfficial, se pueden usar en cualquier juego).
local RESPALDO: { [string]: string } = {
	Ambiente = "rbxassetid://9125615158",
	Tanteo = "rbxassetid://9119604982",
	Piso = "rbxassetid://9126076030",
	Lava = "rbxassetid://9119165650",
	Quemada = "rbxassetid://9114446277",
	Ganar = "rbxassetid://1836473422",
	Estrella = "rbxassetid://9126073001",
}
local sonidos: Instance? = nil
local cache: { [string]: Sound } = {}
local function sonido(nombre: string): Sound?
	local s = sonidos and sonidos:FindFirstChild(nombre)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		return s
	end
	local id = RESPALDO[nombre]
	if not id then
		return nil
	end
	if not cache[nombre] then
		local n = Instance.new("Sound")
		n.Name = "Lava_" .. nombre
		n.SoundId = id
		n.Volume = if nombre == "Ambiente" then 0.2 else 0.6
		n.Parent = SoundService
		cache[nombre] = n
	end
	return cache[nombre]
end
local function sonar(nombre: string)
	local s = sonido(nombre)
	if s then
		SoundService:PlayLocalSound(s)
	end
end

local function parte(props: { [string]: any }, padre: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = padre
	return p
end

-- Texto pintado sobre la cara de arriba de una baldosa («✓», «2», «META»). "" lo quita.
local function rotulo(p: BasePart, texto: string, color: Color3?)
	local s = p:FindFirstChild("Rotulo") :: SurfaceGui?
	if texto == "" then
		if s then
			s:Destroy()
		end
		return
	end
	if not s then
		local nuevo = Instance.new("SurfaceGui")
		nuevo.Name = "Rotulo"
		nuevo.Face = Enum.NormalId.Top
		nuevo.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		nuevo.PixelsPerStud = 30
		local t = Instance.new("TextLabel")
		t.Name = "T"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Estilo.letra
		t.Parent = nuevo
		nuevo.Parent = p
		s = nuevo
	end
	local t = (s :: SurfaceGui):FindFirstChild("T") :: TextLabel
	t.Text = texto
	t.TextColor3 = color or Estilo.color.texto
end

type Tablero = {
	modelo: Model,
	baldosas: { [number]: Part },
	inicio: CFrame,
	n: number,
}

local function centro(n: number, fila: number, col: number): Vector3
	return Vector3.new(ORIGEN.X + (col - (n + 1) / 2) * T, ORIGEN.Y - 1, ORIGEN.Z - (fila - 0.5) * T)
end

local function celdaDe(n: number, pos: Vector3): (number, number)
	local col = math.floor((pos.X - ORIGEN.X) / T + n / 2) + 1
	local fila = math.floor((ORIGEN.Z - pos.Z) / T) + 1
	return fila, col
end

local function construir(n: number, padre: Instance): Tablero
	local m = Instance.new("Model")
	m.Name = "Piso" .. n
	local ancho, largo = n * T, n * T
	local cz = ORIGEN.Z - largo / 2

	local baldosas = {}
	for f = 1, n do
		for c = 1, n do
			local b = parte({
				Name = ("B%d_%d"):format(f, c),
				Size = Vector3.new(T - 0.5, 2, T - 0.5),
				Position = centro(n, f, c),
				Color = Estilo.color.piedra,
				Material = Enum.Material.Slate,
			}, m)
			b:SetAttribute("i", L.indice(n, f, c))
			baldosas[L.indice(n, f, c)] = b
		end
	end
	-- Fondo oscuro entre las juntas y el mar de lava abajo.
	parte({
		Name = "Junta",
		Size = Vector3.new(ancho, 1, largo),
		Position = Vector3.new(ORIGEN.X, ORIGEN.Y - 2.6, cz),
		Color = Color3.fromRGB(45, 35, 30),
	}, m)
	if not escenario then
		parte({
			Name = "MarDeLava",
			Size = Vector3.new(ancho + 160, 1, largo + 200),
			Position = Vector3.new(ORIGEN.X, ORIGEN.Y - 16, cz),
			Color = COLOR,
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, m)
	end
	-- Orilla de salida (abajo) y meta (arriba).
	local salida = parte({
		Name = "Salida",
		Size = Vector3.new(ancho, 2, 2 * T),
		Position = Vector3.new(ORIGEN.X, ORIGEN.Y - 1, ORIGEN.Z + T),
		Color = Estilo.color.madera,
		Material = Enum.Material.WoodPlanks,
	}, m)
	rotulo(salida, "SALIDA", Color3.new(1, 1, 1))
	local meta = parte({
		Name = "Meta",
		Size = Vector3.new(ancho, 2, 2 * T),
		Position = Vector3.new(ORIGEN.X, ORIGEN.Y - 1, ORIGEN.Z - largo - T),
		Color = Estilo.color.oro,
		Material = Enum.Material.SmoothPlastic,
	}, m)
	rotulo(meta, "META", Color3.new(1, 1, 1))
	-- Paredes invisibles a los lados y atrás: nadie se cae por la orilla.
	local total = largo + 4 * T
	for _, lado in { -1, 1 } do
		parte({
			Name = "Pared",
			Size = Vector3.new(1, 14, total),
			Position = Vector3.new(ORIGEN.X + lado * (ancho / 2 + 0.5), ORIGEN.Y + 6, cz),
			Transparency = 1,
		}, m)
	end
	for _, z in { ORIGEN.Z + 2 * T + 0.5, ORIGEN.Z - largo - 2 * T - 0.5 } do
		parte({
			Name = "Pared",
			Size = Vector3.new(ancho, 14, 1),
			Position = Vector3.new(ORIGEN.X, ORIGEN.Y + 6, z),
			Transparency = 1,
		}, m)
	end
	m.Parent = padre
	local pie = Vector3.new(ORIGEN.X, ORIGEN.Y + 3, ORIGEN.Z + T)
	return { modelo = m, baldosas = baldosas, inicio = CFrame.lookAt(pie, pie - Vector3.zAxis), n = n }
end

-- Pinta cada baldosa según lo que se sabe. `brillan` = las que se pueden pisar ahora.
local function pintar(tab: Tablero, e: Estado)
	local n = tab.n
	local seguras = if e.ayudaChecks then (L.deducir(e)) else {}
	local enCamino: { [number]: boolean } = {}
	for _, i in e.camino do
		enCamino[i] = true
	end
	local brillan: { [number]: boolean } = {}
	if e.posicion then
		local f, c = L.celda(n, e.posicion)
		for _, v in L.vecinas(n, f, c) do
			brillan[L.indice(n, v[1], v[2])] = true
		end
	else
		for c = 1, n do
			brillan[L.indice(n, 1, c)] = true
		end
	end

	for i, b in tab.baldosas do
		local f, c = L.celda(n, i)
		if e.lavasConocidas[i] then
			b.Color = COLOR
			b.Material = Enum.Material.Neon
			if not b:FindFirstChild("Fuego") then
				local fuego = Instance.new("Fire")
				fuego.Name = "Fuego"
				fuego.Size = 6
				fuego.Heat = 8
				fuego.Parent = b
			end
			rotulo(b, "")
		else
			local fuego = b:FindFirstChild("Fuego")
			if fuego then
				fuego:Destroy() -- el piso se reusa cuando se cambia por uno nuevo
			end
		end
		if e.lavasConocidas[i] then
			-- ya se pintó arriba
			b.Material = Enum.Material.Neon
		elseif e.segurasConocidas[i] then
			b.Color = if enCamino[i] then Estilo.color.inductivo else Estilo.color.pisoSeguro
			b.Material = Enum.Material.SmoothPlastic
			rotulo(b, if e.piso.conNumeros then tostring(L.lavasAlLado(e.piso, f, c)) else "")
		else
			b.Color = Estilo.color.piedra
			b.Material = Enum.Material.Slate
			rotulo(b, if seguras[i] then "✓" else "", Estilo.color.geometrico)
		end

		local caja = b:FindFirstChild("Brillo") :: SelectionBox?
		local debe = brillan[i] and not e.lavasConocidas[i] and not e.ganado
		if debe and not caja then
			local s = Instance.new("SelectionBox")
			s.Name = "Brillo"
			s.Adornee = b
			s.LineThickness = 0.18
			s.Color3 = Color3.fromRGB(255, 255, 200)
			s.SurfaceTransparency = 1
			s.Parent = b
		elseif not debe and caja then
			caja:Destroy()
		end
	end
end

-- El palo: una vara que sale del personaje hasta la baldosa y se desvanece.
local function palo(desde: Vector3, hasta: Vector3, padre: Instance)
	local largo = (hasta - desde).Magnitude
	local p = parte({
		Name = "Palo",
		Size = Vector3.new(0.4, 0.4, largo),
		CFrame = CFrame.lookAt((desde + hasta) / 2, hasta),
		Color = Estilo.color.madera,
		Material = Enum.Material.Wood,
		CanCollide = false,
		CanQuery = false,
	}, padre)
	TweenService:Create(p, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	task.delay(0.55, function()
		p:Destroy()
	end)
end

local function personaje(): (Model?, Humanoid?, BasePart?)
	local ch = Players.LocalPlayer.Character
	if not ch then
		return nil, nil, nil
	end
	return ch, ch:FindFirstChildOfClass("Humanoid"), ch:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function quieto(parar: boolean)
	local _, h = personaje()
	if h then
		h.WalkSpeed = if parar then 0 else 16
	end
end

type ResultadoPiso = "ganado" | "cambiar" | "salir"

-- Juega un piso hasta ganarlo, cambiarlo (más de 3 quemadas) o salir.
local function jugarPiso(
	tab: Tablero,
	e: Estado,
	salir: () -> boolean,
	barra: Interfaz.Barra,
	primera: boolean
): ResultadoPiso
	local n = tab.n
	local carpeta = tab.modelo
	local ocupado = false
	local ultima: number? = nil
	local preguntas = 0
	local resultado: ResultadoPiso? = nil

	local function datos()
		barra.poner(("Piso %d×%d   ·   Tanteos: %d   ·   Quemadas: %d"):format(n, n, e.tanteos, e.quemadas))
	end
	local function refrescar()
		pintar(tab, e)
		datos()
	end
	refrescar()

	local _, _, raiz = personaje()
	if raiz then
		(raiz.Parent :: Model):PivotTo(tab.inicio)
	end
	if primera then
		Interfaz.mensaje("Tocá una baldosa para tantearla con el palo. Caminá hasta la META.", COLOR, 6)
	else
		Interfaz.mensaje(("Piso %d×%d: una lava en cada fila y en cada columna."):format(n, n), COLOR, 4)
	end

	-- Tantear: toque corto o clic sobre una baldosa (sin arrastrar la cámara).
	local conexiones: { RBXScriptConnection } = {}
	local inicioToque: { [InputObject]: Vector3 } = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { carpeta }

	local function tantearEn(pantalla: Vector3)
		if ocupado or e.ganado then
			return
		end
		local rayo = workspace.CurrentCamera:ScreenPointToRay(pantalla.X, pantalla.Y)
		local golpe = workspace:Raycast(rayo.Origin, rayo.Direction * 500, params)
		if not golpe then
			return
		end
		local i = golpe.Instance:GetAttribute("i")
		if type(i) ~= "number" then
			return
		end
		local f, c = L.celda(n, i)
		local r = L.tantear(e, f, c)
		local _, _, rz = personaje()
		if rz then
			palo(rz.Position + Vector3.new(0, 1, 0), tab.baldosas[i].Position + Vector3.new(0, 1, 0), carpeta)
		end
		sonar("Tanteo")
		if r == "lava" then
			sonar("Lava")
			Interfaz.mensaje("¡Lava! El resto de esa fila y de esa columna es piso.", COLOR)
		elseif r == "piso" then
			sonar("Piso")
			if e.piso.conNumeros then
				local k = L.lavasAlLado(e.piso, f, c)
				Interfaz.mensaje(
					("Piso firme. Tiene %d %s al lado."):format(k, if k == 1 then "lava" else "lavas"),
					Estilo.color.geometrico
				)
			else
				Interfaz.mensaje("Piso firme.", Estilo.color.geometrico, 2)
			end
		end
		refrescar()
	end

	table.insert(
		conexiones,
		UserInputService.InputBegan:Connect(function(input, procesado)
			if procesado then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				inicioToque[input] = input.Position
			end
		end)
	)
	table.insert(
		conexiones,
		UserInputService.InputEnded:Connect(function(input)
			local desde = inicioToque[input]
			inicioToque[input] = nil
			if desde and (input.Position - desde).Magnitude < 12 then
				tantearEn(input.Position)
			end
		end)
	)

	local function volverAlInicio()
		local ch = personaje()
		if ch then
			ch:PivotTo(tab.inicio)
		end
		ultima = nil
	end

	-- «¿Por qué es segura?»: autoexplicación, no resta puntos.
	local function preguntarPorque(f: number, c: number)
		quieto(true)
		local opciones = { "Ya hay lava en esa fila", "Ya hay lava en esa columna", "Adiviné" }
		local claves: { L.Razon } = { "fila", "columna", "adivino" }
		local k = Interfaz.preguntar("¿Cómo sabías que esta baldosa era segura?", opciones, Estilo.color.deductivo)
		local real = L.razon(e, f, c)
		if L.razonCorrecta(e, f, c, claves[k]) then
			if real == "adivino" then
				Interfaz.mensaje(
					"¡Bien dicho! Esta vez fue suerte: tantear antes es más seguro.",
					Estilo.color.deductivo
				)
			else
				Interfaz.mensaje(
					"¡Eso! Una sola lava por "
						.. (if claves[k] == "fila" then "fila" else "columna")
						.. ": las demás son piso.",
					Estilo.color.geometrico
				)
			end
		elseif real == "adivino" then
			Interfaz.mensaje(
				"Mirá bien: en esa fila y esa columna todavía no se ve ninguna lava.",
				Estilo.color.deductivo,
				5
			)
		else
			Interfaz.mensaje(
				"Fijate: la lava que ya encontraste está en la misma " .. real .. ".",
				Estilo.color.deductivo,
				5
			)
		end
		quieto(false)
	end

	local function paso(f: number, c: number)
		local i = L.indice(n, f, c)
		local yaSabida = e.segurasConocidas[i]
		local seguras = L.deducir(e)
		local razon = L.razon(e, f, c)
		local antes = e.posicion
		local r = L.pisar(e, f, c)
		if r == "lavaConocida" then
			sonar("Lava")
			Interfaz.mensaje("¡Ojo! Esa baldosa ya sabés que es lava.", COLOR)
			local ch = personaje()
			if ch then
				if antes then
					local fa, ca = L.celda(n, antes)
					ch:PivotTo(CFrame.new(centro(n, fa, ca) + Vector3.new(0, 4, 0)))
					ultima = antes
				else
					volverAlInicio()
				end
			end
		elseif r == "quemada" then
			refrescar()
			sonar("Quemada")
			quieto(true)
			Interfaz.mensaje("¡Auch! Esa era lava. Queda marcada: volvé a empezar.", COLOR)
			task.wait(0.9)
			volverAlInicio()
			quieto(false)
			if L.hayQueCambiar(e) then
				resultado = "cambiar"
			elseif e.quemadas == L.QUEMADAS_PARA_CHECKS then
				Interfaz.mensaje(
					"Te marqué con ✓ las baldosas que ya se sabe que son seguras.",
					Estilo.color.geometrico,
					5
				)
			end
		elseif r == "meta" then
			sonar("Ganar")
			resultado = "ganado"
		elseif r == "piso" and not yaSabida then
			-- Pisó sin tantear: a veces se pregunta por qué (solo si la razón es una lava a la vista,
			-- o si de verdad no se podía saber).
			local valePreguntar = razon ~= "adivino" or not seguras[i]
			if valePreguntar and preguntas < 2 and (preguntas == 0 or rnd(1, 3) == 1) then
				preguntas += 1
				preguntarPorque(f, c)
			end
		end
		refrescar()
	end

	-- Bucle: ¿sobre qué baldosa está parado?
	table.insert(
		conexiones,
		RunService.Heartbeat:Connect(function()
			if ocupado or resultado then
				return
			end
			if salir() then
				resultado = "salir"
				return
			end
			local _, h, rz = personaje()
			if not (h and rz) then
				return
			end
			h.JumpHeight = 0
			h.JumpPower = 0
			local pos = rz.Position
			if pos.Y < ORIGEN.Y - 8 then
				volverAlInicio()
				return
			end
			local f, c = celdaDe(n, pos)
			if L.dentro(n, f, c) then
				local i = L.indice(n, f, c)
				if i ~= ultima then
					ultima = i
					ocupado = true
					task.spawn(function()
						paso(f, c)
						ocupado = false
					end)
				end
			elseif f < 1 and ultima ~= nil then
				ultima = nil
				L.alaOrilla(e)
				refrescar()
			end
		end)
	)

	while not resultado do
		task.wait(0.1)
	end
	for _, cx in conexiones do
		cx:Disconnect()
	end
	return resultado :: ResultadoPiso
end

-- Corre el juego hasta que el niño toca «Salir». Devuelve true si completó el módulo (ganó un piso 5×5).
function Juego.jugar(ctx: Contexto): boolean
	escenario = ctx.zona or workspace:FindFirstChild("Lava")
	local origen = escenario and escenario:FindFirstChild("Origen")
	if origen and origen:IsA("BasePart") then
		ORIGEN = origen.Position
	else
		escenario = nil
	end
	sonidos = escenario and escenario:FindFirstChild("Sonidos")
	-- Con StreamingEnabled: que cargue lo de alrededor del piso antes de llevar al jugador.
	pcall(function()
		Players.LocalPlayer:RequestStreamAroundAsync(ORIGEN, 5)
	end)

	local carpeta = Instance.new("Folder")
	carpeta.Name = "JuegoLava"
	carpeta.Parent = workspace

	local ambiente: Sound? = nil
	local base = sonido("Ambiente")
	if base then
		local a = base:Clone()
		a.Looped = true
		a.Parent = carpeta
		a:Play()
		ambiente = a
	end

	local quiereSalir = false
	local barra = Interfaz.barra("🌋 ¡El suelo es lava!", COLOR)
	barra.regla("Regla: en cada fila y en cada columna hay una sola lava")
	barra.alSalir(function()
		quiereSalir = true
	end)
	local function salir()
		return quiereSalir
	end

	local escalera = Escalera.nueva(#L.NIVELES, math.clamp(ctx.nivelInicial or 1, 1, #L.NIVELES))
	local function avisarNivel()
		if ctx.nivel then
			ctx.nivel(escalera.nivel, #L.NIVELES)
		end
	end
	avisarNivel()
	local completo = false
	local primera = true
	local regalo = false -- la escalera pidió ayuda: el próximo piso arranca con una lava descubierta

	while not quiereSalir do
		local nivel = L.NIVELES[escalera.nivel]
		local e = L.nuevo(L.generar(nivel.n, nivel.conNumeros, rnd))
		local pistas = 0
		if regalo then
			e = (L.pisoDeRegalo(e, rnd))
			pistas += 1
			regalo = false
		end
		local tab: Tablero
		Interfaz.telon(("Piso %d×%d"):format(nivel.n, nivel.n), function()
			tab = construir(nivel.n, carpeta)
		end)
		local t0 = os.clock()
		local quemadas, errores = 0, 0
		local r: ResultadoPiso
		while true do
			r = jugarPiso(tab, e, salir, barra, primera)
			primera = false
			quemadas += e.quemadas
			errores += e.erroresMemoria
			if e.ayudaChecks then
				pistas += 1
			end
			if r ~= "cambiar" then
				break
			end
			-- Más de 3 quemadas: piso nuevo y se regala una lava para arrancar con ventaja.
			Interfaz.mensaje("Probemos otro piso. Te regalo una lava descubierta.", COLOR, 5)
			e = (L.pisoDeRegalo(e, rnd))
			pistas += 1
		end

		local ganado = r == "ganado"
		if ganado or quemadas > 0 or e.tanteos > 0 then
			ctx.reto({
				reto = ("lava-%dx%d"):format(nivel.n, nivel.n),
				habilidad = "deductivo",
				aciertos = if ganado then 1 else 0,
				intentos = 1 + quemadas,
				pistas = pistas,
				segundos = math.floor(os.clock() - t0),
			})
			if quemadas > 0 then
				-- Memoria: después de quemarse, volver sin pisar las lavas que ya conocía.
				ctx.reto({
					reto = ("lava-%dx%d-memoria"):format(nivel.n, nivel.n),
					habilidad = "memoria",
					aciertos = math.max(0, quemadas - errores),
					intentos = quemadas,
					pistas = 0,
					segundos = math.floor(os.clock() - t0),
				})
			end
		end

		if not ganado then
			break
		end

		local estrellas = L.estrellas(e)
		local cambio = Escalera.registrar(escalera, quemadas <= 1)
		avisarNivel()
		local nuevoSello = false
		if nivel.n == L.NIVELES[#L.NIVELES].n and not completo then
			completo = true
			nuevoSello = true
		end
		local detalle = ("Tanteos: %d · Quemadas: %d"):format(e.tanteos, quemadas)
		if nuevoSello then
			detalle ..= "\n¡Ganaste el sello Volcán! 🌋"
		end
		task.spawn(function()
			for _ = 1, estrellas do
				task.wait(0.35)
				sonar("Estrella")
			end
		end)
		local k = Interfaz.resultado(
			("¡Cruzaste el piso %d×%d!"):format(nivel.n, nivel.n),
			estrellas,
			detalle,
			{ "Otro piso", "Volver a la plaza" }
		)
		if k == 2 then
			quiereSalir = true
		elseif cambio == "sube" then
			Interfaz.mensaje(
				("¡Subís al piso %d×%d!"):format(L.NIVELES[escalera.nivel].n, L.NIVELES[escalera.nivel].n),
				Estilo.color.oro
			)
		elseif cambio == "baja" then
			Interfaz.mensaje("Practiquemos un piso más chico.", Estilo.color.deductivo)
		elseif cambio == "ayuda" then
			regalo = true
		end
		tab.modelo:Destroy()
	end

	barra.quitar()
	if ambiente then
		ambiente:Stop()
	end
	local _, h = personaje()
	if h then
		h.JumpHeight = 7.2
		h.JumpPower = 50
		h.WalkSpeed = 16
	end
	task.delay(1, function()
		carpeta:Destroy()
	end)
	return completo
end

return Juego
