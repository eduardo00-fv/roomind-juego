-- El Colado (id «colado»). Diseño: instrucciones.md §4 y la Guía didáctica.
-- Este módulo es TUYO: editalo en Studio (ReplicatedStorage > Juegos > Colado). Rojo no lo toca.
-- Se corre en el cliente cuando alguien pisa el portal de El Colado en la plaza,
-- o la alfombra «Probar» de tu zona (Workspace > Zonas > Colado).
--
-- Para probar solo tu juego: seleccioná Workspace > Zonas > Colado en el Explorer, F para ir ahí con la cámara,
-- y en la pestaña Test usá «Play Here» (aparecés donde está la cámara). Pisá la alfombra Probar.
--
-- Lo que trae ctx:
--   ctx.zona        tu carpeta Workspace.Zonas.Colado (Piso, Inicio, Probar y lo que construyás ahí)
--   ctx.llevar(p)   lleva al jugador encima de una parte (o un CFrame)
--   ctx.interfaz    mensaje(texto, color?, segundos?)
--                   preguntar(titulo, {"opción 1", "opción 2"}, color?) -> número de la elegida (espera)
--                   resultado(titulo, estrellas 0-3, detalle, {"Otra vez", "Volver a la plaza"}, color?) -> número
--                   barra(titulo, color) -> barra de arriba con botón de salir (ver Client.Juegos.Lava)
--                   telon(texto, function() ... end)  pantalla de transición
--   ctx.estilo      colores: ctx.estilo.color.memoria / inductivo / deductivo / geometrico / oro ...
--   ctx.reto({ reto = "colado-1", habilidad = "inductivo", aciertos = 1, intentos = 2, pistas = 0, segundos = 30 })
--                   llamalo por cada reto resuelto; habilidad: memoria, inductivo, deductivo o geometrico
--
-- Devolvé true cuando el niño completa el juego (gana el sello). Reglas: nada de preguntas tipo examen,
-- la matemática va en la mecánica; mensajes sobre la tarea («esa fila ya tiene lava»), en voseo.

local Juego = {}

function Juego.jugar(ctx)
	local I = ctx.interfaz
	local color = ctx.estilo.color.inductivo
	if ctx.zona and ctx.zona:FindFirstChild("Inicio") then
		I.telon("El Colado", function()
			ctx.llevar(ctx.zona.Inicio)
		end)
	end

	-- 🚧 Aquí va tu juego. Borrá esto y construí el tuyo.
	local t0 = os.clock()
	local k = I.preguntar("🚧 El Colado en construcción. ¿Ya está listo?", { "Todavía no", "¡Sí!" }, color)
	ctx.reto({
		reto = "colado-prueba",
		habilidad = "inductivo",
		aciertos = if k == 2 then 1 else 0,
		intentos = 1,
		pistas = 0,
		segundos = math.floor(os.clock() - t0),
	})
	return k == 2
end

return Juego
