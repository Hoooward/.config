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
- `~/.zprofile` (host stub that sources the repo copy)
- `~/.zshenv` (host stub that sources the repo copy)
- `~/.tmux.conf` (host stub that sources the repo copy)
- `~/.claude/settings.json`
- `~/.cursor/mcp.json`
- `~/.codex` (symlinked to `codex/`, with only selected files tracked in Git)

## Local Overrides

Keep machine-specific settings out of the repo.

- `~/.zshrc`: host stub plus machine-specific shell additions after the `source` line
- `~/.zprofile`: host stub plus machine-specific login-shell additions if needed
- `~/.zshenv`: host stub plus machine-specific minimal env additions if needed
- `~/.tmux.conf`: host stub plus machine-specific tmux additions after the `source-file` line
- `~/.codex/config.toml`: lives inside the symlinked `codex/` directory on each machine, but is ignored by Git

## Deployment Model

- `zsh` and `tmux`: local host entry files stay normal files and only `source` the repo entrypoint, similar to the reference repo
- `claude` and `cursor/mcp.json`: managed via symlink
- `codex`: managed as a directory symlink like the reference repo, but `codex/.gitignore` keeps Git focused on `skills/`
- If the repo path changes, rerun `./scripts/bootstrap.sh` to rewrite the local stub files

Cursor desktop settings and keybindings are intentionally excluded because Cursor already syncs them.

## Notes

- Git uses an allowlist-style `.gitignore`: ignore everything by default, then explicitly unignore only the repo-owned files and directories.
- This repo intentionally does not sync auth, sessions, history, sqlite, caches, or extensions.
- `~/.codex/config.toml` and other Codex runtime files can exist in the symlinked repo working tree, but they stay untracked via `codex/.gitignore`.
- Do not put `[projects."/absolute/path"]` trust rules in `codex/config.toml` if you want that file to remain portable between machines.
- Cursor editor settings live in `~/Library/Application Support/Cursor/User/` on this macOS setup, but this repo does not manage them.
- `references/theniceboy-config/` is for comparison and selective copying only; it is not deployed by `bootstrap.sh`.
