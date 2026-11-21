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

Para los juegos del equipo **no hace falta instalar nada más que Studio**: se trabaja en el mundo compartido
(ver «Cómo trabajamos en equipo»). Lo de abajo es solo para quien corre Rojo.

## Dónde va el código con Rojo

```
src/shared/Modulos.luau        catálogo de los 6 juegos (ids y habilidades): no cambiar ids sin avisar
src/shared/Estilo.luau         colores y letras comunes
src/shared/Logica/<Juego>.luau regla pura de un juego, sin APIs de Roblox (se prueba con Lune en pruebas/)
src/client/Juegos/<Juego>.luau juegos hechos con Rojo (hoy la Lava): exporta jugar(ctx) -> completo
src/client/Interfaz.luau       mensajes, telón, preguntas, resultado
src/client/init.client.luau    carga los juegos (de aquí y de ReplicatedStorage.Juegos) y conecta los portales
src/server/Plaza.luau          arma la plaza si no está en el mundo
src/server/Reporte.luau        manda cada partida a la web de papás
plantillas/                    plantillas de juegos y zonas; plantillas/armar.sh genera entregas/*.rbxm
```

## Arrancar con Rojo (una vez)

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

## Cómo trabajamos en equipo (Team Create)

Todos están en el mismo mundo de Studio. **Rojo lo corre una sola persona** (la del lobby) con
`rojo serve codigo.project.json`. Rojo reescribe solo `ReplicatedStorage.Shared`, `ServerScriptService.Server` y
`StarterPlayerScripts.Client`: **lo que se haga a mano ahí dentro se borra**. Todo lo demás es del equipo y Rojo no lo toca.

| Quién | Dónde trabaja | Cómo |
|---|---|---|
| Lobby | `Workspace.Plaza` (piezas) + `src/` (código, con Rojo) | Studio + editor |
| Cada juego | `ReplicatedStorage.Juegos.<Nombre>` (su código) + `Workspace.Zonas.<Nombre>` (su mapa) | Solo Studio |

**Una vez (lo hace la persona del lobby):**
1. Con Rojo conectado, en la Command Bar de Studio (sin Play):
   `require(game.ServerScriptService.Server.Plaza).construir()` → la plaza queda como piezas que se ven y se editan.
2. Insert from File: `entregas/Juegos.rbxm` en ReplicatedStorage y `entregas/Zonas.rbxm` en Workspace
   (se generan con `plantillas/armar.sh`).

**Cada juego tiene su zona** de 160×160, lejos de la plaza, con `Inicio` (donde aparece el jugador al entrar)
y `Probar` (alfombra que arranca el juego):

| Juego | Módulo | Zona (centro) |
|---|---|---|
| El Mandadero | `Juegos.Mandadero` | (-600, 0, 0) |
| La Balanza | `Juegos.Balanza` | (0, 0, -600) |
| ¿Qué se esconde? | `Juegos.Escondido` | (0, 0, 600) |
| El Colado | `Juegos.Colado` | (-600, 0, 600) |
| El Mensajero | `Juegos.Mensajero` | (-600, 0, -600) |
| ¡El suelo es lava! | `src/client/Juegos/Lava.luau` (Rojo) | se arma solo en (600, 40, 0) |

**Probar solo tu juego:** en el Explorer seleccioná `Workspace > Zonas > <Tuyo>`, F (la cámara va ahí),
pestaña **Test → Play Here**, y pisá la alfombra `Probar`. Al terminar volvés al lado de la alfombra.
Cada plantilla explica arriba qué trae `ctx` (mensajes, preguntas, resultado, `ctx.reto(...)`); el ejemplo
completo es `src/client/Juegos/Lava.luau`.

**Para no pisarse:** cada quien edita solo su módulo y su zona. Construí con piezas en tu zona desde el editor
(se ve sin dar Play) y usá el código para lo que se mueve o cambia.

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
