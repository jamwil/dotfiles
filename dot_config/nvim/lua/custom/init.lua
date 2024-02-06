-- Auto format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format { bufnr = args.buf }
  end,
})

-- Auto resize panes when resizing nvim window
-- Temporarily disabling for neovide
-- vim.api.nvim_create_autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

-- Session save and restore items
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- GUI specific
if vim.g.neovide then
  vim.o.guifont = "Hack Nerd Font:h13"
  vim.g.neovide_cursor_animation_length = 0.01
  vim.g.neovide_cursor_animate_in_insert_mode = false
  vim.g.neovide_scroll_animation_length = 0.05
end
