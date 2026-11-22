--!strict
-- «¿Qué se esconde?» (instrucciones.md §3), niveles 1 y 2. Se juega en pantalla (2D), igual en celular, tablet
-- y computadora. La regla vive en Shared.Logica.Escondido (probada con Lune); aquí solo se dibuja y se leen los
-- toques.
--
-- Cómo se juega:
--   * A la izquierda, una figura tapada por bloques. Tocar un bloque lo destapa (cada uno cuenta).
--   * A la derecha, 3 figuras parecidas. Cuando creás saber cuál es la escondida, la tocás.
--   * Menos bloques destapados = más estrellas. Adivinar mal cuenta como un bloque destapado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Estilo = require(ReplicatedStorage.Shared.Estilo)
local Escalera = require(ReplicatedStorage.Shared.Logica.Escalera)
local E = require(ReplicatedStorage.Shared.Logica.Escondido)
local Interfaz = require(script.Parent.Parent.Interfaz)

export type Contexto = {
	reto: (datos: { [string]: any }) -> (),
	nivelInicial: number?,
	nivel: ((n: number, niveles: number) -> ())?,
}

type Pantalla = {
	gui: ScreenGui,
	bloques: { TextButton },
	opciones: { TextButton },
	marcas: { TextLabel },
}

local Juego = {}

local COLOR = Estilo.color.geometrico
local FIGURA = Color3.fromHex("1F6E38")
local TAPA = Estilo.color.madera
local LETRAS = { "A", "B", "C" }

local rng = Random.new()
local function azar(a: number, b: number): number
	return rng:NextInteger(a, b)
end

local function esquinas(o: GuiObject, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
end

local function borde(o: GuiObject, color: Color3, grosor: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = grosor
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end

-- Dibuja la figura en un marco: 8×6 cuadritos que llenan el marco.
local function dibujarFigura(padre: GuiObject, f: E.Figura, z: number)
	for fila = 1, E.ALTO do
		for col = 1, E.ANCHO do
			local c = Instance.new("Frame")
			c.BorderSizePixel = 0
			c.Position = UDim2.fromScale((col - 1) / E.ANCHO, (fila - 1) / E.ALTO)
			c.Size = UDim2.fromScale(1 / E.ANCHO, 1 / E.ALTO)
			c.BackgroundColor3 = if f[fila][col] then FIGURA else Estilo.color.fondo
			c.ZIndex = z
			c.Parent = padre
		end
	end
end

-- Arma la pantalla de una ronda. `evento` recibe ("bloque", k) u ("opcion", j).
local function construir(e: E.Estado, evento: BindableEvent): Pantalla
	local gui = Instance.new("ScreenGui")
	gui.Name = "Escondido"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -1 -- los mensajes y tarjetas de Interfaz van encima
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Panel entre la barra de arriba (y su regla) y el espacio de los mensajes de abajo.
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 114)
	panel.Size = UDim2.new(0.94, 0, 1, -114 - 100)
	panel.BackgroundColor3 = Estilo.color.tarjeta
	esquinas(panel, 18)
	borde(panel, COLOR, 4)
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(1100, 620)
	limite.Parent = panel
	panel.Parent = gui

	-- Izquierda: el tablero tapado.
	local zonaTablero = Instance.new("Frame")
	zonaTablero.BackgroundTransparency = 1
	zonaTablero.Position = UDim2.fromOffset(14, 14)
	zonaTablero.Size = UDim2.new(0.62, -21, 1, -28)
	zonaTablero.Parent = panel
	local tablero = Instance.new("Frame")
	tablero.AnchorPoint = Vector2.new(0.5, 0.5)
	tablero.Position = UDim2.fromScale(0.5, 0.5)
	tablero.Size = UDim2.fromScale(1, 1)
	tablero.BackgroundColor3 = Estilo.color.fondo
	tablero.ClipsDescendants = true
	esquinas(tablero, 10)
	local proporcion = Instance.new("UIAspectRatioConstraint")
	proporcion.AspectRatio = E.ANCHO / E.ALTO
	proporcion.Parent = tablero
	tablero.Parent = zonaTablero
	dibujarFigura(tablero, e.opciones[e.correcta], 1)

	local bloques: { TextButton } = {}
	for k = 1, E.BLOQUES do
		local bx = (k - 1) % E.BX
		local by = (k - 1) // E.BX
		local b = Instance.new("TextButton")
		b.Position = UDim2.new(bx / E.BX, 2, by / E.BY, 2)
		b.Size = UDim2.new(1 / E.BX, -4, 1 / E.BY, -4)
		b.BackgroundColor3 = TAPA
		b.Text = "?"
		b.TextScaled = true
		b.Font = Estilo.letra
		b.TextColor3 = Color3.fromHex("F3E3CF")
		b.AutoButtonColor = true
		b.ZIndex = 3
		b.Visible = e.tapado[k]
		esquinas(b, 8)
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.2, 0)
		pad.PaddingBottom = UDim.new(0.2, 0)
		pad.Parent = b
		b.Activated:Connect(function()
			evento:Fire("bloque", k)
		end)
		b.Parent = tablero
		bloques[k] = b
	end

	-- Derecha: las opciones, una debajo de la otra.
	local zonaOpciones = Instance.new("Frame")
	zonaOpciones.BackgroundTransparency = 1
	zonaOpciones.Position = UDim2.new(0.62, 7, 0, 14)
	zonaOpciones.Size = UDim2.new(0.38, -21, 1, -28)
	zonaOpciones.Parent = panel
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Vertical
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.VerticalAlignment = Enum.VerticalAlignment.Center
	lista.Padding = UDim.new(0, 10)
	lista.Parent = zonaOpciones

	local n = #e.opciones
	local opciones: { TextButton } = {}
	local marcas: { TextLabel } = {}
	for j = 1, n do
		local b = Instance.new("TextButton")
		b.Text = ""
		b.LayoutOrder = j
		b.Size = UDim2.new(1, 0, 1 / n, -10)
		b.BackgroundColor3 = Estilo.color.tarjeta
		b.AutoButtonColor = true
		esquinas(b, 12)
		borde(b, Estilo.color.secundario, 3)
		b.Parent = zonaOpciones

		local letra = Instance.new("TextLabel")
		letra.BackgroundTransparency = 1
		letra.Text = LETRAS[j]
		letra.TextScaled = true
		letra.Font = Estilo.letra
		letra.TextColor3 = COLOR
		letra.Position = UDim2.new(0, 8, 0.15, 0)
		letra.Size = UDim2.new(0.18, -8, 0.7, 0)
		letra.Parent = b

		local mini = Instance.new("Frame")
		mini.AnchorPoint = Vector2.new(0.5, 0.5)
		mini.Position = UDim2.fromScale(0.58, 0.5)
		mini.Size = UDim2.new(0.74, 0, 1, -14)
		mini.BackgroundColor3 = Estilo.color.fondo
		mini.ClipsDescendants = true
		local p = Instance.new("UIAspectRatioConstraint")
		p.AspectRatio = E.ANCHO / E.ALTO
		p.Parent = mini
		mini.Parent = b
		dibujarFigura(mini, e.opciones[j], 1)

		local marca = Instance.new("TextLabel")
		marca.BackgroundTransparency = 1
		marca.Text = ""
		marca.TextScaled = true
		marca.Font = Estilo.letra
		marca.Size = UDim2.fromScale(1, 1)
		marca.ZIndex = 4
		marca.Parent = b

		b.Activated:Connect(function()
			evento:Fire("opcion", j)
		end)
		opciones[j] = b
		marcas[j] = marca
	end

	return { gui = gui, bloques = bloques, opciones = opciones, marcas = marcas }
