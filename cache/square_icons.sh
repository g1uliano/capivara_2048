#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p assets/images/inventory
for f in cache/removed_bg/*.png; do
  name=$(basename "$f")
  out="assets/images/inventory/$name"
  magick "$f" -trim +repage \
    -background none -gravity center -extent '%[fx:max(w,h)]x%[fx:max(w,h)]' \
    -resize 1024x1024 \
    "$out"
  identify "$out" | head -1
done
