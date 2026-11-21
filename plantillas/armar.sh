#!/usr/bin/env bash
# Arma los .rbxm para insertar en Studio: código (Shared/Server/Client), plantillas de juegos y zonas.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
mkdir -p entregas
for p in shared server client; do
  n="$(tr '[:lower:]' '[:upper:]' <<<"${p:0:1}")${p:1}"
  printf '{ "name": "%s", "tree": { "$path": "src/%s" } }\n' "$n" "$p" > "_$p.project.json"
  rojo build "_$p.project.json" -o "entregas/$n.rbxm"; rm "_$p.project.json"
done
( cd plantillas && rojo build juegos.project.json -o ../entregas/Juegos.rbxm && rojo build zonas.project.json -o ../entregas/Zonas.rbxm )
lune run plantillas/lava_modelo.luau
lune run plantillas/balanza_modelo.luau
lune run plantillas/portales.luau
ls entregas
# Studio (Vinegar, Flatpak) solo ve Documentos e Imágenes: copia ahí lo que se inserta a mano.
d="$(xdg-user-dir DOCUMENTS 2>/dev/null || echo "$HOME/Documents")/RooMind"
mkdir -p "$d" && cp entregas/{Lava,Balanza,Zonas,Juegos}.rbxm entregas/Portal_*.rbxm "$d/" && echo "copiado a $d"
