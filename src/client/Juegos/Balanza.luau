--!strict
-- «La Balanza» (instrucciones.md §2). La regla vive en Shared.Logica.Balanza (probada con Lune);
-- aquí se mueve la balanza del modelo «Balanza» del mundo, se ponen los bloques y se conversa con el niño.
--
-- Cómo se juega:
--   * Tocar un bloque de la bandeja lo levanta; tocar un plato lo pone ahí. Tocar un bloque suelto de un plato
--     lo devuelve a la bandeja. En «Dame y quedamos iguales», tocar un bloque lo pasa al otro plato.
--   * Antes de soltar, a veces se pregunta hacia dónde se va a inclinar (predecir obliga a pensar).
--   * Con la balanza pareja, se pregunta cuánto pesa la caja.
-- La cámara queda fija mirando el mostrador; el jugador se queda quieto delante.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Estilo = require(ReplicatedStorage.Shared.Estilo)
local Escalera = require(ReplicatedStorage.Shared.Logica.Escalera)
local B = require(ReplicatedStorage.Shared.Logica.Balanza)
local Interfaz = require(script.Parent.Parent.Interfaz)

type Reto = B.Reto
type Lado = B.Lado

export type Contexto = { reto: (datos: { [string]: any }) -> (), zona: Instance? }

local Juego = {}

local COLOR = Estilo.color.deductivo
local LADO_BLOQUE = 2.1 -- tamaño de un bloque
local CAJA = 3 -- tamaño de una caja misteriosa
local GRADOS_POR_KILO = 2.5
local MAX_GRADOS = 14
local COLORES_PESO = {
	[1] = Color3.fromRGB(242, 183, 5),
	[2] = Color3.fromRGB(46, 158, 79),
	[3] = Color3.fromRGB(27, 108, 168),
	[4] = Color3.fromRGB(140, 80, 170),
	[5] = Color3.fromRGB(215, 38, 61),
}

local azar = Random.new()
local function rnd(a: number, b: number): number
	return azar:NextInteger(a, b)
end

local sonidos: Instance? = nil
local function sonar(nombre: string)
	local s = sonidos and sonidos:FindFirstChild(nombre)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		SoundService:PlayLocalSound(s)
	end
end

-- El modelo: Workspace.Balanza, Workspace.Zonas.Balanza o cualquier «Balanza» que tenga Pivote.
local function buscarModelo(ctx: Contexto): Instance?
	if ctx.zona and ctx.zona:FindFirstChild("Pivote") then
		return ctx.zona
	end
	for _, m in workspace:GetDescendants() do
		if m.Name == "Balanza" and m:FindFirstChild("Pivote") then
			return m
		end
	end
	return nil
end

-- Texto en las caras de un bloque que se ven desde la cámara (atrás = +Z, que mira a la cámara, y arriba).
local function rotular(p: BasePart, texto: string, color: Color3)
	for _, cara in { Enum.NormalId.Back, Enum.NormalId.Top, Enum.NormalId.Front } do
		local s = Instance.new("SurfaceGui")
		s.Face = cara
		s.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		s.PixelsPerStud = 40
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = texto
		t.TextScaled = true
		t.Font = Estilo.letra
		t.TextColor3 = color
		t.Parent = s
		s.Parent = p
	end
end

type Escena = {
	modelo: Instance,
	pivote: BasePart,
	viga: BasePart,
	platos: { [string]: BasePart },
	cuerdas: { [string]: BasePart },
	bandeja: BasePart,
	camara: BasePart,
	jugador: BasePart,
	originales: { [BasePart]: CFrame },
	-- Desplazamientos guardados respecto al pivote (para mover todo junto si mueven el modelo).
	brazo: { [string]: Vector3 }, -- punta de la viga (x) y caída hasta el plato (y)
	rotPlato: { [string]: CFrame },
	rotCuerda: { [string]: CFrame },
	rotViga: CFrame,
}

