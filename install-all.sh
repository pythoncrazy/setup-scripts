#!/usr/bin/env bash
# WhiteSur Full Install
# Installs: zsh + oh-my-zsh, pixi + global tools, GTK theme (dark, blue, darker),
#           GNOME shell extensions, Ventura wallpapers, WhiteSur icons and cursors.

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

# ─── 0a. ZSH + OH-MY-ZSH ──────────────────────────────────────────────────────
install_zsh() {
  if ! command -v zsh &>/dev/null; then
    info "zsh not found, installing..."
    sudo pacman -S --noconfirm zsh
  fi
  info "zsh found at $(command -v zsh)."

  # Switch the login shell to zsh
  if [[ "$SHELL" != "$(command -v zsh)" ]]; then
    info "Changing login shell to zsh..."
    chsh -s "$(command -v zsh)"
    success "Login shell changed to zsh."
  fi

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "oh-my-zsh already installed, skipping."
    return
  fi
  info "Installing oh-my-zsh..."
  # RUNZSH=no / CHSH=no: don't launch zsh or switch the login shell mid-script
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "oh-my-zsh installed."
}

# ─── 0b. STARSHIP ─────────────────────────────────────────────────────────────
install_starship() {
  if command -v starship &>/dev/null; then
    info "starship already installed, skipping."
    return
  fi
  info "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes

  # Wire starship into both shells
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [[ -f "$rc" ]] && ! grep -q 'starship init' "$rc"; then
      echo '' >> "$rc"
      echo 'eval "$(starship init '"$(basename "$rc" rc | tr -d '.')"')"' >> "$rc"
    fi
  done

  success "starship installed."
}

# ─── 0c. ATUIN ────────────────────────────────────────────────────────────────
install_atuin() {
  if command -v atuin &>/dev/null; then
    info "atuin already installed, skipping."
    return
  fi
  info "Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  success "atuin installed."
}

# ─── 0d. PIXI ─────────────────────────────────────────────────────────────────
install_pixi() {
  if ! command -v pixi &>/dev/null; then
    info "Installing pixi..."
    curl -fsSL https://pixi.sh/install.sh | sh
    # Make pixi available in the current session
    source "$HOME/.bashrc" 2>/dev/null || export PATH="$HOME/.pixi/bin:$PATH"
  else
    info "pixi already installed, skipping."
    export PATH="$HOME/.pixi/bin:$PATH"
  fi

  info "Installing global pixi tools (zellij gh btop)..."
  pixi global install zellij gh btop
  success "pixi tools installed."
}

# ─── 0e. UV ────────────────────────────────────────────────────────────────────
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
# Extension IDs:
#   19   – user-themes          (required to apply shell themes)
#   307  – dash-to-dock
#   3193 – blur-my-shell
#   3843 – just-perfection      (panel layout tweaks)
#   4412 – advanced-alt-tab     (window switcher)
#   1007 – window-is-ready-notification-remover
install_extensions() {
  info "Installing gnome-extensions-cli via uv..."
  uv tool install gnome-extensions-cli --force
  export PATH="$HOME/.local/bin:$PATH"

  info "Installing recommended GNOME Shell extensions..."
  gext install 19 307 3193 3843 4412 1007

  # gext doesn't run glib-compile-schemas; do it for every installed extension
  # that ships a schemas/ directory (blur-my-shell needs this).
  local ext_base="$HOME/.local/share/gnome-shell/extensions"
  for schema_dir in "$ext_base"/*/schemas; do
    [[ -d "$schema_dir" ]] && glib-compile-schemas "$schema_dir" 2>/dev/null || true
  done

  for ext_uuid in \
    "user-themes@gnome-shell-extensions.gcampax.github.com" \
    "dash-to-dock@micxgx.gmail.com" \
    "blur-my-shell@aunetx" \
    "just-perfection-desktop@just-perfection" \
    "advanced-alt-tab@G-dH.github.com"; do
    gnome-extensions enable "$ext_uuid" 2>/dev/null && info "Enabled $ext_uuid" || true
  done

  success "GNOME Shell extensions done."
}

# ─── 3. PANEL LAYOUT (macOS-like) ─────────────────────────────────────────────
configure_panel() {
  info "Configuring panel to match macOS layout via Just Perfection..."
  local schema="org.gnome.shell.extensions.just-perfection"
  local schema_dir="$HOME/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas"

  # Just Perfection schemas live in the extension dir, not the system path.
  jp() { GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set "$schema" "$@"; }

  # --- Items that belong in the macOS menu bar ---
  jp activities-button      true   # Apple logo (set via WhiteSur --shell -i apple)
  jp clock-menu             true   # Date & time
  jp quick-settings         true   # Control Center equivalent
  jp keyboard-layout        true   # Input source (shown on macOS when multiple)

  # Clock goes on the RIGHT  (macOS: Apple logo left → clock/status far right)
  # 0=center  1=right  2=left
  jp clock-menu-position    1

  # Boot to desktop, not the GNOME overview  (macOS behaviour)
  # 0=desktop  1=overview
  jp startup-status         0

  # Notifications appear top-right, like macOS
  # 0=top start  1=top center  2=top end  3=bottom start  4=bottom center  5=bottom end
  jp notification-banner-position 2

  # --- Items NOT present in the macOS menu bar ---
  jp panel-notification-icon false  # no notification dot in macOS menu bar
  jp power-icon              true   # show battery icon
  jp window-picker-icon      false  # no window-picker icon
  jp show-apps-button        false  # no app-grid button
  jp accessibility-menu      false  # hidden by default on macOS

  # Show battery percentage as text next to the icon
  gsettings set org.gnome.desktop.interface show-battery-percentage true

  success "Panel configured."
}

# ─── 4. KEYBINDINGS ───────────────────────────────────────────────────────────
configure_keybindings() {
  info "Remapping Alt+Tab to switch windows (not apps)..."

  # Disable the default app-switching Alt+Tab
  gsettings set org.gnome.desktop.wm.keybindings switch-applications   "[]"
  gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"

  # Bind Alt+Tab / Alt+Shift+Tab to switch individual windows
  gsettings set org.gnome.desktop.wm.keybindings switch-windows        "['<Alt>Tab']"
  gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

  success "Keybindings configured."
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

install_zsh
echo
install_starship
echo
install_atuin
echo
install_pixi
echo
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
configure_panel
echo
configure_keybindings
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
