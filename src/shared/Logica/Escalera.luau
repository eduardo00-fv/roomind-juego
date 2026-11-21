--!strict
-- Dificultad que se ajusta sola, igual para los 5 juegos (instrucciones.md, «Reglas para los 5 juegos»):
-- 2 aciertos seguidos suben un escalón; 2 fallos seguidos dan una ayuda; si sigue fallando, baja un escalón.
-- Lógica pura: se prueba con Lune (pruebas/escalera.luau).

export type Escalera = {
	nivel: number,
	maximo: number,
	aciertosSeguidos: number,
	fallosSeguidos: number,
}

export type Cambio = "sube" | "ayuda" | "baja" | "nada"

local Escalera = {}

function Escalera.nueva(maximo: number, inicio: number?): Escalera
	return { nivel = inicio or 1, maximo = maximo, aciertosSeguidos = 0, fallosSeguidos = 0 }
end

function Escalera.registrar(e: Escalera, acierto: boolean): Cambio
	if acierto then
		e.fallosSeguidos = 0
		e.aciertosSeguidos += 1
		if e.aciertosSeguidos >= 2 and e.nivel < e.maximo then
			e.nivel += 1
			e.aciertosSeguidos = 0
			return "sube"
		end
		return "nada"
	end
	e.aciertosSeguidos = 0
	e.fallosSeguidos += 1
	if e.fallosSeguidos == 2 then
		return "ayuda"
	elseif e.fallosSeguidos >= 3 then
		e.fallosSeguidos = 0
		if e.nivel > 1 then
			e.nivel -= 1
			return "baja"
		end
		return "ayuda"
	end
	return "nada"
end

return Escalera