local function escena(m: Instance): Escena?
	local function p(nombre: string): BasePart?
		local x = m:FindFirstChild(nombre)
		return if x and x:IsA("BasePart") then x else nil
	end
	local pivote, viga, bandeja, camara, jugador = p("Pivote"), p("Viga"), p("Bandeja"), p("Camara"), p("Jugador")
	local pi, pd, ci, cd = p("PlatoIzq"), p("PlatoDer"), p("CuerdaIzq"), p("CuerdaDer")
	if not (pivote and viga and bandeja and camara and jugador and pi and pd and ci and cd) then
		return nil
	end
	local P = (pivote :: BasePart).CFrame
	local e: Escena = {
		modelo = m,
		pivote = pivote :: BasePart,
		viga = viga :: BasePart,
		platos = { izq = pi :: BasePart, der = pd :: BasePart },
		cuerdas = { izq = ci :: BasePart, der = cd :: BasePart },
		bandeja = bandeja :: BasePart,
		camara = camara :: BasePart,
		jugador = jugador :: BasePart,
		originales = {},
		brazo = {},
		rotPlato = {},
		rotCuerda = {},
		rotViga = P:ToObjectSpace((viga :: BasePart).CFrame),
	}
	for _, x in { viga, pi, pd, ci, cd } do
		e.originales[x :: BasePart] = (x :: BasePart).CFrame
	end
	for lado, plato in e.platos do
		e.brazo[lado] = P:PointToObjectSpace(plato.Position)
		e.rotPlato[lado] = (P.Rotation):ToObjectSpace(plato.CFrame.Rotation)
		e.rotCuerda[lado] = (P.Rotation):ToObjectSpace(e.cuerdas[lado].CFrame.Rotation)
	end
	return e
end

-- Pone viga, cuerdas y platos según el ángulo (positivo = baja la izquierda). Devuelve dónde quedó cada plato.
local function inclinar(e: Escena, angulo: number): { [string]: CFrame }
	local P = e.pivote.CFrame
	local vigaCF = P * CFrame.Angles(0, 0, angulo)
	e.viga.CFrame = vigaCF * e.rotViga
	local donde = {}
	for lado, plato in e.platos do
		local b = e.brazo[lado]
		local punta = vigaCF:PointToWorldSpace(Vector3.new(b.X, 0, b.Z))
		local centro = punta + P:VectorToWorldSpace(Vector3.new(0, b.Y, 0))
		local cf = CFrame.new(centro) * P.Rotation
		plato.CFrame = cf * e.rotPlato[lado]
		e.cuerdas[lado].CFrame = CFrame.new((punta + centro) / 2) * P.Rotation * e.rotCuerda[lado]
		donde[lado] = cf
	end
	return donde
end

