#!/usr/bin/env bash
# Instalador do Deck para macOS/Linux: baixa o executável da última release pública (sem Go, Node nem login),
# confere o SHA-256, coloca o Deck na lista de programas e abre o assistente `deck setup all`.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/thecodecodex/deck/main/install.sh | bash
#
# Variáveis: DECK_INSTALL_DIR (padrão ~/.deck/bin), DECK_NO_SETUP=1 (não abre o assistente),
# DECK_NO_APP=1 (não instala o programa na lista de aplicativos).
set -euo pipefail

REPO="thecodecodex/deck"
DEST_DIR="${DECK_INSTALL_DIR:-$HOME/.deck/bin}"

case "$(uname -s)" in
  Darwin) os="darwin" ;;
  Linux) os="linux" ;;
  *) echo "Sistema não suportado: $(uname -s). Use o install.ps1 no Windows." >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) arch="arm64" ;;
  x86_64 | amd64) arch="amd64" ;;
  *) echo "Arquitetura não suportada: $(uname -m)" >&2; exit 1 ;;
esac
if [ "$os" = "linux" ] && [ "$arch" = "arm64" ]; then
  echo "Ainda não há executável para Linux arm64." >&2
  exit 1
fi
asset="deck-${os}-${arch}"

command -v curl >/dev/null 2>&1 || { echo "curl não encontrado." >&2; exit 1; }

# a release mais nova do canal estável (v<ANO.MES.BUILD>); sem nenhuma, a mais nova do canal dev (-dev)
tags="$(curl -fsSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO/releases?per_page=30" \
  | grep -o '"tag_name": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')"
tag="$(printf '%s\n' "$tags" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)"
[ -n "$tag" ] || tag="$(printf '%s\n' "$tags" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-dev$' | head -1 || true)"
if [ -z "$tag" ]; then
  echo "Nenhuma release do Deck encontrada em github.com/$REPO." >&2
  exit 1
fi

base="https://github.com/$REPO/releases/download/$tag"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "Baixando $asset ($tag) de github.com/$REPO..."
curl -fSL --progress-bar "$base/$asset" -o "$tmp/$asset"
curl -fsSL "$base/checksums.txt" -o "$tmp/checksums.txt"

esperado="$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/checksums.txt")"
if command -v sha256sum >/dev/null 2>&1; then
  obtido="$(sha256sum "$tmp/$asset" | awk '{ print $1 }')"
else
  obtido="$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')"
fi
if [ -z "$esperado" ] || [ "$esperado" != "$obtido" ]; then
  echo "SHA-256 de $asset não confere com o checksums.txt da release: download corrompido ou adulterado." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
mv "$tmp/$asset" "$DEST_DIR/deck"
chmod +x "$DEST_DIR/deck"
# macOS: arquivo baixado pelo curl não ganha quarentena, mas um copiado do navegador ganharia
[ "$os" = "darwin" ] && xattr -d com.apple.quarantine "$DEST_DIR/deck" 2>/dev/null || true
echo "deck instalado em $DEST_DIR/deck ($("$DEST_DIR/deck" --version))."
echo

# o Deck na lista de programas (Launchpad/Spotlight no macOS, menu de aplicativos no Linux): abre o painel
if [ "${DECK_NO_APP:-}" != "1" ]; then
  "$DEST_DIR/deck" app instalar --yes || echo "Aviso: não foi possível instalar o programa do Deck (rode 'deck app instalar' depois)." >&2
  echo
fi

if [ "${DECK_NO_SETUP:-}" = "1" ]; then
  exit 0
fi

# </dev/tty: com o script vindo por pipe, o stdin do bash é o próprio script; o assistente precisa do terminal.
if [ -r /dev/tty ]; then
  "$DEST_DIR/deck" setup all "$@" </dev/tty
else
  "$DEST_DIR/deck" setup all "$@"
fi
