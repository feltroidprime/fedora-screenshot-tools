# fedora-screenshot-tools

Screenshot productivity tools for Fedora GNOME/Wayland. Take a screenshot with the native GNOME tool, then send it to **Claude Code** for AI processing (OCR, analysis) or to any device on your **Tailscale** network.

## How it works

1. **Print Screen** — take a screenshot with GNOME's built-in tool (saved to clipboard)
2. **Ctrl+Shift+Print** — choose what to do with it:
   - Send to **Claude Code** — AI extracts text, answers questions about the image
   - Send to a **Tailscale device** — auto-detected, sent via scp to `~/Downloads/<hostname>/`

## Install

```bash
git clone https://github.com/feltroidprime/fedora-screenshot-tools.git
cd fedora-screenshot-tools
bash install.sh
```

The installer:
- Symlinks scripts to `~/bin` (edits in the repo take effect immediately)
- Checks required and optional dependencies
- Registers the GNOME keyboard shortcut

To uninstall:
```bash
bash install.sh --uninstall
```

## Requirements

**Required** (for core functionality):
- Fedora with GNOME on Wayland
- `zenity`, `notify-send`, `wl-copy`, `wl-paste`

**Optional** (features degrade gracefully without these):
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) — for AI image processing
- [Tailscale](https://tailscale.com/) + `ssh`/`scp` — for sending to other devices

## CLI usage

```bash
# Interactive dialog (same as Ctrl+Shift+Print)
claude-screenshot

# Quick mode: send to Claude with default prompt (extract text)
claude-screenshot --quick

# Quick mode with custom prompt
claude-screenshot --quick "Translate this text to English"

# Send directly to a Tailscale device
claude-screenshot --send mydevice
```

## License

MIT
