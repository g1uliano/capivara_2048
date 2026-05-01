#!/usr/bin/env bash
set -euo pipefail
API_KEY=1ce1b106-8192-4ea8-b414-8a84dc9588b3
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/cache/removed_bg" "$ROOT/assets/images/inventory"

declare -a SRCS=(
  "design/Bomba verde Sucuri.png|bomb_sucuri.png"
  "design/Desfazer - Capivara.png|undo_capivara.png"
  "design/MICO LEÃO BOMBA 3X.png|bomb_mico_3x.png"
  "design/ONÇA DESFAZER 3X .png|undo_onca_3x.png"
)

cd "$ROOT"
for entry in "${SRCS[@]}"; do
  src="${entry%%|*}"
  name="${entry##*|}"
  out="cache/removed_bg/$name"
  echo "=== $src -> $out ==="
  curl -sSL -X POST "https://api.removal.ai/3.0/remove" \
    -H "Rm-Token: $API_KEY" \
    -F "image_file=@${src}" \
    -F "crop=1" \
    -F "get_file=1" \
    -o "$out"
  file "$out"
done
