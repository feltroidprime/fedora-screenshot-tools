#!/bin/bash
# install.sh - Install/update/uninstall fedora-screenshot-tools
# Usage: install.sh [--uninstall]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/bin"
KEYBINDING_BASE="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/claude-screenshot/"
BIND_SCHEMA="$KEYBINDING_BASE.custom-keybinding:$CUSTOM_PATH"
SHORTCUT="<Control><Shift>Print"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
err()   { echo -e "  ${RED}✗${NC} $1"; }
step()  { echo -e "\n${GREEN}==>${NC} $1"; }

# --- Environment checks ---

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        err "Cannot detect OS"; return 1
    fi
    source /etc/os-release
    if [[ "$ID" != "fedora" ]]; then
        warn "Designed for Fedora, detected $ID — may still work"
    fi
    if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
        err "Wayland session required (detected: ${XDG_SESSION_TYPE:-unknown})"
        return 1
    fi
    if [[ "${XDG_CURRENT_DESKTOP:-}" != *"GNOME"* ]]; then
        warn "Designed for GNOME, detected ${XDG_CURRENT_DESKTOP:-unknown}"
    fi
    info "Environment: $ID / ${XDG_CURRENT_DESKTOP:-unknown} / ${XDG_SESSION_TYPE:-unknown}"
}

check_deps() {
    local missing=()
    local optional_missing=()

    # Required
    for dep in zenity notify-send wl-copy wl-paste; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    # Optional
    for dep in tailscale scp ssh; do
        if ! command -v "$dep" &>/dev/null; then
            optional_missing+=("$dep")
        fi
    done

    # Claude CLI (special path)
    if command -v claude &>/dev/null || [[ -x "$HOME/.claude/local/claude" ]]; then
        info "claude CLI found"
    else
        optional_missing+=("claude")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        err "Missing required: ${missing[*]}"
        echo "    sudo dnf install ${missing[*]}"
        return 1
    fi
    info "Required dependencies OK"

    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        warn "Optional missing: ${optional_missing[*]} (some features disabled)"
    else
        info "Optional dependencies OK"
    fi
}

# --- Symlink management ---

install_scripts() {
    mkdir -p "$BIN_DIR"

    local count=0
    for script in "$REPO_DIR"/bin/*; do
        [[ -f "$script" ]] || continue
        local name
        name=$(basename "$script")
        chmod +x "$script"

        if [[ -L "$BIN_DIR/$name" ]] && [[ "$(readlink -f "$BIN_DIR/$name")" == "$(readlink -f "$script")" ]]; then
            info "$name (already linked)"
        elif [[ -L "$BIN_DIR/$name" ]] || [[ -f "$BIN_DIR/$name" ]]; then
            warn "$name: replacing existing file with symlink"
            ln -sf "$script" "$BIN_DIR/$name"
        else
            ln -sf "$script" "$BIN_DIR/$name"
            info "$name (installed)"
        fi
        count=$((count + 1))
    done

    if [[ $count -eq 0 ]]; then
        err "No scripts found in $REPO_DIR/bin/"
        return 1
    fi
}

remove_scripts() {
    for script in "$REPO_DIR"/bin/*; do
        [[ -f "$script" ]] || continue
        local name
        name=$(basename "$script")
        local target="$BIN_DIR/$name"

        if [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$script")" ]]; then
            rm "$target"
            info "Removed $name"
        elif [[ -e "$target" ]]; then
            warn "$target exists but is not our symlink, skipping"
        fi
    done
}

# --- GNOME keybinding ---

get_custom_keybindings() {
    gsettings get "$KEYBINDING_BASE" custom-keybindings 2>/dev/null || echo "@as []"
}

install_keybinding() {
    if ! command -v gsettings &>/dev/null; then
        warn "gsettings not found, skipping keybinding setup"
        return 0
    fi

    local existing
    existing=$(get_custom_keybindings)

    if ! echo "$existing" | grep -q "claude-screenshot"; then
        local new_list
        if [[ "$existing" == "@as []" ]]; then
            new_list="['$CUSTOM_PATH']"
        else
            new_list="${existing%]*}, '$CUSTOM_PATH']"
        fi
        gsettings set "$KEYBINDING_BASE" custom-keybindings "$new_list"
    fi

    gsettings set "$BIND_SCHEMA" name "Claude Screenshot"
    gsettings set "$BIND_SCHEMA" command "$REPO_DIR/bin/claude-screenshot"
    gsettings set "$BIND_SCHEMA" binding "$SHORTCUT"
    info "Ctrl+Shift+Print → claude-screenshot"
}

remove_keybinding() {
    if ! command -v gsettings &>/dev/null; then
        return 0
    fi

    local existing
    existing=$(get_custom_keybindings)

    if echo "$existing" | grep -q "claude-screenshot"; then
        # Remove our path from the list
        local new_list
        new_list=$(echo "$existing" \
            | sed "s|, '$CUSTOM_PATH'||g" \
            | sed "s|'$CUSTOM_PATH', ||g" \
            | sed "s|'$CUSTOM_PATH'||g")

        # Handle empty list
        if [[ "$new_list" == "[]" ]] || [[ "$new_list" == "[ ]" ]]; then
            new_list="@as []"
        fi

        gsettings set "$KEYBINDING_BASE" custom-keybindings "$new_list"
        gsettings reset "$BIND_SCHEMA" name 2>/dev/null || true
        gsettings reset "$BIND_SCHEMA" command 2>/dev/null || true
        gsettings reset "$BIND_SCHEMA" binding 2>/dev/null || true
        info "Keybinding removed"
    else
        info "No keybinding to remove"
    fi
}

# --- Main ---

echo "=== fedora-screenshot-tools ==="

if [[ "${1:-}" == "--uninstall" ]]; then
    step "Removing scripts"
    remove_scripts
    step "Removing keybinding"
    remove_keybinding
    echo -e "\n${GREEN}Uninstalled.${NC}"
    exit 0
fi

step "Checking environment"
check_os

step "Checking dependencies"
check_deps

step "Installing scripts to $BIN_DIR"
install_scripts

step "Setting up keyboard shortcut"
install_keybinding

echo -e "\n${GREEN}=== Installed ===${NC}"
echo "  Print Screen      → take screenshot (GNOME default)"
echo "  Ctrl+Shift+Print  → send to Claude or Tailscale device"
echo "  CLI: claude-screenshot --help"