end

local function sacarBloque(b: TextButton)
	if not b.Visible then
		return
	end
	local escala = Instance.new("UIScale")
	escala.Parent = b
	local t = TweenService:Create(escala, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Scale = 0,
	})
	t.Completed:Connect(function()
		b.Visible = false
		escala:Destroy()
	end)
	t:Play()
end

local function mostrarTapados(p: Pantalla, e: E.Estado)
	for k, b in p.bloques do
		if not e.tapado[k] then
			sacarBloque(b)
		end
	end
end

local function humanoide(): Humanoid?
	local ch = Players.LocalPlayer.Character
	return ch and ch:FindFirstChildOfClass("Humanoid")
end

-- Corre el juego hasta que el niño toca «Salir». Devuelve true si completó el módulo (resolvió el nivel 2 sin
-- equivocarse).
function Juego.jugar(ctx: Contexto): boolean
	local quiereSalir = false
	local eventoActual: BindableEvent? = nil
	local barra = Interfaz.barra("🧩 ¿Qué se esconde?", COLOR)
	barra.regla("Destapá pocos bloques y elegí cuál figura se esconde")
	barra.alSalir(function()
		quiereSalir = true
		Interfaz.cancelar()
		if eventoActual then
			eventoActual:Fire("salir", 0)
		end
	end)

	-- Mientras juega, el personaje se queda quieto (todo pasa en la pantalla).
	local h = humanoide()
	local velocidad, salto = 16, 50
	if h then
		velocidad, salto = h.WalkSpeed, h.JumpPower
		h.WalkSpeed = 0
		h.JumpPower = 0
	end

	local escalera = Escalera.nueva(E.NIVELES, math.clamp(ctx.nivelInicial or 1, 1, E.NIVELES))
	local function avisarNivel()
		if ctx.nivel then
			ctx.nivel(escalera.nivel, E.NIVELES)
		end
	end
	avisarNivel()

	local completo = false
	local ayuda = false -- la escalera pidió ayuda: la próxima ronda trae solo 2 opciones
	local primera = true

	while not quiereSalir do
		local nivel = escalera.nivel
		local e = E.generar(nivel, azar, ayuda)
		local conAyuda = ayuda
		ayuda = false
		local evento = Instance.new("BindableEvent")
		eventoActual = evento
		local p = construir(e, evento)
		local t0 = os.clock()
		local function contar()
			barra.poner(("Nivel %d de %d · Destapados: %d"):format(nivel, E.NIVELES, e.destapados))
		end
		contar()
		if primera then
			Interfaz.mensaje(
				if nivel == 1
					then "Faltan pocos bloques. Mirá en qué se diferencian A, B y C, y destapá justo ahí."
					else "Todo está tapado. ¿Qué bloque te sirve para descartar una figura?",
				COLOR,
				6
			)
			primera = false
		elseif conAyuda then
			Interfaz.mensaje("Ahora hay solo 2 figuras. Buscá el bloque donde son distintas.", COLOR, 5)
		end

		local salio = false
		while not e.resuelto do
			local tipo, n = evento.Event:Wait()
			if tipo == "salir" or quiereSalir then
				salio = true
				break
			elseif tipo == "bloque" then
				if E.destapar(e, n) then
					sacarBloque(p.bloques[n])
					contar()
				end
			elseif tipo == "opcion" and not e.descartada[n] then
				local acerto, k = E.adivinar(e, n)
				if acerto then
					p.marcas[n].Text = "✓"
					p.marcas[n].TextColor3 = COLOR
				else
					p.marcas[n].Text = "✗"
					p.marcas[n].TextColor3 = Estilo.color.memoria
					p.opciones[n].BackgroundTransparency = 0.5
					p.opciones[n].AutoButtonColor = false
					if k then
						sacarBloque(p.bloques[k])
					end
					contar()
					Interfaz.mensaje(
						"Esa no es. Te destapo un bloque que ayuda (cuenta como destapado).",
						Estilo.color.memoria,
						4
					)
				end
			end
		end
		eventoActual = nil
		evento:Destroy()

		if salio then
			p.gui:Destroy()
			if e.destapados > 0 or e.errores > 0 then
				ctx.reto({
					reto = ("escondido-n%d"):format(nivel),
					habilidad = "geometrico",
					aciertos = 0,
					intentos = math.max(1, e.errores),
					pistas = if conAyuda then 1 else 0,
					segundos = math.floor(os.clock() - t0),
				})
			end
			break
		end

		-- Resuelto: se destapa todo para ver la figura entera.
		for k = 1, E.BLOQUES do
			e.tapado[k] = false
		end
		mostrarTapados(p, e)
		local segundos = math.floor(os.clock() - t0)
		ctx.reto({
			reto = ("escondido-n%d"):format(nivel),
			habilidad = "geometrico",
			aciertos = 1,
			intentos = 1 + e.errores,
			pistas = if conAyuda then 1 else 0,
			segundos = segundos,
		})
		-- La hipótesis: ¿supo dónde mirar? (destapó cerca del mínimo)
		ctx.reto({
			reto = ("escondido-n%d-hipotesis"):format(nivel),
			habilidad = "inductivo",
			aciertos = if E.buenaHipotesis(e) then 1 else 0,
			intentos = 1,
			pistas = 0,
			segundos = segundos,
		})

		local estrellas = E.estrellas(e)
		local cambio = Escalera.registrar(escalera, e.errores == 0)
		avisarNivel()
		local nuevoSello = false
		if nivel == E.NIVELES and e.errores == 0 and not completo then
			completo = true
			nuevoSello = true
		end
		task.wait(0.6)
		local detalle = ("Destapaste %d %s (lo justo era %d). Era: %s."):format(
			e.destapados,
			if e.destapados == 1 then "bloque" else "bloques",
			e.minimo,
			e.nombre
		)
		if e.errores > 0 then
			detalle ..= "\nLa próxima, destapá donde las figuras son distintas antes de elegir."
		end
		if nuevoSello then
			detalle ..= "\n¡Ganaste el sello Tangram! 🧩"
		end
		local k = Interfaz.resultado("¡La encontraste!", estrellas, detalle, { "Otra figura", "Volver a la plaza" }, COLOR)
		p.gui:Destroy()
		if k ~= 1 then
			quiereSalir = true
		elseif cambio == "sube" then
			Interfaz.mensaje("¡Subís al nivel 2: todo tapado!", Estilo.color.oro)
		elseif cambio == "baja" then
			Interfaz.mensaje("Practiquemos con menos bloques tapados.", COLOR)
		elseif cambio == "ayuda" then
			ayuda = true
		end
	end

	barra.quitar()
	local h2 = humanoide()
	if h2 then
		h2.WalkSpeed = velocidad
		h2.JumpPower = salto
	end
	return completo
end

return Juego
