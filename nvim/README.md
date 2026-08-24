# Neovim Configuration

This is my personal nvim configuration.

## Setup

Follow these steps to install the latest Neovim on the system:

### Clone

```sh
git clone https://github.com/neovim/neovim
```

### Dependencies

Neovim has its third-parties internally managed:

```sh
cmake -S neovim/cmake.deps -B neovim/.deps -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo -D CMAKE_INSTALL_PREFIX=/usr/local
cmake --build neovim/.deps --parallel $(nproc)
```

One of the externally required tools is `tree-sitter-cli` managed by npm on Ubuntu, and managed by dnf on Fedora:

```sh
// Ubuntu
npm install -g tree-sitter-cli

// Fedora
sudo dnf install tree-sitter-cli
```

### Build & Install

```sh
cmake -S neovim -B neovim/build -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo -D CMAKE_INSTALL_PREFIX=/usr/local
cmake --build neovim/build --parallel $(nproc)
sudo cmake --install neovim/build
```

## Plugins

40 plugins managed by Neovim's built-in `vim.pack` (the list lives in `lua/plugins/init.lua`;
each plugin's setup lives in the matching module under `lua/plugins/`).

### Core / libraries

| Plugin | Purpose |
| --- | --- |
| `plenary.nvim` | Async/util library required by telescope, neogit, harpoon |
| `nvim-nio` | Async IO library required by nvim-dap-ui |
| `nvim-web-devicons` | Filetype icons for lualine, telescope, oil |

### Appearance

| Plugin | Purpose |
| --- | --- |
| `neovim-ayu` | Colorscheme (dark variant, custom `LineNr`) |
| `lualine.nvim` | Statusline: mode, branch, diff, diagnostics, path, encoding, position |
| `dashboard-nvim` | Start screen. Installed but never `setup()` — only a signcolumn autocmd |
| `which-key.nvim` | Popup after 1s showing leader groups (`\f` find, `\m` cmake, `\d` debug, `\g` git, …) |

### Finding and moving around

| Plugin | Purpose |
| --- | --- |
| `telescope.nvim` + `telescope-fzf-native` | Fuzzy picker. `\ff` files, `\fg` grep, `\fb` buffers, `\fk` keymaps |
| `harpoon` (v2) | Pin 4 files, jump with `\1`–`\4`. Faster than a picker for the files in flight |
| `flash.nvim` | Jump anywhere on screen by typing a label (`\s`), or select treesitter nodes (`\S`) |
| `oil.nvim` | File manager as an editable buffer (`-` or `\e`) — rename/delete by editing lines, `\ea` applies changes |
| `vim-lastplace` | Restores cursor to where the file was left |
| `auto-session` | Per-directory session save/restore (skips `~` and `/`) |
| `undotree` | Visual undo history, `\U` |
| `tagbar` | ctags symbol sidebar. No config, no keymap |

### Editing

| Plugin | Purpose |
| --- | --- |
| `nvim-cmp` + `cmp-nvim-lsp` + `cmp-buffer` | Completion, manual trigger only (`autocomplete = false`, `<C-Space>`) |
| `LuaSnip` + `cmp_luasnip` + `friendly-snippets` | Snippet engine and community snippet pack |
| `nvim-surround` | Add/change/delete surrounding quotes and brackets (`ys`, `cs`, `ds`) |
| `vim-commentary` | `gc` to comment |
| `mini.ai` | Smarter text objects (`ci(`, `va,`) across lines and treesitter nodes |
| `nvim-treesitter` | Syntax/indent parsing for c, cpp, lua, cmake, python, rust |
| `conform.nvim` | Formatting via uncrustify for C/C++, `\uf` |
| `vim-maximizer` | Zoom one split to full screen. No config |
| `bullets.vim`, `vim-livedown` | Markdown list auto-numbering, live browser preview. No config |

### C/C++ workflow

| Plugin | Purpose |
| --- | --- |
| `cmake-tools.nvim` | Configure, build, run, test, presets, kits, build types — all on `\m*` |
| `overseer.nvim` + `toggleterm.nvim` | Task runner and terminal that cmake-tools drives for its build/run panels |
| `clangd_extensions.nvim` | Inlay hints, AST view, source/header switch, type hierarchy, plus `\li` / `\lI` code actions |
| `nvim-dap` + `nvim-dap-ui` | Debugger on `\d*`. `plugins.cmake` must load first — dap re-registers cmake-tools' debug function |
| `trouble.nvim` | Diagnostics, references, and symbols in a navigable list (`\x*`) |

### Git

| Plugin | Purpose |
| --- | --- |
| `neogit` | Magit-style git UI, `\gg` |
| `diffview.nvim` | Side-by-side diffs and file history, `\gd` / `\gh` |

## Agents

Coding agents are not a plugin. `lua/agents.lua` runs them as plain
`jobstart(argv, { term = true })` terminals in a 33% bottom split, keyed by
**(agent, git root)** so several agents stay alive side by side in the same
repository. `lua/plugins/agents.lua` holds the agent table and the keymaps; adding
one is a new entry plus a `map(...)` line.

| Keymap | Action |
| --- | --- |
| `\cc` | claude (`\cC` continue, `\cv` / `\cV` verbose, `\cy` / `\cY` skip permissions) |
| `\co` / `\cO` | opencode, plain / continue last session |
| `\ca` | pick or focus a running agent |
| `\cs` / `\cS` | system-prompt picker, scoped to the agent being launched |
| `<M-r>` | redraw the terminal (`<C-l>` is not free: `<C-h/j/k/l>` leave the window) |

Each agent may declare a `prompts` block naming its prompt directory and the flags
to build from a pick. Claude reads `~/.config/models/*.md` and passes
`--model <name> --append-system-prompt-file <path>`; an agent without the block
says so instead of borrowing another agent's flags.

Opening or toggling an agent lands in insert mode, but nothing re-enters insert on
`WinEnter`, so leaving with `<C-\><C-n>` and switching windows keeps the scrollback
position.
