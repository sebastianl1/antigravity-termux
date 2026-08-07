#!/data/data/com.termux/files/usr/bin/bash
#
# mirror.sh - Sincroniza la copia de seguridad de los binarios de Antigravity
#
# Descarga el tarball de wallentx/antigravity-cli-termux, lo verifica y lo
# sube como release asset a este mismo repositorio (sebastianl1/antigravity-termux),
# de modo que si wallentx desaparece, el instalador sigue funcionando con el mirror.
#
# Uso:
#   bash scripts/mirror.sh              Sincroniza con la última versión de wallentx
#   bash scripts/mirror.sh v1.1.10      Sincroniza una versión concreta
#
# Requisitos: gh autenticado, curl, tar, sha256sum.

set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO="sebastianl1/antigravity-termux"
ASSET="antigravity-termux-standalone.tar.gz"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cd "$DIR"

# 1. Determinar versión
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "==> Consultando última versión de wallentx..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/wallentx/antigravity-cli-termux/releases/latest" \
        | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
fi
[ -n "$VERSION" ] || { echo "ERROR: no se pudo determinar la versión."; exit 1; }
echo "    Versión: $VERSION"

URL="https://github.com/wallentx/antigravity-cli-termux/releases/download/${VERSION}/${ASSET}"
TARBALL="$WORK/$ASSET"

# 2. Descargar
echo "==> Descargando ${ASSET} (${VERSION})..."
curl -fsSL --proto =https "$URL" -o "$TARBALL"

# 3. Verificar integridad
echo "==> Verificando integridad..."
gzip -t "$TARBALL" || { echo "ERROR: gzip corrupto."; exit 1; }
[ "$(head -c 2 "$TARBALL" | od -An -tx1 | tr -d ' \n')" = "1f8b" ] || { echo "ERROR: no es gzip."; exit 1; }

tar -xzf "$TARBALL" -C "$WORK" agy agy.va39
[ "$(head -c 4 "$WORK/agy" | od -An -tx1 | tr -d ' \n')" = "7f454c46" ] || { echo "ERROR: agy no es un binario ELF."; exit 1; }
SIZE=$(wc -c < "$WORK/agy.va39")
[ "$SIZE" -ge 100000000 ] || { echo "ERROR: agy.va39 demasiado pequeño ($SIZE bytes)."; exit 1; }

SHA=$(sha256sum "$TARBALL" | awk '{print $1}')
echo "    SHA256: $SHA"

# 4. Subir al release del propio repo
TAG="agy-${VERSION}"
echo "==> Subiendo a ${REPO}:${TAG}..."
if ! gh release view "$TAG" -R "$REPO" &>/dev/null; then
    gh release create "$TAG" -R "$REPO" \
        --title "Antigravity binaries mirror $VERSION" \
        --notes "Copia de seguridad del tarball de wallentx/antigravity-cli-termux $VERSION. SHA256: $SHA"
fi
gh release upload "$TAG" -R "$REPO" "$TARBALL" --clobber

# 5. Actualizar versions.json
echo "==> Actualizando versions.json..."
cat > "$DIR/versions.json" <<EOF
{
  "version": "$VERSION",
  "sha256": "$SHA",
  "urls": [
    "https://github.com/wallentx/antigravity-cli-termux/releases/download/${VERSION}/${ASSET}",
    "https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"
  ]
}
EOF

echo ""
echo "✔ Mirror sincronizado: $VERSION ($SHA)"
echo "  No olvides commitear y pushear versions.json si cambió:"
echo "    git add versions.json && git commit -m \"mirror: actualizar a $VERSION\" && git push"
