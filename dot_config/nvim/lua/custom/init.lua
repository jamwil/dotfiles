-- Enable autoread
vim.opt.autoread = true

-- Enable swapfiles
vim.opt.swapfile = true

-- Clipboard
vim.opt.clipboard = ""

-- Indenting
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- Scrolling
vim.opt.scrolloff = 15

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Wrapping
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- Will create actual line breaks
    vim.opt_local.textwidth = 80
  end,
})

-- Treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99

-- Auto format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format { bufnr = args.buf }
  end,
})

-- Session save and restore items
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,localoptions"

-- GUI specific
if vim.loop.os_uname().sysname == "Windows_NT" then
  local powershell_options = {
    shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell",
    shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
    shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
    shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
    shellquote = "",
    shellxquote = "",
  }

  for option, value in pairs(powershell_options) do
    vim.opt[option] = value
  end
end

-- Neovide specific
vim.g.neovide_cursor_animation_length = 0.01
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_scroll_animation_length = 0.05
vim.g.neovide_input_macos_option_key_is_meta = "both"

-- nvy specific
if vim.g.nvy == 1 then
  vim.o.guifont = "Hack Nerd Font:h10"
end
