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
  info "Installing recommended GNOME Shell extensions..."

  # Try gext (python-gnome-extensions-cli) first, then fall back to
  # gnome-shell-extension-installer, then warn the user.
  if command -v gext &>/dev/null; then
    info "Using gext..."
    gext install user-themes@gnome-shell-extensions.gcampax.github.com   || warn "user-themes install failed"
    gext install dash-to-dock@micxgx.gmail.com                           || warn "dash-to-dock install failed"
    gext install blur-my-shell@aunetx                                     || warn "blur-my-shell install failed"

  elif command -v gnome-shell-extension-installer &>/dev/null; then
    info "Using gnome-shell-extension-installer..."
    gnome-shell-extension-installer 19   --yes || warn "user-themes install failed"
    gnome-shell-extension-installer 307  --yes || warn "dash-to-dock install failed"
    gnome-shell-extension-installer 3193 --yes || warn "blur-my-shell install failed"

  else
    # Download the installer script on the fly
    warn "Neither gext nor gnome-shell-extension-installer found."
    info "Attempting to download gnome-shell-extension-installer..."
    local installer_tmp
    installer_tmp="$(mktemp)"
    if curl -fsSL \
        "https://raw.githubusercontent.com/brunelli/gnome-shell-extension-installer/master/gnome-shell-extension-installer" \
        -o "$installer_tmp"; then
      chmod +x "$installer_tmp"
      "$installer_tmp" 19   --yes || warn "user-themes install failed"
      "$installer_tmp" 307  --yes || warn "dash-to-dock install failed"
      "$installer_tmp" 3193 --yes || warn "blur-my-shell install failed"
      rm -f "$installer_tmp"
    else
      warn "Could not download installer. Install extensions manually:"
      warn "  user-themes  → https://extensions.gnome.org/extension/19/"
      warn "  dash-to-dock → https://extensions.gnome.org/extension/307/"
      warn "  blur-my-shell→ https://extensions.gnome.org/extension/3193/"
    fi
  fi

  # Enable the extensions (non-fatal if the shell isn't running / is Wayland)
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
