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

## New Device Setup

1. Clone this repo and run:

```bash
./scripts/bootstrap.sh
./scripts/check.sh
```

2. Install the local prerequisites that this repo assumes:
   - Node.js `v20.19+` with `npx` available
   - Chrome stable or newer if you want to use the `chrome-devtools` MCP server
   - Codex CLI if you use Codex from the terminal

3. Understand when `npx skills` is needed:
   - The shared skills in this repo are stored under `agents/skills/` and become `~/.agents/skills` after `bootstrap.sh`.
   - For the already-backed-up shared skills to exist on a new device, you do not need to separately install the `skills` package globally.
   - You do need `npx skills` when you want to import new third-party skill packages, update them, remove them, or create compatibility installs for other agents.

4. Useful `skills` commands:

```bash
# Install a public skill package globally
npx skills add -g vercel-labs/agent-skills

# Install from a git URL
npx skills add -g git@github.com:kepano/obsidian-skills.git

# List global skills
npx skills list -g

# Remove a skill
npx skills remove <skill-name> -g -y
```

5. Verify the tracked Chrome DevTools MCP entry in Codex:

```bash
codex mcp list
```

The shared Codex config in this repo already contains a `chrome-devtools` MCP entry, so on a new device you usually only need the local prerequisites above.

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

## Official Links

- Open agent skills CLI:
  - GitHub: https://github.com/vercel-labs/skills
  - Overview: https://vercel.com/changelog/introducing-skills-the-open-agent-skills-ecosystem
  - Guide: https://vercel.com/kb/guide/agent-skills-creating-installing-and-sharing-reusable-agent-context
- Chrome DevTools MCP:
  - GitHub: https://github.com/mcp/chromedevtools/chrome-devtools-mcp
  - Chrome for Developers overview: https://developer.chrome.com/blog/chrome-devtools-mcp
- Codex:
  - Product page: https://openai.com/codex
  - MCP docs: https://platform.openai.com/docs/docs-mcp
