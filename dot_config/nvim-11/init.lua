-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Nerd font
vim.g.have_nerd_font = true

-- Gutter
vim.opt.number = true
vim.opt.signcolumn = "yes"

-- Mouse
vim.opt.mouse = "a"

-- Enable autoread
vim.opt.autoread = true

-- Enable swapfiles
vim.opt.swapfile = true

-- Project-specific config
vim.o.exrc = true

-- Clipboard
vim.opt.clipboard = ""

-- Scrolling
vim.opt.scrolloff = 10

-- Indenting
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.breakindent = true
vim.opt.expandtab = true

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Offer to save
vim.opt.confirm = true

-- Filetype-based config overrides
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "html", "htmldjango", "css", "javascript", "terraform" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- Will create actual line breaks
    vim.opt_local.textwidth = 80
  end,
})

-- Keybindings
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Use <Tab> and <S-Tab> to navigate the completion menu
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

-- Use <CR> to confirm selection
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

-- Use <Esc> to abort but stay in insert mode
vim.keymap.set("i", "<Esc>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_replace_termcodes("<C-e>", true, true, true)
  else
    return "<Esc>"
  end
end, { expr = true })

-- LSP
vim.lsp.config["lua-language-server"] = {
  cmd = { "lua-language-server" },
  root_markers = { ".luarc.json" },
  filetypes = { "lua" },
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim", "Snacks" },
      },
    },
    workspace = {
      -- Make the server aware of Neovim runtime files
      library = vim.api.nvim_get_runtime_file("", true),
    },
    telemetry = {
      enable = false,
    },
  },
}

vim.lsp.enable({ "lua-language-server" })

-- Enable LSP auto-completion
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method("textDocument/completion") then
      local caps = client.server_capabilities
      if caps.completionProvider and caps.completionProvider.triggerCharacters then
        vim.list_extend(caps.completionProvider.triggerCharacters, { ".", ">", ":" })
      end
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })

      -- Retrigger completion manually on alphanumerics or underscore
      vim.api.nvim_create_autocmd("InsertCharPre", {
        buffer = ev.buf,
        callback = function()
          local char = vim.v.char
          if vim.fn.pumvisible() == 0 and char:match("[%w_]") then
            vim.defer_fn(function()
              vim.lsp.completion.get()
            end, 0)
          end
        end,
      })
    end
  end,
})

-- Make autocompletion not annoying
vim.cmd("set completeopt+=noselect")

-- Rounded borders
vim.o.winborder = "rounded"

-- Virtual lines for diagnostics
vim.diagnostic.config({
  virtual_lines = {
    -- Only show virtual line diagnostics for the current cursor line
    current_line = true,
  },
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup plugins
require("lazy").setup({
  spec = {
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        bigfile = { enabled = true },
        explorer = { enabled = true },
        picker = { enabled = true },
      },
      keys = {
        {
          "<leader>e",
          function()
            Snacks.explorer()
          end,
          desc = "Toggle file explorer",
        },
        {
          "<leader><space>",
          function()
            Snacks.picker.smart()
          end,
          desc = "Smart Find Files",
        },
        {
          "<leader>,",
          function()
            Snacks.picker.buffers()
          end,
          desc = "Buffers",
        },
        {
          "<leader>/",
          function()
            Snacks.picker.grep()
          end,
          desc = "Grep",
        },
        {
          "<leader>:",
          function()
            Snacks.picker.command_history()
          end,
          desc = "Command History",
        },
        {
          "<leader>n",
          function()
            Snacks.picker.notifications()
          end,
          desc = "Notification History",
        },
      },
    },
    {
      "romgrk/barbar.nvim",
      lazy = false,
      dependencies = {
        "lewis6991/gitsigns.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      keys = {
        { "<tab>", "<Cmd>BufferNext<CR>", desc = "Next buffer" },
        { "<S-tab>", "<Cmd>BufferPrevious<CR>", desc = "Previous buffer" },
        { "<leader>x", "<Cmd>BufferClose<CR>", desc = "Close buffer" },
        { "<leader>=", "<Cmd>BufferMoveNext<CR>", desc = "Move buffer to next" },
        { "<leader>-", "<Cmd>BufferMovePrevious<CR>", desc = "Move buffer to previous" },
      },
    },
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
        options = { theme = "OceanicNext" },
      },
    },
    {
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      cmd = { "ConformInfo" },
      keys = {
        {
          "<leader>fm",
          function()
            require("conform").format({ async = true })
          end,
          desc = "Format buffer",
        },
      },
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          htmldjango = { "djlint" },
          markdown = { "prettier" },
          sh = { "shfmt" },
          python = { "ruff_format" },
          rust = { "rustfmt" },
          terraform = { "terraform_fmt" },
        },
        formatters = {
          stylua = {
            prepend_args = { "--indent-width", "2", "--indent-type", "Spaces" },
          },
          prettier = {
            prepend_args = { "--prose-wrap", "always" },
          },
          djlint = {
            prepend_args = { "--format-js", "--format-css", "--indent", "2", "--indent-css", "2", "--indent-js", "2" },
          },
        },
        lsp_fallback = false,
        notify_on_error = true,
        notify_no_formatters = true,
      },
    },
    {
      "hedyhli/outline.nvim",
      cmd = { "Outline", "OutlineOpen" },
      opts = {
        outline_window = {
          width = 50,
          relative_width = false,
        },
      },
      keys = {
        { "<leader>o", "<Cmd>Outline<CR>", "Outline" },
      },
    },
    {
      "m4xshen/autoclose.nvim",
      event = { "BufEnter" },
      opts = {
        options = {
          disabled_filetypes = { "text", "markdown" },
          disable_when_touch = true,
          pair_spaces = true,
          disable_command_mode = true,
        },
      },
    },
  },
  checker = { enabled = true },
})

-- GUI cmd key bindings
if vim.g.neovide or vim.g.nvy == 1 then
  if vim.loop.os_uname().sysname == "Darwin" then
    vim.keymap.set("n", "<D-s>", ":w<CR>")
    vim.keymap.set("v", "<D-c>", '"+y')
    vim.keymap.set("n", "<D-v>", '"+P')
    vim.keymap.set("i", "<D-v>", '<ESC>"+pa')
    vim.keymap.set("t", "<D-v>", '<C-\\><C-N>"+Pa')
  else
    vim.keymap.set("n", "<C-s>", ":w<CR>")
    vim.keymap.set("v", "<C-c>", '"+y')
    vim.keymap.set("n", "<C-v>", '"+P')
    vim.keymap.set("i", "<C-v>", '<ESC>"+pa')
    vim.keymap.set("t", "<C-v>", '<C-\\><C-N>"+Pa')
  end
end

-- Neovide specific
vim.g.neovide_cursor_animation_length = 0.01
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_scroll_animation_length = 0.05
vim.g.neovide_input_macos_option_key_is_meta = "both"
vim.g.neovide_title_background_color = "black"

-- nvy specific
if vim.g.nvy == 1 then
  vim.o.guifont = "Hack Nerd Font:h10"
end
