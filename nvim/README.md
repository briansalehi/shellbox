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

### Per-machine step: build the fzf sorter

Run this once on every machine, after the first `nvim` start has installed the
plugins:

```sh
make -C ~/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim
```

`telescope-fzf-native` is a C library and `vim.pack` has no build step, so nvim
clones it without compiling `build/libfzf.so`. A `PackChanged` autocmd in
`lua/plugins/telescope.lua` runs `make` on install and update, but it can only fire
for changes that happen after it exists: a machine whose plugins were installed
earlier still needs the command above, once.

Nothing breaks without it. `load_extension('fzf')` is wrapped in `pcall`, so
telescope falls back to its own Lua sorter and prints the exact `make` command to
run at startup. If you never see that warning, the sorter is already built.

## Plugins

44 plugins managed by Neovim's built-in `vim.pack` (the list lives in `lua/plugins/init.lua`;
each plugin's setup lives in the matching module under `lua/plugins/`).

Two HTML pages in `docs/` cover the same ground in more detail: `docs/plugins.html` is
the full reference with every keymap, and `docs/changelog.html` is the dated log of
config changes. Open them in a browser. When a plugin is added or removed, update the
table below **and** `docs/plugins.html`; record the change in `docs/changelog.html`.

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
| `which-key.nvim` | Popup after 1s showing leader groups (`\f` find, `\m` cmake, `\d` debug, `\g` git, …) |

### Finding and moving around

| Plugin | Purpose |
| --- | --- |
| `telescope.nvim` + `telescope-fzf-native` | Fuzzy picker. `\ff` files, `\fg` grep, `\fb` buffers, `\fk` keymaps. fzf-native is a C library, so a `PackChanged` hook runs `make` for it on install and update |
| `telescope-ui-select` | Routes every `vim.ui.select` through telescope, so long prompts get a fuzzy filter instead of a numbered cmdline list. No keymap of its own |
| `harpoon` (v2) | Pin 4 files, jump with `\1`–`\4`. Faster than a picker for the files in flight |
| `flash.nvim` | Jump anywhere on screen by typing a label (`\s`), or select treesitter nodes (`\S`) |
| `oil.nvim` | File manager as an editable buffer (`-` or `\e`) — rename/delete by editing lines, `\ea` applies changes |
| `vim-lastplace` | Restores cursor to where the file was left |
| `auto-session` | Per-directory session save/restore (skips `~` and `/`) |
| `undotree` | Visual undo history, `\U` |

### Editing

| Plugin | Purpose |
| --- | --- |
| `nvim-cmp` + `cmp-nvim-lsp` + `cmp-buffer` | Completion, manual trigger only (`autocomplete = false`, `<C-Space>`) |
| `LuaSnip` + `cmp_luasnip` + `friendly-snippets` | Snippet engine and community snippet pack |
| `nvim-surround` | Add/change/delete surrounding quotes and brackets (`ys`, `cs`, `ds`) |
| `vim-illuminate` | Faintly highlights other occurrences of the symbol under the cursor. lsp (clangd) then regex — the treesitter provider needs nvim-treesitter master. `<A-n>` / `<A-p>` jump between them, `<A-i>` selects one |
| `mini.ai` | Smarter text objects (`ci(`, `va,`) across lines and treesitter nodes |
| `nvim-treesitter` | Syntax/indent parsing for c, cpp, lua, cmake, python, rust |
| `nvim-treesitter-context` | Pins the enclosing function/loop to the top of the window while scrolling. Capped at 3 lines, off in windows under 20 rows. `[c` jumps to the context line (falls through to the builtin in diff mode) |
| `conform.nvim` | Formatting via uncrustify for C/C++, `\uf` |
| `vim-maximizer` | Zoom one split to full screen. No config |
| `bullets.vim`, `vim-livedown` | Markdown list auto-numbering, live browser preview. No config |

### C/C++ workflow

