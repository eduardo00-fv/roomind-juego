#!/usr/bin/env bash
# Revisa el juego sin abrir Studio: pruebas de lógica (Lune), lint (selene) y tipos (luau-lsp).
# Uso: roblox/pruebas/todo.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
for t in pruebas/*.luau; do lune run "$t"; done
selene src | tail -1
tipos="${XDG_CACHE_HOME:-$HOME/.cache}/mathforge/globalTypes.d.luau"
if [ ! -s "$tipos" ]; then
  mkdir -p "$(dirname "$tipos")"
  curl -sSL -o "$tipos" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
rojo sourcemap -o sourcemap.json >/dev/null
salida=$(luau-lsp analyze --defs="$tipos" --sourcemap=sourcemap.json --platform=roblox src 2>&1 | grep -E "Error|error" || true)
if [ -n "$salida" ]; then echo "$salida"; exit 1; fi
echo "ok: tipos"
