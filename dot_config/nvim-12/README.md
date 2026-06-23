# Neovim Cheat Sheet

Custom keybindings for this config.

## Conventions

- **Leader**: `<Space>`
- **`g...` family**: navigation, LSP, and picker-style commands
- **`d...` family**: git/diff actions on the current change
- Some mappings are **buffer-local** and only appear when:
  - an **LSP** is attached
  - **gitsigns** is attached in a git-tracked file

---

## Picker / Search (`g` family)

| Key        | Action                |
| ---------- | --------------------- |
| `gf`       | Find files            |
| `gb`       | List open buffers     |
| `g/`       | Grep / project search |
| `g<Space>` | Resume last picker    |
| `g:`       | Command history       |

---

## Diagnostics

| Key         | Action                                                |
| ----------- | ----------------------------------------------------- |
| `gh`        | Show line diagnostics, or LSP hover if no diagnostics |
| `]d`        | Next diagnostic                                       |
| `[d`        | Previous diagnostic                                   |
| `g]`        | Next diagnostic                                       |
| `g[`        | Previous diagnostic                                   |
| `<leader>q` | Send diagnostics to location list                     |
| `<Esc>`     | Clear search highlight                                |

---

## LSP (`g` family, LSP-attached buffers only)

| Key  | Action                  |
| ---- | ----------------------- |
| `gd` | Go to definition        |
| `gD` | Go to declaration       |
| `gy` | Go to type definition   |
| `gI` | Go to implementation    |
| `gA` | Find references         |
| `gs` | Symbols in current file |
| `gS` | Symbols in workspace    |
| `cd` | Rename symbol           |
| `g.` | Code actions            |

### LSP in split

| Key       | Action                            |
| --------- | --------------------------------- |
| `<C-w>gd` | Definition in vertical split      |
| `<C-w>gD` | Type definition in vertical split |
| `<C-w>gy` | Type definition in vertical split |
| `<C-w>gI` | Implementation in vertical split  |
| `<C-w>gA` | References in vertical split      |

### Insert mode LSP / completion

| Key          | Action                  |
| ------------ | ----------------------- |
| `<C-x><C-o>` | Show completion menu    |
| `<C-x><C-l>` | Code actions            |
| `<C-x><C-z>` | Hide/cancel suggestions |

---

## Git changes (`gitsigns`)

These work on the current hunk/change. In diff mode, navigation/put/get-style
motions fall back to native diff behavior where appropriate.

| Key  | Action                                                       |
| ---- | ------------------------------------------------------------ |
| `]c` | Next git change                                              |
| `[c` | Previous git change                                          |
| `do` | Preview current change                                       |
| `dO` | Toggle staged state for current change                       |
| `du` | Stage current unstaged hunk, then jump to next unstaged hunk |
| `dU` | Unstage current staged hunk, then jump to next staged hunk   |
| `dp` | Restore/reset current change                                 |

### Extra git actions

| Key          | Action                             |
| ------------ | ---------------------------------- |
| `<leader>hs` | Stage hunk                         |
| `<leader>hr` | Reset hunk                         |
| `<leader>hS` | Stage buffer                       |
| `<leader>hR` | Reset buffer                       |
| `<leader>hp` | Preview hunk                       |
| `<leader>hb` | Blame line                         |
| `<leader>hd` | Diff against index                 |
| `<leader>hD` | Diff against last commit           |
| `<leader>tb` | Toggle current-line blame          |
| `<leader>tD` | Preview deleted / inline hunk view |

### Visual mode git actions

| Key          | Action               |
| ------------ | -------------------- |
| `<leader>hs` | Stage selected lines |
| `<leader>hr` | Reset selected lines |

---

## Buffers / Tabs

| Key                       | Action                    |
| ------------------------- | ------------------------- |
| `<Tab>`                   | Next buffer               |
| `<S-Tab>`                 | Previous buffer           |
| `<leader>x`               | Close buffer              |
| `<leader>=`               | Move buffer right         |
| `<leader>-`               | Move buffer left          |
| `<leader>bp`              | Pin buffer                |
| `<leader>bo`              | Close other buffers       |
| `<leader>bP`              | Close unpinned buffers    |
| `<leader>1` … `<leader>9` | Jump to buffer by ordinal |
| `<leader>n`               | New empty buffer          |

---

## Windows / Panes

| Key     | Action             |
| ------- | ------------------ |
| `<C-h>` | Focus left window  |
| `<C-j>` | Focus lower window |
| `<C-k>` | Focus upper window |
| `<C-l>` | Focus right window |

---

## File Tree

| Key         | Action          |
| ----------- | --------------- |
| `<leader>e` | Focus Neo-tree  |
| `<C-n>`     | Toggle Neo-tree |

---

## Formatting / Diff / Sessions

| Key          | Action                                        |
| ------------ | --------------------------------------------- |
| `<leader>fm` | Format buffer                                 |
| `<leader>dv` | Open Diffview                                 |
| `<leader>dh` | File history in Diffview                      |
| `<leader>sr` | Restore session for current working directory |

Sessions are automatically saved on exit.

---

## Visual mode editing

| Key | Action                          |
| --- | ------------------------------- |
| `<` | Indent left and keep selection  |
| `>` | Indent right and keep selection |

---

## Surrounds (`nvim-surround`)

| Key / Pattern | Action |
| ------------- | ------ |
| `ys{motion}{char}` | Add surround using a motion/text object |
| `S{char}` | Surround visual selection |
| `cs{old}{new}` | Change surround |
| `ds{char}` | Delete surround |
| `ysiw)` | Surround inner word: `word` → `(word)` |
| `ysa")` | Surround around quotes: `"word"` → `("word")` |
| `ysiwf` | Surround inner word with function: `word` → `func(word)` |
| `Sf` | Surround visual selection with function |

---

## Notes

- `gh`, `gd`, `gD`, `gy`, `gI`, `gA`, `gs`, `gS`, and `g.` are meant to mirror
  the Zed Vim-style `g` navigation family where practical.
- The picker commands also intentionally live under the same `g` prefix for
  consistency.
