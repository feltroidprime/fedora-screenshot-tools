#!/bin/bash
# install.sh - Install/update fedora-screenshot-tools
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/bin"
KEYBINDING_BASE="org.gnome.settings-daemon.plugins.media-keys"

echo "=== fedora-screenshot-tools installer ==="

# 1. Ensure ~/bin exists
mkdir -p "$BIN_DIR"

# 2. Symlink scripts (so updates are instant)
for script in "$REPO_DIR"/bin/*; do
    name=$(basename "$script")
    chmod +x "$script"
    if [[ -L "$BIN_DIR/$name" ]]; then
        echo "  ↻ $name (updated symlink)"
        ln -sf "$script" "$BIN_DIR/$name"
    elif [[ -f "$BIN_DIR/$name" ]]; then
        echo "  ⚠ $BIN_DIR/$name exists as regular file, replacing with symlink"
        rm "$BIN_DIR/$name"
        ln -sf "$script" "$BIN_DIR/$name"
    else
        echo "  + $name"
        ln -sf "$script" "$BIN_DIR/$name"
    fi
done

# 3. Check dependencies
echo ""
echo "Checking dependencies..."
MISSING=()
for dep in zenity notify-send wl-copy wl-paste tailscale scp ssh gdbus; do
    if ! command -v "$dep" &>/dev/null; then
        MISSING+=("$dep")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "  ⚠ Missing: ${MISSING[*]}"
    echo "  Install with: sudo dnf install ${MISSING[*]}"
else
    echo "  ✓ All dependencies found"
fi

# Check claude
if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.claude/local/claude" ]]; then
    echo "  ⚠ claude CLI not found"
else
    echo "  ✓ claude CLI found"
fi

# 4. Setup GNOME keybinding for claude-screenshot
echo ""
echo "Setting up keyboard shortcut (Ctrl+Shift+Print)..."

EXISTING=$(gsettings get "$KEYBINDING_BASE" custom-keybindings 2>/dev/null)
CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/claude-screenshot/"

if echo "$EXISTING" | grep -q "claude-screenshot"; then
    echo "  ↻ Keybinding already registered, updating..."
else
    # Append to existing list
    if [[ "$EXISTING" == "@as []" ]]; then
        NEW_LIST="['$CUSTOM_PATH']"
    else
        NEW_LIST="${EXISTING%]*}, '$CUSTOM_PATH']"
    fi
    gsettings set "$KEYBINDING_BASE" custom-keybindings "$NEW_LIST"
    echo "  + Registered keybinding path"
fi

BIND_PATH="$KEYBINDING_BASE.custom-keybinding:$CUSTOM_PATH"
gsettings set "$BIND_PATH" name "Claude Screenshot"
gsettings set "$BIND_PATH" command "$REPO_DIR/bin/claude-screenshot"
gsettings set "$BIND_PATH" binding "<Control><Shift>Print"
echo "  ✓ Ctrl+Shift+Print → claude-screenshot"

echo ""
echo "=== Done ==="
echo "Usage: Impr Écran (capture) → Ctrl+Shift+Impr Écran (action)"
echo "CLI:   claude-screenshot --quick | claude-screenshot --send macbook"
