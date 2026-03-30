#!/usr/bin/env bash
# WhiteSur Full Install
# Installs: GTK theme (dark, blue, darker), GNOME shell extensions,
#           Ventura wallpapers, WhiteSur icons, and WhiteSur cursors.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BLU='\033[0;34m'
BLD='\033[1m'
RST='\033[0m'

info()    { echo -e "${BLU}${BLD}[INFO]${RST} $*"; }
success() { echo -e "${GRN}${BLD}[OK]${RST}   $*"; }
warn()    { echo -e "${YLW}${BLD}[WARN]${RST} $*"; }
die()     { echo -e "${RED}${BLD}[ERR]${RST}  $*" >&2; exit 1; }

# ─── 0. UV ────────────────────────────────────────────────────────────────────
install_uv() {
  if command -v uv &>/dev/null; then
    info "uv already installed, skipping."
    return
  fi
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Make uv available in the current session
  export PATH="$HOME/.local/bin:$PATH"
  success "uv installed."
}

# ─── 1. GTK THEME ─────────────────────────────────────────────────────────────
install_gtk_theme() {
  info "Installing WhiteSur GTK theme (dark, blue, darker)..."
  local dir="$SCRIPT_DIR/whitesur-gtk-theme"
  [[ -d "$dir" ]] || die "whitesur-gtk-theme not found at $dir"
  cd "$dir"
  bash install.sh \
    --color dark \
    --theme blue \
    --darker
  success "GTK theme installed."
}

# ─── 2. GNOME SHELL EXTENSIONS ────────────────────────────────────────────────
# Extension IDs from the README:
#   19   – user-themes   (required to apply shell themes)
#   307  – dash-to-dock
#   3193 – blur-my-shell
install_extensions() {
  info "Installing gnome-extensions-cli via uv..."
  uv tool install gnome-extensions-cli --force
  export PATH="$HOME/.local/bin:$PATH"

  info "Installing recommended GNOME Shell extensions..."
  gext install 19 307 3193

  for ext_uuid in \
    "user-themes@gnome-shell-extensions.gcampax.github.com" \
    "dash-to-dock@micxgx.gmail.com" \
    "blur-my-shell@aunetx"; do
    gnome-extensions enable "$ext_uuid" 2>/dev/null && info "Enabled $ext_uuid" || true
  done

  success "GNOME Shell extensions done."
}

# ─── 3. VENTURA WALLPAPERS ────────────────────────────────────────────────────
install_wallpapers() {
  info "Installing Ventura wallpapers (all color variants, 4k)..."
  local dir="$SCRIPT_DIR/whitesur-wallpapers"
  [[ -d "$dir" ]] || die "whitesur-wallpapers not found at $dir"
  cd "$dir"
  bash install-wallpapers.sh --theme ventura
  success "Ventura wallpapers installed."
}

# ─── 4. ICON THEME ────────────────────────────────────────────────────────────
install_icons() {
  info "Installing WhiteSur icon theme (default/blue)..."
  local dir="$SCRIPT_DIR/whitesur-icon-theme"
  [[ -d "$dir" ]] || die "whitesur-icon-theme not found at $dir"
  cd "$dir"
  # Default accent is blue; no extra flags needed.
  bash install.sh
  success "Icon theme installed."
}

# ─── 5. CURSOR THEME ──────────────────────────────────────────────────────────
install_cursors() {
  info "Installing WhiteSur cursor theme..."
  local dir="$SCRIPT_DIR/whitesur-cursors"
  [[ -d "$dir" ]] || die "whitesur-cursors not found at $dir"
  cd "$dir"
  bash install.sh
  success "Cursor theme installed."
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────
echo
echo -e "${BLD}WhiteSur Full Installer${RST}"
echo "────────────────────────────────────────"

install_uv
echo
install_gtk_theme
echo
install_extensions
echo
install_wallpapers
echo
install_icons
echo
install_cursors
echo

echo -e "${GRN}${BLD}All done!${RST}"
echo
echo "Next steps:"
echo "  1. Open GNOME Tweaks → Appearance and set:"
echo "     • Shell theme : WhiteSur-Dark-blue"
echo "     • Applications: WhiteSur-Dark-blue"
echo "     • Icons        : WhiteSur"
echo "     • Cursor       : WhiteSur-cursors"
echo "  2. Set a Ventura wallpaper from ~/.local/share/backgrounds/"
echo "  3. You may need to log out / log back in for the shell theme to apply."
