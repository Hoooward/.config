# hzht-config

Low-friction dotfiles repo for `agents` skills, `codex`, `cursor` AI assets, `claude`, `zsh`, and `tmux`.

## Structure

- `references/theniceboy-config/`: read-only reference clone of `theniceboy/.config`
- `zsh/`: shared zsh fragments
- `agents/`: shared universal skills source of truth
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
- `~/.agents` (symlinked to `agents/`, as the universal skills source)
- `~/.codex` (symlinked to `codex/`, with `config.toml` tracked and runtime state ignored)

## Local Overrides

Keep machine-specific settings out of the repo.

- `~/.zshrc`: host stub plus machine-specific shell additions after the `source` line
- `~/.zprofile`: host stub plus machine-specific login-shell additions if needed
- `~/.zshenv`: host stub plus machine-specific minimal env additions if needed
- `~/.tmux.conf`: host stub plus machine-specific tmux additions after the `source-file` line
- `~/.agents/skills`: add or import skills here when you want them synced by Git
- `~/.codex/config.toml`: lives inside the symlinked `codex/` directory and is tracked as shared Codex config

## Deployment Model

- `zsh` and `tmux`: local host entry files stay normal files and only `source` the repo entrypoint, similar to the reference repo
- `claude` and `cursor/mcp.json`: managed via symlink
- `agents`: managed as a directory symlink and stores the universal skills source of truth
- `codex`: managed as a directory symlink for shared config plus local runtime state, but skills no longer live here
- If the repo path changes, rerun `./scripts/bootstrap.sh` to rewrite the local stub files

Cursor desktop settings and keybindings are intentionally excluded because Cursor already syncs them.

## Notes

- Git uses an allowlist-style `.gitignore`: ignore everything by default, then explicitly unignore only the repo-owned files and directories.
- `agents/skills/` is the canonical skills directory for this repo; do not add new shared skills under `codex/skills/`.
- This repo intentionally does not sync auth, sessions, history, sqlite, caches, or extensions.
- `codex/config.toml` is tracked; other Codex runtime files can exist in the symlinked repo working tree, but stay untracked via the root `.gitignore`.
- Do not put `[projects."/absolute/path"]` trust rules in `codex/config.toml` if you want that file to remain portable between machines.
- Cursor editor settings live in `~/Library/Application Support/Cursor/User/` on this macOS setup, but this repo does not manage them.
- `references/theniceboy-config/` is for comparison and selective copying only; it is not deployed by `bootstrap.sh`.
