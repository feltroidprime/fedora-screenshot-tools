# fedora-screenshot-tools

Screenshot productivity tools for Fedora GNOME (Wayland) with Claude Code and Tailscale integration.

## Project structure

```
bin/                  # Executable scripts (symlinked to ~/bin by install.sh)
  claude-screenshot   # Main tool: screenshot → Claude OCR or Tailscale send
install.sh            # Installer: symlinks, deps check, GNOME keybinding setup (supports --uninstall)
README.md             # Public-facing documentation
```

## Architecture

- Scripts live in `bin/`, `install.sh` symlinks them to `~/bin`
- GNOME custom keybindings trigger scripts directly from repo path
- Screenshots come from clipboard (`wl-paste`) after GNOME's native Print Screen
- Claude Code runs in `-p` (print) mode with `--model haiku` for speed/cost
- Tailscale peers are auto-detected at runtime via `tailscale status` — nothing hardcoded
- Files sent via scp to `~/Downloads/<hostname>/` on remote devices

## Conventions

- Bash scripts, `set -euo pipefail`
- No hardcoded machine names, IPs, or usernames — everything dynamic
- Notifications via `notify-send`, dialogs via `zenity`
- Results copied to clipboard via `wl-copy`
- No sudo required for install or usage
- Graceful degradation: features disabled when optional deps missing (tailscale, claude)

## Adding new tools

1. Create script in `bin/`
2. Run `install.sh` to symlink + optionally add keybinding
3. Keep scripts self-contained (no shared libs needed for now)