| Plugin | Purpose |
| --- | --- |
| `cmake-tools.nvim` | Configure, build, run, test, presets, kits, build types — all on `\m*`. Cache options are not its job, so `\mv` (and `\mV` for advanced ones) lists `cmake -LH`, stages edits into the generate options `\mc` shows, and reconfigures once |
| `overseer.nvim` + `toggleterm.nvim` | Task runner and terminal that cmake-tools drives for its build/run panels |
| `clangd_extensions.nvim` | Inlay hints, AST view, source/header switch, type hierarchy, plus `\li` / `\lI` code actions |
| `nvim-dap` + `nvim-dap-ui` | Debugger on `\d*`. `plugins.cmake` must load first — dap re-registers cmake-tools' debug function |
| `nvim-dap-virtual-text` | Variable values shown at end of line while stepping, changed ones highlighted |
| `trouble.nvim` | Diagnostics, references, and symbols in a navigable list (`\x*`) |
| `todo-comments.nvim` | Highlights TODO/FIXME/HACK. `\xt` lists them in trouble, `]t` / `[t` jump |
| `nvim-bqf` | Preview pane in the native quickfix window, so `\mb` build errors and `grr` references can be read in context while scrolling the list |

### Git

| Plugin | Purpose |
| --- | --- |
| `neogit` | Magit-style git UI, `\gg` |
| `diffview.nvim` | Side-by-side diffs and file history, `\gd` / `\gh` |
| `gitsigns.nvim` | Live `+`/`~`/`-` markers for uncommitted lines. `]h` / `[h` walk hunks, `\gs` / `\gr` stage or reset one, `\gv` preview, `\gb` blame the line |

## Valgrind

Valgrind is not a plugin either. `lua/valgrind.lua` runs it, parses its report
and fills the quickfix list; `lua/plugins/valgrind.lua` holds the options and the
keymaps. It takes the binary, its arguments and its working directory straight
from cmake-tools' launch target, so there is nothing to configure per project —
pick a target with `\mL` and run.

Valgrind's own text report is the single artifact: it is what `\vr` shows
verbatim and what the quickfix is built from, so the thing read and the thing
parsed are the same bytes. Only one form can be produced per run — `--xml=yes`
*replaces* the text rather than duplicating it, and a `--log-file` given
alongside comes back empty — and the text is the one worth having, because it is
the format every tutorial and CI log speaks.

Three flags make it unambiguous: `--error-markers` has valgrind bracket each
error itself, `--fullpath-after=` gives absolute paths so the quickfix can
navigate, and `--log-file` keeps the report out of the program's own output.
After the `==pid==` marker the indent carries the structure — four spaces for a
frame, two for a secondary description, one for the message.

This is not vim's `errorformat`, which cannot do the job: a leak's top frame is
always valgrind's own `vg_replace_malloc.c`, and errorformat has no way to walk
down to the frame that is actually yours. Parsing the report here does, which is
what puts a leak on the line that allocated it. The error kind, which the text
states only in prose, comes from a table taken out of memcheck's `mc_errors.c`,
where the kind and its wording are printed from the same switch.

`\v` is a namespace per valgrind tool, so the rest have somewhere to go:
`\vm` memcheck, `\vh` helgrind, `\vd` drd, `\vc` callgrind, `\vg` cachegrind,
`\va` massif, `\vt` dhat. Only memcheck is wired up. `\vs` stops whichever tool
is running, `\vp` / `\vr` read whichever one ran last and `\vx` closes what they
opened, so those four sit at the top level. Helgrind and DRD emit the
report shape, so the filter, stack and suppression functions already take
the tool as an argument and will serve them unchanged.

| Keymap | Action |
| --- | --- |
| `\vmm` | Run memcheck on the launch target, errors into the quickfix list |
| `\vmb` | Build first, then run — valgrind never builds, so on its own it happily measures a stale binary |
| `\vml` | Run showing every leak kind, reachable and indirect included |
| `\vmo` | Toggle `--track-origins`, which says where an uninitialised value came from. Off by default: it halves memcheck's speed and costs at least 100MB |
| `\vmf` | Filter the list down to one error kind, or back to all |
| `\vmt` | Full stack of the error under the cursor: every frame, plus the allocation site and the origin stack under their own headings |
| `\vms` / `\vmS` | Append valgrind's generated suppression for this error, or for every error listed, to `valgrind.supp` |
| `\vs` | Stop the run in flight |
| `\vp` | Focus the output pane |
| `\vr` | Valgrind's own report, as it printed it |
| `\vx` | Close the windows valgrind opened |

The output pane opens on every run, as a 33% bottom split — the share the agent
terminals take — and focus stays on the code, so starting a run does not interrupt
what is being edited. `\vp` focuses it later. The program's output is streamed
into it as it arrives and follows the tail unless you have scrolled back. The
stack view and the raw report open the same size. This matters for a target that never exits on its own — a
server, say: valgrind reports nothing until the process ends, so without live
output such a run looks like it has done nothing at all. The way to use one is to
start it, exercise it, then `\vs`.

