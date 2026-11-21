--!strict
-- Colores y letra compartidos: la «rueda de carreta» de Sarchí, los mismos de la web de papás (papas/web).

local Estilo = {}

Estilo.color = {
	memoria = Color3.fromHex("D7263D"),
	inductivo = Color3.fromHex("F2B705"),
	deductivo = Color3.fromHex("1B6CA8"),
	geometrico = Color3.fromHex("2E9E4F"),
	madera = Color3.fromHex("7A4A2A"),
	oro = Color3.fromHex("C9A227"),
	texto = Color3.fromHex("1F2A33"),
	fondo = Color3.fromHex("EEF3F6"),
	tarjeta = Color3.fromHex("FFFFFF"),
	secundario = Color3.fromHex("5D6A74"),
	lava = Color3.fromRGB(255, 90, 20),
	piedra = Color3.fromRGB(150, 138, 122),
	pisoSeguro = Color3.fromRGB(140, 205, 120),
	grama = Color3.fromRGB(106, 168, 79),
}

-- Color y texto de cada portal de la plaza (mismos ids que Modulos.luau).
Estilo.portal = {
	mandadero = { color = Estilo.color.memoria, icono = "🛵" },
	balanza = { color = Estilo.color.deductivo, icono = "⚖️" },
	escondido = { color = Estilo.color.geometrico, icono = "🧩" },
	colado = { color = Estilo.color.inductivo, icono = "💃" },
	lava = { color = Estilo.color.lava, icono = "🌋" },
}

-- Orden de los portales en la plaza, de izquierda a derecha.
Estilo.ordenPortales = { "mandadero", "balanza", "lava", "escondido", "colado" }

Estilo.letra = Enum.Font.FredokaOne
Estilo.letraTexto = Enum.Font.GothamMedium

return Estilo
