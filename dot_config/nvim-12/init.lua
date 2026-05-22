-- 1. Enable loader
vim.loader.enable()

-- 2. Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- 3. Options
-- Gutter
vim.opt.number = true
vim.opt.signcolumn = "yes"

-- Mouse
vim.opt.mouse = "a"

-- File handling
vim.opt.autoread = true
vim.opt.swapfile = true

-- Project-local config (.nvim.lua/.nvimrc/.exrc in cwd or parent dirs; trusted files only)
vim.o.exrc = true

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

-- Sessions (used by built-in mksession; see section 11.8)
vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Floating window border
vim.o.winborder = "rounded"

-- True color
vim.opt.termguicolors = true

-- Native insert-mode completion (replaces blink.cmp)
vim.o.autocomplete = true
vim.o.completeopt = "menu,menuone,noselect,popup,fuzzy"
vim.o.pumheight = 12
vim.o.pumborder = "rounded"
vim.o.pummaxwidth = 60

-- Use ripgrep for :grep if available
if vim.fn.executable("rg") == 1 then
  vim.o.grepprg = "rg --vimgrep --smart-case"
  vim.o.grepformat = "%f:%l:%c:%m"
end

-- 4. Diagnostic configuration
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})

-- 5. Filetype autocmds
-- two-space indent overrides
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "html", "htmldjango", "json", "css", "javascript", "typescript", "terraform", "yaml", "toml" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Markdown hard-wrap at 80
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.textwidth = 80
  end,
})

-- 6. Global keymaps
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostics
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic location list" })

-- Smart K: prefer diagnostic float if there's a diagnostic on the line, else LSP hover
map("n", "K", function()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  if diagnostics and #diagnostics > 0 then
    vim.diagnostic.open_float({ scope = "cursor" })
  else
    vim.lsp.buf.hover()
  end
end, { desc = "Show diagnostics or hover" })

-- New buffer
map("n", "<leader>n", "<cmd>enew<CR>", { desc = "New buffer" })

-- Window focus
map("n", "<C-h>", "<C-w>h", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move focus to the upper window" })

-- Re-indent visual selection without losing it
map("v", "<", "<gv", { desc = "Indent line(s) left" })
map("v", ">", ">gv", { desc = "Indent line(s) right" })

-- Buffer navigation (bufferline.nvim)
map("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map("n", "<leader>x", function()
  require("snacks.bufdelete").delete()
end, { desc = "Close buffer" })

-- Reorder buffers
map("n", "<leader>=", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer right" })
map("n", "<leader>-", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer left" })

-- Pin / close-others
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin buffer" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close other buffers" })
map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<CR>", { desc = "Close unpinned buffers" })

-- Jump-to-ordinal (1-9)
for i = 1, 9 do
  map("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "Go to buffer " .. i })
end

-- Session restore (replaces persistence.nvim — see autocmd in section 11.8)
map("n", "<leader>sr", function()
  local f = vim.fn.stdpath("state") .. "/sessions/" .. vim.fn.getcwd():gsub("/", "%%") .. ".vim"
  if vim.fn.filereadable(f) == 1 then
    vim.cmd("source " .. vim.fn.fnameescape(f))
  else
    vim.notify("No session for cwd", vim.log.levels.WARN)
  end
end, { desc = "Restore session for cwd" })

-- 7. LSP server configs and vim.lsp.enable()
vim.lsp.config["lua-language-server"] = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim", "Snacks" } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

vim.lsp.config["rust-analyzer"] = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", ".git" },
}

vim.lsp.config["ruff"] = {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  settings = {},
}

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
}

vim.lsp.enable({ "lua-language-server", "rust-analyzer", "ruff", "basedpyright" })

-- 8. LspAttach autocmd
local code_action_sign_group = "lsp-code-action"
vim.fn.sign_define("LspCodeActionAvailable", { text = "+", texthl = "DiagnosticHint", numhl = "" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    local grp = vim.api.nvim_create_augroup("lsp-buffer-" .. ev.buf, { clear = false })

    -- Enable inlay hints if supported
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end

    -- Subtle sign when code actions are available at the cursor
    if client:supports_method("textDocument/codeAction") and not vim.b[ev.buf].lsp_code_action_signs then
      vim.b[ev.buf].lsp_code_action_signs = true
      local function clear_code_action_sign()
        vim.fn.sign_unplace(code_action_sign_group, { buffer = ev.buf })
      end

      local function update_code_action_sign()
        local mode = vim.api.nvim_get_mode().mode
        if mode:match("^[iRcv]") then
          clear_code_action_sign()
          return
        end

        local bufnr = ev.buf
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { diagnostics = vim.diagnostic.get(bufnr) }

        vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(results)
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          if vim.api.nvim_get_current_buf() ~= bufnr then
            clear_code_action_sign()
            return
          end

          local lnum = vim.api.nvim_win_get_cursor(0)[1]
          local has_actions = false
          for _, res in pairs(results or {}) do
            if res.result and not vim.tbl_isempty(res.result) then
              has_actions = true
              break
            end
          end

          clear_code_action_sign()
          if has_actions then
            vim.fn.sign_place(
              0,
              code_action_sign_group,
              "LspCodeActionAvailable",
              bufnr,
              { lnum = lnum, priority = 10 }
            )
          end
        end)
      end

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = grp,
        buffer = ev.buf,
        callback = update_code_action_sign,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
        group = grp,
        buffer = ev.buf,
        callback = clear_code_action_sign,
      })
    end

    -- Enable document highlight on CursorHold/CursorHoldI (per :h vim.lsp.buf.document_highlight())
    if client:supports_method("textDocument/documentHighlight") and not vim.b[ev.buf].lsp_document_highlight then
      vim.b[ev.buf].lsp_document_highlight = true
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = grp,
        buffer = ev.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = grp,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- 9. Helper functions (venv)
