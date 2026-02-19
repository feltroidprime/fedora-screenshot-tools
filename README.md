# fedora-screenshot-tools

Screenshot productivity tools for Fedora GNOME/Wayland. Take a screenshot with the native GNOME tool, then send it to **Claude Code** for AI processing (OCR, analysis) or to any device on your **Tailscale** network.

## How it works

1. **Print Screen** — take a screenshot with GNOME's built-in tool (saved to clipboard)
2. **Ctrl+Shift+Print** — choose what to do with it:
   - **Claude Code** — AI processes the image (extract text, translate, describe, etc.). Result is displayed and copied to clipboard.
   - **Tailscale device** — all reachable peers are auto-detected. The screenshot is sent via `scp` and the absolute remote path is copied to your clipboard so you can paste it directly in an SSH session.

Files are named `<hostname>_2026-02-19_16h45m30.png` and placed in `~/Downloads/<sender>/` on the remote device.

## Install

```bash
git clone https://github.com/feltroidprime/fedora-screenshot-tools.git
cd fedora-screenshot-tools
bash install.sh
```

The installer:
- Validates environment (Fedora, GNOME, Wayland)
- Checks required and optional dependencies
- Symlinks scripts to `~/bin` (edits in the repo take effect immediately)
- Registers the GNOME keyboard shortcut
- Is idempotent — safe to re-run after `git pull`

To uninstall:
```bash
bash install.sh --uninstall
```

## Requirements

**Required:**
- Fedora with GNOME on Wayland
- `zenity`, `notify-send`, `wl-copy`, `wl-paste`

**Optional** (features degrade gracefully):
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) — AI image processing
- [Tailscale](https://tailscale.com/) + `ssh`/`scp` — device sharing

## CLI usage

```bash
# Interactive dialog (same as Ctrl+Shift+Print)
claude-screenshot

# Quick mode: extract text with Claude (default prompt)
claude-screenshot --quick

# Quick mode with custom prompt
claude-screenshot --quick "Translate this text to English"

# Send to a specific Tailscale device
claude-screenshot --send mydevice

# Help
claude-screenshot --help
```

## How it's built

- Nothing is hardcoded — hostnames from `hostname`, peers from `tailscale status`
- Claude Code runs in non-interactive mode (`-p`) with Haiku for speed and cost
- Clipboard-based: grabs the image from `wl-paste` after GNOME's native screenshot
- Graceful degradation: only shows available actions (no Claude CLI = no Claude option, no Tailscale = no device list)

## License

MIT
