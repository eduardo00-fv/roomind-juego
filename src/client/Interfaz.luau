--!strict
-- Interfaz común de los minijuegos: barra de arriba, mensajes de una línea, preguntas con botones grandes
-- y la tarjeta de resultado. Botones táctiles grandes: la mayoría juega en celular o tablet.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Estilo = require(ReplicatedStorage.Shared.Estilo)

local Interfaz = {}

local gui = Instance.new("ScreenGui")
gui.Name = "MathForge"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function esquinas(o: GuiObject, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
end

local function borde(o: GuiObject, color: Color3, grosor: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = grosor
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
end

local function etiqueta(texto: string, letra: Enum.Font?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = texto
	t.TextScaled = true
	t.Font = letra or Estilo.letra
	t.TextColor3 = Estilo.color.texto
	return t
end

function Interfaz.boton(texto: string, color: Color3, padre: Instance): TextButton
	local b = Instance.new("TextButton")
	b.Text = texto
	b.TextScaled = true
	b.Font = Estilo.letra
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	esquinas(b, 14)
	borde(b, color:Lerp(Color3.new(0, 0, 0), 0.35), 3)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = b
	b.Parent = padre
	return b
end

-- Barra de arriba: título del juego + datos («Tanteos: 2») + botón Salir. Devuelve funciones para actualizarla.
export type Barra = {
	poner: (texto: string) -> (),
	regla: (texto: string) -> (),
	alSalir: (fn: () -> ()) -> (),
	quitar: () -> (),
}

function Interfaz.barra(titulo: string, color: Color3): Barra
	local marco = Instance.new("Frame")
	marco.Name = "Barra"
	marco.AnchorPoint = Vector2.new(0.5, 0)
	marco.Position = UDim2.new(0.5, 0, 0, 8)
	marco.Size = UDim2.new(0.94, 0, 0, 56)
	marco.BackgroundColor3 = Estilo.color.tarjeta
	esquinas(marco, 16)
	borde(marco, color, 4)
	marco.Parent = gui

	local t = etiqueta(titulo)
	t.TextColor3 = color
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Position = UDim2.fromOffset(14, 6)
	t.Size = UDim2.new(0.38, -14, 1, -12)
	t.Parent = marco

	local datos = etiqueta("", Estilo.letra)
	datos.TextXAlignment = Enum.TextXAlignment.Right
	datos.Position = UDim2.new(0.38, 0, 0, 10)
	datos.Size = UDim2.new(0.62, -120, 1, -20)
	datos.Parent = marco

	local salir = Interfaz.boton("Salir", Estilo.color.secundario, marco)
	salir.AnchorPoint = Vector2.new(1, 0.5)
	salir.Position = UDim2.new(1, -8, 0.5, 0)
	salir.Size = UDim2.new(0, 100, 1, -12)

	-- La regla del juego, siempre a la vista debajo de la barra.
	local regla = etiqueta("", Estilo.letra)
	regla.AnchorPoint = Vector2.new(0.5, 0)
	regla.Position = UDim2.new(0.5, 0, 0, 70)
	regla.Size = UDim2.new(0.8, 0, 0, 34)
	regla.BackgroundTransparency = 0.1
	regla.BackgroundColor3 = color
	regla.TextColor3 = Color3.new(1, 1, 1)
	regla.Visible = false
	esquinas(regla, 12)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = regla
	regla.Parent = gui

	local conexion: RBXScriptConnection? = nil
	return {
		poner = function(texto)
			datos.Text = texto
		end,
		regla = function(texto)
			regla.Text = texto
			regla.Visible = texto ~= ""
		end,
		alSalir = function(fn)
			if conexion then
				conexion:Disconnect()
			end
			conexion = salir.Activated:Connect(fn)
		end,
		quitar = function()
			marco:Destroy()
			regla:Destroy()
		end,
	}
end

-- Mensaje de una línea abajo al centro. Un mensaje nuevo reemplaza al anterior.
local mensajeActual: Frame? = nil
local margenAbajo = 0

-- Espacio libre abajo (en píxeles) para que los mensajes no tapen los controles de un juego. 0 = normal.
function Interfaz.margenAbajo(px: number)
	margenAbajo = px
end

-- Preguntas abiertas (preguntar/elegir): Interfaz.cancelar() las cierra todas y devuelven 0.
local abiertas: { [BindableEvent]: boolean } = {}
function Interfaz.cancelar()
	for ev in abiertas do
		ev:Fire(0)
	end
end
function Interfaz.mensaje(texto: string, color: Color3?, segundos: number?)
	if mensajeActual then
		mensajeActual:Destroy()
	end
	local marco = Instance.new("Frame")
	marco.AnchorPoint = Vector2.new(0.5, 1)
	marco.Position = UDim2.new(0.5, 0, 1, -24 - margenAbajo)
	marco.Size = UDim2.new(0.8, 0, 0, 64)
	marco.BackgroundColor3 = Estilo.color.tarjeta
	esquinas(marco, 16)
	borde(marco, color or Estilo.color.deductivo, 4)
	local t = etiqueta(texto, Estilo.letra)
	t.Position = UDim2.fromOffset(12, 8)
	t.Size = UDim2.new(1, -24, 1, -16)
	t.Parent = marco
	marco.Parent = gui
	mensajeActual = marco
	local escala = Instance.new("UIScale")
	escala.Scale = 0.8
	escala.Parent = marco
	TweenService:Create(escala, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local esta = marco
	task.delay(segundos or 3.5, function()
		if mensajeActual == esta then
			esta:Destroy()
			mensajeActual = nil
		end
	end)
end

-- Tarjeta al centro con una pregunta y opciones. Espera (yield) hasta que toque una; devuelve su número
-- (0 si se canceló con Interfaz.cancelar, por ejemplo al tocar Salir).
function Interfaz.preguntar(titulo: string, opciones: { string }, color: Color3?): number
	local c = color or Estilo.color.deductivo
	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.new(0, 0, 0)
	fondo.BackgroundTransparency = 0.55
	fondo.ZIndex = 5
	fondo.Parent = gui

	local tarjeta = Instance.new("Frame")
	tarjeta.AnchorPoint = Vector2.new(0.5, 0.5)
	tarjeta.Position = UDim2.fromScale(0.5, 0.5)
	tarjeta.Size = UDim2.new(0.7, 0, 0, 110 + #opciones * 70)
	tarjeta.BackgroundColor3 = Estilo.color.tarjeta
	tarjeta.ZIndex = 6
	esquinas(tarjeta, 20)
	borde(tarjeta, c, 5)
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(560, math.huge)
	limite.Parent = tarjeta
	tarjeta.Parent = fondo

	local t = etiqueta(titulo)
	t.Position = UDim2.fromOffset(16, 14)
	t.Size = UDim2.new(1, -32, 0, 70)
	t.ZIndex = 7
	t.Parent = tarjeta

	local elegido = Instance.new("BindableEvent")
	for i, texto in opciones do
		local b = Interfaz.boton(texto, c, tarjeta)
		b.Position = UDim2.fromOffset(20, 96 + (i - 1) * 70)
		b.Size = UDim2.new(1, -40, 0, 58)
		b.ZIndex = 7
		b.Activated:Connect(function()
			elegido:Fire(i)
		end)
	end
	abiertas[elegido] = true
	local i = elegido.Event:Wait()
	abiertas[elegido] = nil
	fondo:Destroy()
	elegido:Destroy()
	return i
end

-- Como preguntar, pero en una franja abajo y sin oscurecer: para preguntas donde hay que MIRAR la escena
-- (¿hacia dónde se inclina?, ¿cuánto pesa?). Opciones en fila. Espera hasta que toque una; devuelve su número.
function Interfaz.elegir(titulo: string, opciones: { string }, color: Color3?): number
	local c = color or Estilo.color.deductivo
	if mensajeActual then -- el panel ocupa el lugar del mensaje
		mensajeActual:Destroy()
		mensajeActual = nil
	end
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -12)
	panel.Size = UDim2.new(0.94, 0, 0, 138)
	panel.BackgroundColor3 = Estilo.color.tarjeta
	panel.ZIndex = 6
	esquinas(panel, 18)
	borde(panel, c, 4)
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(980, math.huge)
	limite.Parent = panel
	panel.Parent = gui

	local t = etiqueta(titulo)
	t.Position = UDim2.fromOffset(14, 8)
	t.Size = UDim2.new(1, -28, 0, 46)
	t.ZIndex = 7
	t.Parent = panel

	local fila = Instance.new("Frame")
	fila.BackgroundTransparency = 1
	fila.Position = UDim2.fromOffset(14, 62)
	fila.Size = UDim2.new(1, -28, 0, 62)
	fila.ZIndex = 7
	fila.Parent = panel
	local lista = Instance.new("UIListLayout")
	lista.FillDirection = Enum.FillDirection.Horizontal
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Padding = UDim.new(0, 12)
	lista.Parent = fila

	local elegido = Instance.new("BindableEvent")
	local n = #opciones
	for i, texto in opciones do
		local b = Interfaz.boton(texto, c, fila)
		b.Size = UDim2.new(1 / n, -12 * (n - 1) / n, 1, 0)
		b.LayoutOrder = i
		b.ZIndex = 8
		b.Activated:Connect(function()
			elegido:Fire(i)
		end)
	end
	local escala = Instance.new("UIScale")
	escala.Scale = 0.85
	escala.Parent = panel
	TweenService:Create(escala, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	abiertas[elegido] = true
	local i = elegido.Event:Wait()
	abiertas[elegido] = nil
	panel:Destroy()
	elegido:Destroy()
	return i
end

-- Resultado de un reto: estrellas (0 = sin estrellas) + una línea + botones. Devuelve el número del botón.
function Interfaz.resultado(
	titulo: string,
	estrellas: number,
	detalle: string,
	botones: { string },
	color: Color3?
): number
	local s = ""
	if estrellas > 0 then
		s = string.rep("★", estrellas) .. string.rep("☆", 3 - estrellas) .. "\n"
	end
	return Interfaz.preguntar(s .. titulo .. "\n" .. detalle, botones, color or Estilo.color.oro)
end

-- Pantalla de carga corta al entrar o salir de un juego (tapa el teletransporte).
function Interfaz.telon(texto: string, fn: () -> ())
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(0, -60)
	f.Size = UDim2.new(1, 0, 1, 60)
	f.BackgroundColor3 = Estilo.color.madera
	f.BackgroundTransparency = 1
	f.ZIndex = 20
	local t = etiqueta(texto)
	t.TextColor3 = Color3.new(1, 1, 1)
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.new(0.8, 0, 0, 70)
	t.TextTransparency = 1
	t.ZIndex = 21
	t.Parent = f
	f.Parent = gui
	local info = TweenInfo.new(0.35)
	TweenService:Create(f, info, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(t, info, { TextTransparency = 0 }):Play()
	task.wait(0.4)
	fn()
	task.wait(0.5)
	TweenService:Create(f, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(t, info, { TextTransparency = 1 }):Play()
	task.wait(0.4)
	f:Destroy()
end

return Interfaz
