# RooMind — el juego (Roblox)

Cinco minijuegos de razonamiento para niños de 8 a 10 años, en Roblox. Una plaza con portales: cada portal
lleva a un minijuego. El diseño de cada uno (reglas, niveles, pistas, base en la investigación) está en
[`instrucciones.md`](instrucciones.md). **Leelo antes de programar tu juego.**

| Juego | Id | Estado |
|---|---|---|
| El Mandadero | `mandadero` | por hacer |
| La Balanza | `balanza` | por hacer |
| ¿Qué se esconde? | `escondido` | por hacer |
| El Colado | `colado` | por hacer |
| ¡El suelo es lava! | `lava` | **listo** (usalo de ejemplo) |
| El Mensajero (extra) | `mensajero` | por hacer |

## Arrancar (una vez)

1. Instalá [Roblox Studio](https://create.roblox.com/) y [Git](https://git-scm.com/).
2. Instalá [Rokit](https://github.com/rojo-rbx/rokit) (trae Rojo y las demás herramientas con la versión exacta del proyecto):
   - Windows (PowerShell): `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`
   - Mac/Linux: `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`
3. Cloná el repo e instalá las herramientas:
   ```bash
   git clone https://github.com/eduardo00-fv/roomind-juego.git
   cd roomind-juego
   rokit install
   ```
4. Instalá el plugin de Rojo en Studio: `rojo plugin install` (o desde el Creator Store, «Rojo»).

## Trabajar

```bash
rojo serve
```

En Studio: abrí un lugar vacío (Baseplate), pestaña **Plugins → Rojo → Connect**. Lo que guardés en `src/`
aparece solo en Studio. **El código se edita en los archivos, no en Studio** (lo que cambiés en Studio dentro
de los scripts se pierde). Si armás modelos o piezas a mano en Studio, guardalos como `.rbxm` dentro de `src/`.

Para probar: **Play** en Studio, caminá hasta el portal de tu juego.

## Dónde va cada cosa

```
src/
  shared/Modulos.luau        catálogo de los 6 juegos (ids y habilidades) — no cambiar ids sin avisar
  shared/Estilo.luau         colores y fuentes comunes
  shared/Logica/<Juego>.luau la REGLA del juego, sin APIs de Roblox (se prueba fuera de Studio)
  client/Juegos/<Juego>.luau lo que se ve y se toca: exporta jugar(ctx) -> completo
  client/Interfaz.luau       mensajes, telón, botones comunes
  client/init.client.luau    conecta los portales con los juegos
  server/Plaza.luau          la plaza y los portales
  server/Reporte.luau        manda el resultado de cada partida a la web de papás
pruebas/                     pruebas de la lógica (Lune)
```

### Agregar tu juego (ejemplo: La Balanza)

1. `src/shared/Logica/Balanza.luau`: la regla pura (estado, jugadas, ¿ganó?). Sin `game:GetService`.
2. `pruebas/balanza.luau`: pruebas de esa lógica (mirá `pruebas/lava.luau`).
3. `src/client/Juegos/Balanza.luau`: exporta `jugar(ctx)`, que corre el juego y devuelve `true` si lo completó.
   Por cada reto resuelto llamá:
   ```lua
   ctx.reto({ reto = "balanza-1", habilidad = "deductivo", aciertos = 1, intentos = 2, pistas = 0, segundos = 35 })
   ```
   `habilidad` es una de: `memoria`, `inductivo`, `deductivo`, `geometrico`.
4. En `src/client/init.client.luau`, sumalo a la tabla `Juegos`: `balanza = require(script.Juegos.Balanza),`

Cada juego construye su mundo lejos de la plaza (Lava usa `x = 600`); elegí otra zona para no chocar.

## Revisar antes de subir

```bash
pruebas/todo.sh     # pruebas (Lune) + lint (selene) + tipos (luau-lsp). En Windows: correlo en Git Bash.
```

## Reglas del juego (no negociables)

- El niño nunca ve la palabra «problema» ni ejercicios escritos: la matemática va dentro de la mecánica.
- Nada de Robux, premios en dinero, ni enlaces a la web de papás dentro del juego (reglas de Roblox).
- Textos en español de Costa Rica, con voseo («tocá», «probá»).
- Nada de datos de niños, docentes ni claves en este repo: es público.

## Git en equipo

- Una rama por juego: `git switch -c balanza`. Subí seguido (`git push -u origin balanza`) y abrí un Pull Request.
- Cada quien toca su `Logica/<Juego>`, `Juegos/<Juego>` y `pruebas/<juego>`. Los archivos comunes
  (`init.client.luau`, `Modulos.luau`, `Estilo.luau`, `Interfaz.luau`) cambian poco: avisá en el grupo antes.