local function personaje(): (Model?, Humanoid?, BasePart?)
	local ch = Players.LocalPlayer.Character
	if not ch then
		return nil, nil, nil
	end
	return ch, ch:FindFirstChildOfClass("Humanoid"), ch:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Juego.jugar(ctx: Contexto): boolean
	local m = buscarModelo(ctx)
	local e = m and escena(m)
	if not e then
		Interfaz.mensaje("Falta el modelo «Balanza» en el mundo (entregas/Balanza.rbxm).", COLOR, 6)
		return false
	end
	local E = e :: Escena
	sonidos = E.modelo:FindFirstChild("Sonidos")

	local carpeta = Instance.new("Folder")
	carpeta.Name = "JuegoBalanza"
	carpeta.Parent = workspace

	-- Cámara fija y jugador quieto delante del mostrador.
	local cam = workspace.CurrentCamera
	local camTipo = cam.CameraType
	local _, _, raiz = personaje()
	Interfaz.telon("⚖️ La Balanza", function()
		local ch = personaje()
		if ch then
			ch:PivotTo(E.jugador.CFrame + Vector3.new(0, 3, 0))
		end
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = E.camara.CFrame
	end)
	if raiz then
		raiz.Anchored = true
	end

	local ambiente: Sound? = nil
	local base = sonidos and sonidos:FindFirstChild("Ambiente")
	if base and base:IsA("Sound") and base.SoundId ~= "" then
		local a = base:Clone()
		a.Looped = true
		a.Parent = carpeta
		a:Play()
		ambiente = a
	end

	local quiereSalir = false
	local barra = Interfaz.barra("⚖️ La Balanza", COLOR)
	barra.alSalir(function()
		quiereSalir = true
	end)

	-- Estado de la escena -------------------------------------------------------------------------
	local reto: Reto? = nil
	local partes: { [number]: Part } = {}
	local elegido: number? = nil
	local ayudaId: number? = nil
	local trabada = false -- nivel 1: la balanza no se mueve hasta que el niño predice
	local angulo, velocidad = 0, 0

	local function objetivo(): number
		if not reto or trabada then
			return 0
		end
		local g = math.clamp(B.diferencia(reto :: Reto) * GRADOS_POR_KILO, -MAX_GRADOS, MAX_GRADOS)
		return math.rad(g)
	end

	local function empujon(fuerza: number)
		velocidad += fuerza
	end

	-- Dónde va cada bloque: en filas de 3 sobre su plato, o en fila sobre la bandeja.
	local function destinos(donde: { [string]: CFrame }): { [number]: CFrame }
		local r = reto :: Reto
		local res = {}
		local cuenta = { izq = 0, der = 0, bandeja = 0 }
		for _, b in r.bloques do
			local k = cuenta[b.lado]
			cuenta[b.lado] = k + 1
			local alto = if b.misterio then CAJA else LADO_BLOQUE
			if b.lado == "bandeja" then
				local paso = 2.8
				local ancho = E.bandeja.Size.X
				local x = -ancho / 2 + 2 + k * paso
				res[b.id] = E.bandeja.CFrame
					* CFrame.new(x, E.bandeja.Size.Y / 2 + alto / 2 + (if b.id == elegido then 2.5 else 0), 0)
			else
				local cf = donde[b.lado]
				local capa = k // 9
				local i = k % 9
				local col, fila = i % 3 - 1, i // 3 - 1
				local grosor = E.platos[b.lado].Size.X / 2
				res[b.id] = cf * CFrame.new(col * 2.6, grosor + alto / 2 + capa * (LADO_BLOQUE + 0.1), fila * 2.6)
			end
		end
		return res
	end

	local function crearBloques()
		carpeta:ClearAllChildren()
		partes = {}
		for _, b in (reto :: Reto).bloques do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			if b.misterio then
				p.Size = Vector3.new(CAJA, CAJA, CAJA)
				p.Color = Color3.fromRGB(170, 120, 70)
				p.Material = Enum.Material.Cardboard
				rotular(p, "?", Color3.new(1, 1, 1))
			else
				p.Size = Vector3.new(LADO_BLOQUE, LADO_BLOQUE, LADO_BLOQUE)
				p.Color = COLORES_PESO[b.peso] or Estilo.color.secundario
				p.Material = Enum.Material.SmoothPlastic
				rotular(p, tostring(b.peso), Color3.new(1, 1, 1))
			end
			p:SetAttribute("id", b.id)
			p.Name = "Bloque" .. b.id
			p.CFrame = E.bandeja.CFrame + Vector3.new(0, 20, 0)
			p.Parent = carpeta
			partes[b.id] = p
		end
		local donde = inclinar(E, angulo)
		for id, cf in destinos(donde) do
			partes[id].CFrame = cf
		end
	end

	local function marcarAyuda()
		for id, p in partes do
			local h = p:FindFirstChild("Ayuda")
			local debe = id == ayudaId
			if debe and not h then
				local x = Instance.new("Highlight")
				x.Name = "Ayuda"
				x.FillColor = Color3.fromRGB(255, 255, 160)
				x.FillTransparency = 0.4
				x.OutlineColor = Color3.new(1, 1, 1)
				x.Parent = p
			elseif not debe and h then
				h:Destroy()
			end
		end
	end

	-- Animación: resorte de la viga y bloques que se deslizan a su lugar.
	local animar = RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 1 / 20)
		local meta = objetivo()
		local acel = -40 * (angulo - meta) - 4.5 * velocidad
		velocidad += acel * dt
		angulo += velocidad * dt
		local donde = inclinar(E, angulo)
		if reto then
			local t = 1 - math.exp(-14 * dt)
			for id, cf in destinos(donde) do
				local p = partes[id]
				if p then
					p.CFrame = p.CFrame:Lerp(cf, t)
				end
			end
		end
		cam.CFrame = E.camara.CFrame
	end)

	-- Toques: rayo desde la pantalla a los bloques, los platos o la bandeja.
	local tocado = Instance.new("BindableEvent")
	-- Salir despierta al bucle que espera un toque.
	barra.alSalir(function()
		quiereSalir = true
		tocado:Fire(carpeta)
	end)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { carpeta, E.platos.izq, E.platos.der, E.bandeja }
	local inicioToque: { [InputObject]: Vector3 } = {}
	local conexiones = {
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
		end),
		UserInputService.InputEnded:Connect(function(input)
			local desde = inicioToque[input]
			inicioToque[input] = nil
			if not desde or (input.Position - desde).Magnitude > 12 then
				return
			end
			local rayo = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
			local golpe = workspace:Raycast(rayo.Origin, rayo.Direction * 300, params)
			if golpe then
				tocado:Fire(golpe.Instance)
			end
		end),
	}

	-- Un reto -----------------------------------------------------------------------------------------
	local escalera = Escalera.nueva(B.NIVELES)
	local completo = false
	local ayudaProxima = false

	local function preguntarInclina(titulo: string): number
		return Interfaz.preguntar(titulo, B.OPCIONES_INCLINA, COLOR)
	end

	local function textoLado(lado: string): string
		return if lado == "izq" then "la izquierda" else "la derecha"
	end

	-- Devuelve: acierto al primer intento, intentos, pistas.
	local function jugarReto(r: Reto): (boolean, number, number)
		reto = r
		elegido, ayudaId = nil, nil
		trabada = r.tipo == "predecir"
		crearBloques()
		barra.poner(("Nivel %d de %d   ·   %s"):format(r.nivel, B.NIVELES, B.TITULOS[r.nivel]))
		local intentos, pistas, fallos = 0, 0, 0
		local function pedirAyuda()
			if r.tipo ~= "predecir" then
				local id = B.ayuda(r)
				ayudaId = id
				marcarAyuda()
				if id then
					pistas += 1
				end
			end
		end
		if ayudaProxima then
			ayudaProxima = false
			pedirAyuda()
		end

		if r.tipo == "predecir" then
			barra.regla("Regla: baja el plato que pesa más")
			task.wait(0.8)
			while true do
				intentos += 1
				local k = preguntarInclina("La balanza está trabada. Si la soltamos, ¿qué pasa?")
				trabada = false
				sonar("Inclina")
				task.wait(1.2)
				if k == B.opcionInclina(r) then
					sonar("Bien")
					Interfaz.mensaje(
						("¡Eso! Izquierda %d, derecha %d."):format(B.total(r, "izq"), B.total(r, "der")),
						Estilo.color.geometrico
					)
					task.wait(2)
					return intentos == 1, intentos, pistas
				end
				fallos += 1
				sonar("Mal")
				empujon(if angulo >= 0 then 3 else -3)
				Interfaz.mensaje(
					("Sumá cada plato: izquierda %d, derecha %d."):format(B.total(r, "izq"), B.total(r, "der")),
					COLOR,
					5
				)
				task.wait(2.5)
				if intentos >= 2 then
					return false, intentos, pistas + 1
				end
				trabada = true
				task.wait(0.6)
			end
		end

		if r.tipo == "pasar" then
			barra.regla("Regla: pasá bloques del plato pesado al liviano")
			task.wait(0.8)
			local ops = B.opcionesPasar(r, rnd)
			local textos = {}
			for i, v in ops do
				textos[i] = ("Pasar %d %s"):format(v, if v == 1 then "bloque" else "bloques")
			end
			local pesado = if B.diferencia(r) > 0 then "izq" else "der"
			local k = Interfaz.preguntar(
				("Todos los bloques pesan 1. ¿Cuántos tenés que pasar de %s al otro plato para que queden parejas?"):format(
					textoLado(pesado)
				),
				textos,
				COLOR
			)
			local predijo = ops[k]
			local necesarios = B.pasarNecesarios(r)
			Interfaz.mensaje("Ahora pasalos: tocá un bloque para cambiarlo de plato.", COLOR, 5)
			local movidas = 0
			while not B.parejas(r) and not quiereSalir do
				local x = tocado.Event:Wait()
				local id = x:GetAttribute("id")
				if type(id) == "number" then
					local b = B.bloque(r, id)
					if b and B.mover(r, id, if b.lado == "izq" then "der" else "izq") then
						movidas += 1
						sonar("Poner")
						if fallos >= 2 or ayudaId then
							pedirAyuda()
						end
					end
				end
			end
			if quiereSalir then
				return false, 1, pistas
			end
			sonar("Pareja")
			task.wait(0.8)
			intentos = 1
			if predijo == necesarios then
				sonar("Bien")
				Interfaz.mensaje(
					("¡Parejas! Con %d alcanzaba: cada bloque que pasa le quita 1 a un plato y le suma 1 al otro."):format(
						necesarios
					),
					Estilo.color.geometrico,
					6
				)
				task.wait(3)
				return movidas == necesarios, intentos, pistas
			end
			Interfaz.mensaje(
				("Eran %d, no %d: cada bloque que pasás cambia la diferencia en 2."):format(necesarios, predijo),
				COLOR,
				6
			)
			task.wait(3.5)
			return false, intentos, pistas
		end

		-- «caja»: emparejar con la bandeja y decir cuánto pesa.
		barra.regla("Regla: si quedan parejas, los dos platos pesan lo mismo")
		local predicciones = 0
		Interfaz.mensaje("Tocá un bloque de abajo y después el plato donde lo querés poner.", COLOR, 5)
		while not B.parejas(r) and not quiereSalir do
			local x = tocado.Event:Wait()
			local id = x:GetAttribute("id")
			local lado = x:GetAttribute("Lado")
			if type(id) == "number" then
				local b = B.bloque(r, id) :: B.Bloque
				if b.lado == "bandeja" then
					elegido = if elegido == id then nil else id
				elseif not B.esFijo(b) and not elegido then
					B.mover(r, id, "bandeja")
					sonar("Poner")
				elseif elegido then
					lado = b.lado -- tocó un bloque que está en un plato: cuenta como tocar ese plato
				end
			end
			if elegido and (lado == "izq" or lado == "der") then
				local id2 = elegido :: number
				-- Predecir antes de soltar: la primera vez y después de vez en cuando.
				if predicciones == 0 or (predicciones < 3 and rnd(1, 3) == 1) then
					predicciones += 1
					local k = preguntarInclina(
						("Vas a poner el %d en %s. ¿Qué va a pasar?"):format(
							(B.bloque(r, id2) :: B.Bloque).peso,
							textoLado(lado)
						)
					)
					B.mover(r, id2, lado)
					elegido = nil
					sonar("Poner")
					task.wait(1)
					if k == B.opcionInclina(r) then
						sonar("Bien")
						Interfaz.mensaje("¡Bien predicho!", Estilo.color.geometrico, 2)
					else
						sonar("Mal")
						empujon(if B.diferencia(r) >= 0 then 2 else -2)
						Interfaz.mensaje(B.OPCIONES_INCLINA[B.opcionInclina(r)] .. ". ¿Por qué será?", COLOR, 3)
					end
				else
					B.mover(r, id2, lado)
					elegido = nil
					sonar("Poner")
				end
				if ayudaId then
					pedirAyuda()
				end
			end
		end
		if quiereSalir then
			return false, 1, pistas
		end
		ayudaId = nil
		marcarAyuda()
		sonar("Pareja")
		Interfaz.mensaje("¡Parejas! 🙌", Estilo.color.oro, 2)
		task.wait(1.6)

		local una = r.nivel == 5
		local ops = B.opcionesPeso(r, rnd)
		local textos = {}
		for i, v in ops do
			textos[i] = tostring(v)
		end
		local w = r.pesoCaja :: number
		while true do
			intentos += 1
			local k =
				Interfaz.preguntar(if una then "¿Cuánto pesa UNA caja?" else "¿Cuánto pesa la caja?", textos, COLOR)
			if ops[k] == w then
				sonar("Bien")
				Interfaz.mensaje(("¡Eso! La caja pesa %d."):format(w), Estilo.color.geometrico)
				task.wait(2)
				return intentos == 1, intentos, pistas
			end
			fallos += 1
			sonar("Mal")
			empujon(4)
			local der = B.total(r, "der")
			local pista: string
			if r.nivel == 2 then
				pista = ("La caja pesa lo mismo que todo el otro plato junto: %d."):format(der)
			elseif r.nivel == 3 then
				local sueltos = B.total(r, "izq") - w
				pista = ("El otro plato pesa %d, pero la caja no está sola: tiene %d al lado."):format(der, sueltos)
			else
				pista = ("Las dos cajas juntas pesan lo que les falta para %d. ¿Y una sola?"):format(der)
			end
			if fallos >= 2 then
				pistas += 1
			end
			Interfaz.mensaje(pista, COLOR, 6)
			task.wait(2.5)
			if intentos >= 3 then
				Interfaz.mensaje(("Pesaba %d. ¡Vamos con otra!"):format(w), COLOR, 4)
				task.wait(3)
				return false, intentos, pistas
			end
		end
	end

	-- Bucle de retos ---------------------------------------------------------------------------------
	local hechos = 0
	while not quiereSalir do
		local nivel = escalera.nivel
		local r = B.generar(nivel, rnd)
		local t0 = os.clock()
		local acierto, intentos, pistas = jugarReto(r)
		if quiereSalir then
			break
		end
		hechos += 1
		ctx.reto({
			reto = ("balanza-n%d"):format(nivel),
			habilidad = "deductivo",
			aciertos = if acierto then 1 else 0,
			intentos = intentos,
			pistas = pistas,
			segundos = math.floor(os.clock() - t0),
		})
		local cambio = Escalera.registrar(escalera, acierto)
		local nuevoSello = false
		if nivel == B.NIVELES and acierto and not completo then
			completo = true
			nuevoSello = true
		end
		if cambio == "ayuda" then
			ayudaProxima = true
		end
		if cambio == "sube" or nuevoSello or hechos % 5 == 0 then
			local estrellas = if acierto and pistas == 0 then 3 elseif acierto then 2 else 1
			task.spawn(function()
				for _ = 1, estrellas do
					task.wait(0.35)
					sonar("Estrella")
				end
			end)
			local titulo = if cambio == "sube" then ("¡Subís al nivel %d!"):format(escalera.nivel) else "¡Muy bien!"
			local detalle = if nuevoSello then "¡Ganaste el sello Balanza! ⚖️" else B.TITULOS[escalera.nivel]
			local k = Interfaz.resultado(titulo, estrellas, detalle, { "Seguir", "Volver a la plaza" })
			if k == 2 then
				quiereSalir = true
			end
		elseif cambio == "baja" then
			Interfaz.mensaje("Practiquemos uno más fácil.", COLOR)
			task.wait(1.5)
		end
	end

	-- Salida: todo como estaba.
	animar:Disconnect()
	for _, c in conexiones do
		c:Disconnect()
	end
	tocado:Destroy()
	for p, cf in E.originales do
		p.CFrame = cf
	end
	barra.quitar()
	if ambiente then
		ambiente:Stop()
	end
	carpeta:Destroy()
	cam.CameraType = if camTipo == Enum.CameraType.Scriptable then Enum.CameraType.Custom else camTipo
	local _, _, rz = personaje()
	if rz then
		rz.Anchored = false
	end
	return completo
end

return Juego
