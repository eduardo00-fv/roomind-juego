--!strict
-- Catálogo de módulos. Los `id` y `habilidades` tienen que coincidir con papas/servidor/modulos.ts.
-- Habilidades válidas: "memoria", "inductivo", "deductivo", "geometrico".
-- Los 5 minijuegos (instrucciones.md) + El Mensajero como extra.

export type Habilidad = "memoria" | "inductivo" | "deductivo" | "geometrico"
export type Modulo = { id: string, nombre: string, habilidades: { Habilidad }, extra: boolean? }

local Modulos: { [string]: Modulo } = {
	mandadero = { id = "mandadero", nombre = "El Mandadero", habilidades = { "memoria", "geometrico" } },
	balanza = { id = "balanza", nombre = "La Balanza", habilidades = { "deductivo" } },
	escondido = { id = "escondido", nombre = "¿Qué se esconde?", habilidades = { "inductivo", "geometrico" } },
	colado = { id = "colado", nombre = "El Colado", habilidades = { "inductivo" } },
	lava = { id = "lava", nombre = "¡El suelo es lava!", habilidades = { "deductivo", "memoria" } },
	mensajero = {
		id = "mensajero",
		nombre = "El Mensajero",
		habilidades = { "memoria", "deductivo", "geometrico" },
		extra = true,
	},
}

return Modulos