Valgrind runs 20-50x slower than native, so a run is long enough to want calling
off: `\vs` sends it SIGTERM, which valgrind treats as a normal shutdown — it
writes a complete report on the way out, so the errors found so far still reach
the quickfix list, titled `(stopped)`. A second run will not start over the top of
one already going, and a run still in flight is stopped when nvim quits rather
than left holding the target process open.

Each view owns one window. Pressing `\vp`, `\vr` or `\vmt` again focuses the
window it is already in rather than stacking another copy — `\vmt` on a second
error replaces the stack on screen, and `\vr` re-reads the report so a run still
going shows what it has written since.

`\vx` clears the workspace in one key: the output, the stack view, the raw report
and the quickfix window, but only when valgrind is what filled the quickfix — a
list from anywhere else is left alone. It closes the quickfix *window* and not the
list, so `\qo` brings the same errors back, and it keeps the output buffer so
`\vp` reopens the same scrollback rather than an empty pane.

Errors land in the quickfix list rather than a window of their own, so `\xq`
opens them in trouble and nvim-bqf previews each one in place. Still-reachable
blocks are marked `W` rather than `E`, since they are reported for information.
Suppressions are generated with `--gen-suppressions=all`; the `yes` form stops
and reads a confirmation from stdin for every error, which no editor job can
answer.

Saved logs get the `valgrind` filetype from a small autocmd on `*.valgrind` and
`valgrind*.log` — nvim ships `syntax/valgrind.vim` but no ftdetect for it.

## Agents

Coding agents are not a plugin. `lua/agents.lua` runs them as plain
`jobstart(argv, { term = true })` terminals in a 33% bottom split, keyed by
**(agent, git root)** so several agents stay alive side by side in the same
repository. `lua/plugins/agents.lua` holds the agent table and the keymaps; adding
one is a new entry plus a `map(...)` line.

| Keymap | Action |
| --- | --- |
| `\cc` / `\cC` | claude model picker, plain / continue last session |
| `\cr` / `\cR` | claude raw, no model and no appended prompt, plain / continue |
| `\cv` / `\cV` | claude, verbose / verbose and continue |
| `\cy` / `\cY` | claude, skip permissions / skip permissions and continue |
| `\cd` / `\cD` | claude reviewer, no editing tools, model picker, plain / continue |
| `\ca` | opencode model picker |
| `\co` / `\cO` | opencode, plain / continue last session |
| `\cs` / `\cS` | cursor model picker, plain / continue last chat |
| `\cu` / `\cU` | cursor, plain / continue last chat |
| `\cp` | pick or focus a running agent |
| `<M-r>` | redraw the terminal (`<C-l>` is not free: `<C-h/j/k/l>` leave the window) |

Model pickers are per-agent, because each agent takes a system prompt through
different flags and must never be offered each other's models. Claude lists
`~/.config/models/claude/*.md` and launches
`--model <name> --append-system-prompt-file <path>`. The reviewer under `\cd` is a
separate agent rather than a claude variant, so a review and a working session stay
alive side by side in one repository. It adds
`--disallowedTools Edit NotebookEdit` and a prompt forbidding writes through Bash,
Write, and subagents as well, carving out only its own memory files, artifact
scratch files, and build or installer output. `Write` stays enabled because those
carve-outs need it, and because Bash already makes the flag a hint rather than a
guarantee. Because claude refuses `--append-system-prompt` together with
`--append-system-prompt-file`, it inlines the picked model's prompt file and
appends the review rules to that text. Opencode lists what
`opencode models` reports (read once per session, it takes about a second) and
launches `--model <provider/model>`; opencode has no prompt-file flag, so a prompt
reaches it only as an agent definition in `~/.config/opencode/agent/*.md` whose
frontmatter `model:` names that model, and such a model is shown as
`ollama/qwen3:8b  [name]` and launched with `--agent <name>` as well. Cursor lists
what `cursor-agent --list-models` reports (cached the same way, and it exits
non-zero until `cursor-agent login` has run) and launches `--model <name>` with
nothing else: cursor takes its instructions from `.cursor/rules` and `AGENTS.md`,
so it has no prompt flag to pair with a model.

Opening or toggling an agent lands in insert mode, but nothing re-enters insert on
`WinEnter`, so leaving with `<C-\><C-n>` and switching windows keeps the scrollback
position.
