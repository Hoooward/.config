# hzht-config

Low-friction dotfiles repo for `codex`, `cursor` AI assets, `claude`, `zsh`, and `tmux`.

## Structure

- `references/theniceboy-config/`: read-only reference clone of `theniceboy/.config`
- `zsh/`: shared zsh fragments
- `claude/`, `codex/`, `cursor/`: tracked app config and AI assets
- `.zshrc`, `.zprofile`, `.zshenv`, `.tmux.conf`: host entry files
- `scripts/bootstrap.sh`: backup existing files and create symlinks
- `scripts/check.sh`: verify expected symlinks

## Quick Start

```bash
./scripts/bootstrap.sh
./scripts/check.sh
```

## Managed Paths

- `~/.zshrc` (host stub that sources the repo copy)
- `~/.zprofile`
- `~/.zshenv`
- `~/.tmux.conf`
- `~/.claude/settings.json`
- `~/.codex/config.toml`
- `~/.cursor/mcp.json`

## Local Overrides

Keep machine-specific settings out of the repo.

- `~/.zshrc.local`: proxies, absolute paths, local completions
- `~/.tmux.conf.local`: machine-specific tmux integrations
- `~/.codex/config.local.toml`: local notes only; merge manually if needed

## Deployment Model

- `zsh`: local `~/.zshrc` stays a normal file and only `source`s the repo entrypoint, similar to the reference repo
- `tmux`, `claude`, `codex`, `cursor/mcp.json`: managed via symlink
- If the repo path changes, rerun `./scripts/bootstrap.sh` to rewrite the local `~/.zshrc` stub

Cursor desktop settings and keybindings are intentionally excluded because Cursor already syncs them.

## Notes

- This repo intentionally does not sync auth, sessions, history, sqlite, caches, or extensions.
- Cursor editor settings live in `~/Library/Application Support/Cursor/User/` on this macOS setup, but this repo does not manage them.
- `references/theniceboy-config/` is for comparison and selective copying only; it is not deployed by `bootstrap.sh`.
