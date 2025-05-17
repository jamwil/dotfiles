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

-- Session options
vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,options"

-- Filetype-based config overrides
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "html", "htmldjango", "json", "css", "javascript", "terraform" },
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
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic quickfix list" })

vim.keymap.set("n", "<leader>n", "<cmd>enew<CR>", { desc = "buffer new" })

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("v", "<", "<gv", { desc = "Dedent line(s)" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent line(s)" })

vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set("n", "ra", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "ca", vim.lsp.buf.code_action, { desc = "Code action" })

-- lua-language-server
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
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
    telemetry = {
      enable = false,
    },
  },
}

-- rust-analyzer
vim.lsp.config["rust-analyzer"] = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "cargo.toml", ".git" },
}

-- ruff
vim.lsp.config["ruff"] = {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  settings = {},
}

-- pyright
vim.lsp.config["pyright"] = {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}

-- basedpyright
local function set_python_path(path)
  local clients = vim.lsp.get_clients({
    bufnr = vim.api.nvim_get_current_buf(),
    name = "basedpyright",
  })
  for _, client in ipairs(clients) do
    if client.settings then
      client.settings.python = vim.tbl_deep_extend("force", client.settings.python or {}, { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
    end
    client.notify("workspace/didChangeConfiguration", { settings = nil })
  end
end

vim.lsp.config["basedpyright"] = {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(0, "LspPyrightSetPythonPath", set_python_path, {
      desc = "Reconfigure basedpyright with the provided python path",
      nargs = 1,
      complete = "file",
    })
  end,
}

-- Enable LSPs
vim.lsp.enable({ "lua-language-server", "rust-analyzer", "ruff", "basedpyright" })

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
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      lazy = false, -- neo-tree will lazily load itself
      opts = {
        source_selector = {
          winbar = true,
          statusline = false,
        },
      },
      keys = {
        { "<leader>e", "<Cmd>Neotree<CR>", desc = "Focus neo-tree" },
        { "<C-n>", "<Cmd>Neotree toggle<CR>", desc = "Toggle neo-tree" },
      },
    },
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        bigfile = { enabled = true },
        picker = {
          enabled = true,
        },
        rename = { enabled = true },
      },
      keys = {
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
        {
          "<leader>mv",
          function()
            Snacks.rename.rename_file()
          end,
          desc = "LSP-enabled Rename",
        },
      },
    },
    {
      "lewis6991/gitsigns.nvim",
      opts = {
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              gitsigns.nav_hunk("next")
            end
          end, { desc = "Jump to next git [c]hange" })

          map("n", "[c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              gitsigns.nav_hunk("prev")
            end
          end, { desc = "Jump to previous git [c]hange" })

          -- Actions
          -- visual mode
          map("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "git [s]tage hunk" })
          map("v", "<leader>hr", function()
            gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "git [r]eset hunk" })
          -- normal mode
          map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
          map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
          map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
          map("n", "<leader>hu", gitsigns.stage_hunk, { desc = "git [u]ndo stage hunk" })
          map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
          map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
          map("n", "<leader>hb", gitsigns.blame_line, { desc = "git [b]lame line" })
          map("n", "<leader>hd", gitsigns.diffthis, { desc = "git [d]iff against index" })
          map("n", "<leader>hD", function()
            gitsigns.diffthis("@")
          end, { desc = "git [D]iff against last commit" })
          -- Toggles
          map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
          map("n", "<leader>tD", gitsigns.preview_hunk_inline, { desc = "[T]oggle git show [D]eleted" })
        end,
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
        options = { theme = "auto" },
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
          json = { "prettier" },
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
      cmd = { "Outline", "OutlineOpen", "OutlineFocusOutline" },
      opts = {
        outline_window = {
          width = 50,
          relative_width = false,
        },
      },
      keys = {
        { "<leader>o", "<Cmd>OutlineOpen<CR><Cmd>OutlineFocusOutline<CR>", "Focus outline" },
      },
    },
    {
      "m4xshen/autoclose.nvim",
      event = { "InsertEnter" },
      opts = {
        options = {
          disabled_filetypes = { "text", "markdown" },
          disable_when_touch = true,
          pair_spaces = true,
          disable_command_mode = true,
        },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      main = "nvim-treesitter.configs",
      opts = {
        ensure_installed = {
          "bash",
          "c",
          "css",
          "diff",
          "html",
          "htmldjango",
          "javascript",
          "json",
          "lua",
          "luadoc",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "rust",
          "terraform",
          "toml",
          "typescript",
          "vim",
          "vimdoc",
          "yaml",
        },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "ruby" },
        },
        indent = { enable = true, disable = { "ruby" } },
      },
    },
    {
      "saghen/blink.cmp",
      dependencies = { "rafamadriz/friendly-snippets" },
      version = "1.2.0",
      opts = {
        keymap = { preset = "enter" },
        appearance = {
          nerd_font_variant = "mono",
        },
        completion = {
          documentation = { auto_show = false },
          list = { selection = { preselect = true, auto_insert = false } },
        },
        signature = { enabled = true, window = { show_documentation = false } },
        sources = {
          default = { "lsp", "path", "snippets" },
          providers = {
            path = {
              opts = {
                get_cwd = function(_)
                  return vim.fn.getcwd()
                end,
              },
            },
          },
        },
        fuzzy = { implementation = "prefer_rust_with_warning" },
      },
      opts_extend = { "sources.default" },
    },
    {
      "sindrets/diffview.nvim",
      cmd = { "Diffview", "DiffviewOpen", "DiffviewFileHistory" },
      opts = {
        view = {
          merge_tool = {
            layout = "diff3_mixed",
          },
        },
      },
      keys = {
        { "<leader>dv", "<cmd>DiffviewOpen<CR>" },
        { "<leader>dh", "<cmd>DiffviewFileHistory<CR>" },
      },
    },
    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      opts = {
        suggestion = {
          auto_trigger = false,
          keymap = {
            accept = "<M-\\>",
            accept_word = "<M-'>",
            accept_line = "<M-;>",
            dismiss = "<C-]>",
            next = "<M-]>",
          },
        },
      },
    },
    {
      "CopilotC-Nvim/CopilotChat.nvim",
      dependencies = {
        { "zbirenbaum/copilot.lua" },
        { "nvim-lua/plenary.nvim", branch = "master" },
      },
      cmd = { "CopilotChat", "CopilotChatOpen" },
      event = "InsertEnter",
      opts = {
        allow_insecure = true,
        model = "gpt-4.1",
        chat_autocomplete = true,
        window = {
          width = 0.4,
        },
        selection = function(source)
          local select = require("CopilotChat.select")
          return select.visual(source) or select.buffer(source)
        end,
      },
      keys = {
        { "<leader>ll", "<cmd>CopilotChatOpen<CR>", "n" },
        { "<leader>ll", "<cmd>CopilotChatOpen<CR>", "v" },
      },
    },
    {
      "folke/persistence.nvim",
      event = "BufReadPre",
      opts = {},
      keys = {
        {
          "<leader>sr",
          function()
            require("persistence").load()
          end,
        },
      },
    },
    {
      "linux-cultist/venv-selector.nvim",
      branch = "regexp",
      opts = {
        picker = "auto",
      },
      event = "VeryLazy",
      keys = {
        { "<leader>vs", "<cmd>VenvSelect<cr>" },
        { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
      },
    },
    {
      "rebelot/kanagawa.nvim",
      lazy = false,
      priority = 1000,
    },
  },
  defaults = { version = "*" },
  checker = { enabled = true, notify = false },
  install = { colorscheme = { "kanagawa" } },
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

-- colorscheme
vim.opt.termguicolors = true
vim.cmd("colorscheme kanagawa-dragon")
