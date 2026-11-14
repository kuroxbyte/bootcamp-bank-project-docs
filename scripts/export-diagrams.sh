#!/usr/bin/env bash
# Exporta cada página de los diagramas draw.io a SVG, junto a su fuente:
# docs/diagrams/<tipo>/<tipo>.drawio -> docs/diagrams/<tipo>/<NN>-<página>.svg
# Requiere draw.io Desktop (brew install --cask drawio). Uso: scripts/export-diagrams.sh
set -euo pipefail
cd "$(dirname "$0")/../docs/diagrams"
DRAWIO=${DRAWIO:-/Applications/draw.io.app/Contents/MacOS/draw.io}

pages=$(python3 -I - <<'PY'
import re, unicodedata, xml.dom.minidom as md
for t in ['solution-design', 'sequence-diagrams', 'class-diagrams']:
    pages = md.parse(f'{t}/{t}.drawio').getElementsByTagName('diagram')
    for i, d in enumerate(pages, start=1):
        name = unicodedata.normalize('NFKD', d.getAttribute('name')).encode('ascii', 'ignore').decode()
        slug = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
        print(f'{t}\t{i}\t{i:02d}-{slug}')
PY
)

for type in solution-design sequence-diagrams class-diagrams; do
    find "$type" -name '*.svg' -delete
done
while IFS=$'\t' read -r type page slug; do
    # Las páginas se numeran desde 1.
    "$DRAWIO" --export --format svg --border 20 --page-index "$page" \
        --output "$type/$slug.svg" "$type/$type.drawio" > /dev/null
done <<< "$pages"
echo "$(find . -name '*.svg' | wc -l | tr -d ' ') SVG en docs/diagrams"
