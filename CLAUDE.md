# fedora-screenshot-tools

Screenshot productivity tools for Fedora GNOME (Wayland) with Claude Code and Tailscale integration.

## Project structure

```
bin/                  # Executable scripts (symlinked to ~/bin by install.sh)
  claude-screenshot   # Main tool: screenshot → Claude OCR or Tailscale send
install.sh            # Installer: symlinks, deps check, GNOME keybinding setup
```

## Architecture

- Scripts live in `bin/`, `install.sh` symlinks them to `~/bin`
- GNOME custom keybindings trigger scripts directly from repo path
- Screenshots come from clipboard (`wl-paste`) after GNOME's native Print Screen
- Claude Code runs in `-p` (print) mode with `--model haiku` for speed/cost
- Tailscale peers are auto-detected via `tailscale status`
- Files sent via scp to `~/Downloads/<hostname>/` on remote devices

## User environment

- Fedora, GNOME, Wayland
- Tailscale network with peers: macbook, iphone, pixel5, asus
- Claude Code CLI at `~/.claude/local/claude`
- This machine's hostname: `fedora`

## Conventions

- Bash scripts, `set -euo pipefail`
- User-facing text in French, Claude prompts in English (token-optimized)
- Notifications via `notify-send`, dialogs via `zenity`
- Results copied to clipboard via `wl-copy`
- No sudo required for install or usage

## Adding new tools

1. Create script in `bin/`
2. Run `install.sh` to symlink + optionally add keybinding
3. Keep scripts self-contained (no shared libs needed for now)
