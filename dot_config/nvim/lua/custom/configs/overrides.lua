local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "htmldjango",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "python",
    "rust",
    "json",
    "terraform",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",
    "djlint",

    -- c/cpp stuff
    "clangd",
    "clang-format",

    -- python stuff
    "pyright",
    "ruff",
    "debugpy",

    -- rust stuff
    "rust-analyzer",
    "pest-language-server",

    -- terraform
    "terraform-ls",
    "tflint",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
    timeout = 1000,
  },

  view = {
    width = 40,
  },

  renderer = {
    special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md", "pyproject.toml", "tox.ini" },
    highlight_git = false,
    icons = {
      git_placement = "after",
      show = {
        git = true,
      },
      glyphs = {},
    },
  },
  filters = {
    git_ignored = false,
  },
}

M.nvterm = {
  terminals = {
    type_opts = {
      horizontal = { location = "rightbelow", split_ratio = 0.4 },
      vertical = { location = "rightbelow", split_ratio = 0.4 },
    },
  },
  behavior = {
    autoclose_on_quit = {
      enabled = true,
      confirm = true,
    },
    close_on_exit = true,
    auto_insert = true,
  },
}

return M
