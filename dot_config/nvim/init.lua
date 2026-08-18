-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- Options
-- Gutter
vim.opt.number = true
vim.opt.signcolumn = "yes"

-- Mouse
vim.opt.mouse = "a"

-- File handling
vim.opt.autoread = true
vim.opt.swapfile = true

-- Clipboard (intentionally empty — explicit yank to + register)
vim.opt.clipboard = ""

-- Scrolling
vim.opt.scrolloff = 10

-- Indenting (default 4-space)
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.breakindent = true
vim.opt.expandtab = true

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Update time
vim.opt.updatetime = 250

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Whitespace display
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Cursor
vim.opt.cursorline = true

-- Substitution preview
vim.opt.inccommand = "split"

-- Prompt to save
vim.opt.confirm = true

-- True color
vim.opt.termguicolors = true

-- Markdown hard-wrap at 80
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.textwidth = 80
  end,
})

-- Global keymaps
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map({ "n", "v" }, "j", "gj", { desc = "Move down by display line" })
map({ "n", "v" }, "k", "gk", { desc = "Move up by display line" })

-- GUI-specific blocks
if vim.g.neovide or vim.g.nvy == 1 then
  local is_mac = vim.uv.os_uname().sysname == "Darwin"
  local mod = is_mac and "D" or "C"
  vim.keymap.set("n", "<" .. mod .. "-s>", "<cmd>w<CR>")
  vim.keymap.set("v", "<" .. mod .. "-c>", '"+y')
  vim.keymap.set("n", "<" .. mod .. "-v>", '"+P')
  vim.keymap.set("i", "<" .. mod .. "-v>", "<C-r>+")
  vim.keymap.set("t", "<" .. mod .. "-v>", '<C-\\><C-n>"+Pa')
end

vim.g.neovide_cursor_animation_length = 0.01
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_scroll_animation_length = 0.05
vim.g.neovide_input_macos_option_key_is_meta = "both"
vim.g.neovide_title_background_color = "black"

if vim.g.nvy == 1 then
  vim.o.guifont = "Hack Nerd Font:h10"
end

-- Colorscheme
vim.o.background = "dark"