local uv = vim.uv

function _G.set_unix_venv(venv_path)
  local bin_path = venv_path .. "/bin"
  local python3 = bin_path .. "/python"
  if uv.fs_stat(bin_path) then
    local old_path = vim.env.PATH or os.getenv("PATH")
    if not old_path:find(bin_path, 1, true) then
      vim.env.PATH = bin_path .. ":" .. old_path
    end
    vim.env.VIRTUAL_ENV = venv_path
    if uv.fs_stat(python3) then
      vim.g.python3_host_prog = python3
    end
  end
end

function _G.set_windows_venv(venv_path)
  local scripts_path = venv_path .. "\\Scripts"
  local python3 = scripts_path .. "\\python.exe"
  if uv.fs_stat(scripts_path) then
    local old_path = vim.env.PATH or os.getenv("PATH")
    if not old_path:find(scripts_path, 1, true) then
      vim.env.PATH = scripts_path .. ";" .. old_path
    end
    vim.env.VIRTUAL_ENV = venv_path
    if uv.fs_stat(python3) then
      vim.g.python3_host_prog = python3
    end
  end
end

-- 10. Plugin manager bootstrap
vim.pack.add({
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-neo-tree/neo-tree.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/neovim-treesitter/treesitter-parser-registry",
  "https://github.com/neovim-treesitter/nvim-treesitter",
  "https://github.com/sindrets/diffview.nvim",
})

-- 11. Plugin setup calls
-- 11.1 Kanagawa (no setup needed for defaults)

-- 11.2 Neo-tree
require("neo-tree").setup({
  source_selector = { winbar = true, statusline = false },
  filesystem = { follow_current_file = { enabled = true } },
})
vim.keymap.set("n", "<leader>e", "<cmd>Neotree<CR>", { desc = "Focus neo-tree" })
vim.keymap.set("n", "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "Toggle neo-tree" })

-- 11.3 Bufferline
local function setup_bufferline()
  require("bufferline").setup({
    options = {
      mode = "buffers",
      numbers = "ordinal",
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      show_buffer_close_icons = false,
      show_close_icon = false,
      separator_style = "thin",
      always_show_bufferline = true,
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          text_align = "left",
          separator = true,
        },
      },
    },
  })
end

if vim.g.colors_name then
  setup_bufferline()
else
  vim.api.nvim_create_autocmd("ColorScheme", {
    once = true,
    callback = setup_bufferline,
  })
end

-- 11.4 Snacks
require("snacks").setup({
  bigfile = { enabled = true },
  picker = { enabled = true },
})

vim.keymap.set("n", "<C-p>", function()
  Snacks.picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>,", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>:", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })

-- 11.5 Gitsigns
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
    end

    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, "Jump to next git change")

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, "Jump to previous git change")

    map("v", "<leader>hs", function()
      gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "git stage hunk")
    map("v", "<leader>hr", function()
      gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "git reset hunk")
    map("n", "<leader>hs", gs.stage_hunk, "git stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "git reset hunk")
    map("n", "<leader>hS", gs.stage_buffer, "git Stage buffer")
    map("n", "<leader>hR", gs.reset_buffer, "git Reset buffer")
    map("n", "<leader>hp", gs.preview_hunk, "git preview hunk")
    map("n", "<leader>hb", gs.blame_line, "git blame line")
    map("n", "<leader>hd", gs.diffthis, "git diff against index")
    map("n", "<leader>hD", function()
      gs.diffthis("@")
    end, "git diff against last commit")
    map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle git blame line")
    map("n", "<leader>tD", gs.preview_hunk_inline, "Toggle git deleted")
  end,
})

-- 11.6 Conform
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    typescript = { "prettier" },
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
    stylua = { prepend_args = { "--indent-width", "2", "--indent-type", "Spaces" } },
    prettier = { prepend_args = { "--prose-wrap", "always" } },
    djlint = {
      prepend_args = { "--format-js", "--format-css", "--indent", "2", "--indent-css", "2", "--indent-js", "2" },
    },
  },
  lsp_fallback = false,
  notify_on_error = true,
  notify_no_formatters = true,
})

vim.keymap.set("n", "<leader>fm", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })

-- 11.7 Diffview
require("diffview").setup({
  view = { merge_tool = { layout = "diff3_mixed" } },
})
vim.keymap.set("n", "<leader>dv", "<cmd>DiffviewOpen<CR>", { desc = "Diffview open" })
vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory<CR>", { desc = "Diffview file history" })

-- 11.8 Sessions
local session_dir = vim.fn.stdpath("state") .. "/sessions"
vim.fn.mkdir(session_dir, "p")

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local f = session_dir .. "/" .. vim.fn.getcwd():gsub("/", "%%") .. ".vim"
    vim.cmd("mksession! " .. vim.fn.fnameescape(f))
  end,
})

-- 12. Treesitter FileType autocmd
require("nvim-treesitter").setup({})

local parsers = {
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
}
require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local d = ev.data
    if d and d.spec and d.spec.name == "nvim-treesitter" and d.kind == "update" then
      if not d.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      require("nvim-treesitter").update()
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
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
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo[0][0].foldmethod = "expr"
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.opt.foldlevelstart = 99

-- 13. GUI-specific blocks
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

-- 14. Colorscheme
pcall(vim.cmd.colorscheme, "kanagawa-dragon")
