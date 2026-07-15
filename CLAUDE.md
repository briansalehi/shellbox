# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Shellbox is a personal dotfiles + shell-utilities repo (Fedora-oriented, but scripts detect
distro/OS at runtime). It has **two independent deployment mechanisms** — knowing which one a
given directory uses is the key to working here:

1. **`make`-installed** (`scripts/`, `aliases/`, `services/` + `systemd/`) — copied into place.
2. **Symlink-deployed** (`bash/`, `nvim/`, `tmux/`, `mutt/`, `msmtp/`, `ssh/`, `llvm/`) — the
   home-directory config path is a symlink back into this repo, so **editing a file here edits
   the live config directly**. E.g. `~/.bashrc → bash/bashrc`, `~/.config/nvim → nvim/`,
   `~/.tmux.conf → tmux/tmux.conf`. There is no install step for these; changes take effect on
   next shell/app start.

## Commands

- `make` (or `make help`) — list all installable targets (generated dynamically from the
  contents of `scripts/`, `aliases/`, `services/`).
- `make all` — install every script + alias.
- `make <name>` — install a single script/alias/service by filename (e.g. `make clip`,
  `make task`, `make ninja-maintenance`).
- `make test` — **the only lint/test**: runs `shellcheck` over `scripts/*`, `aliases/*`,
  `services/*`. Run this after editing any shell file.

Install destinations: scripts → `/usr/local/bin`; aliases → `~/.bash_tools/` (sourced by a
`for tool in ~/.bash_tools/*; do source $tool; done` loop in `bashrc`); services → `/usr/local/bin`
plus their paired `systemd/<name>.service` + `.timer` → `/usr/lib/systemd/system/`.

Adding a new script/alias/service requires **no Makefile edit** — the wildcard target list picks
up any new file in those directories automatically. A new `service` must ship a matching
`<name>.service` and `<name>.timer` in `systemd/`.

## Directory roles & conventions

- **`aliases/`** — each file defines a single bash *function* (filename = function name), meant to
  be sourced, not executed. Style is heavy on `awk`/`sed`/parameter-expansion; see
  `aliases/latest_version_of` for the house style.
- **`scripts/`** — standalone executables installed onto `PATH` (e.g. the `genesis*` Library Genesis
  downloaders, `clip`, `zget`, `package-version-manager`).
- **`services/` + `systemd/`** — self-contained "maintenance" scripts that **build a dev tool from
  source and keep it at the latest upstream release** (`clang`, `cmake`, `gcc`, `ninja`, `node`,
  `doxygen`, `plantuml`). Each: reads `PREFIX_PATH` (default `~/.local`), clones/pulls into
  `$PREFIX_PATH/src`, checks out the newest matching tag, and bootstraps/builds/installs. They
  share a common idiom — ANSI color helpers (`error`/`notice`/`success`/`code`) and a
  `window_stream` function that renders a fixed-height scrolling progress pane. The `.service` is
  `Type=oneshot`; the `.timer` runs `OnCalendar=Daily Persistent=true`.
- **`nvim/`** — `init.lua` just `require`s three modules under `nvim/lua/`: `options`, `plugins`,
  `lsp`. Plugins use Neovim's **native package manager** (`nvim/nvim-pack-lock.json`, plugins under
  `~/.local/share/nvim/site/pack/…`), **not** lazy.nvim/packer. `plugins.lua` is the large file:
  plugin setup + the `<leader>m` cmake-tools keymap group + ESP-IDF helpers (`:IdfActivate`,
  `:IdfSetPort`). Leader key is `\`.
- **`mutt/`, `msmtp/`** — neomutt + msmtp mail config (build/config flags for neomutt are in the
  README). Note `~/.config/mutt` may point at a sibling `shellbox-work` repo, not this one.

## Notes

- Git remote is `github` (`git@github.com:briansalehi/shellbox.git`); default branch is `master`.
- `README.md` holds the Fedora package list and the from-source build flags for neomutt and LLVM.
