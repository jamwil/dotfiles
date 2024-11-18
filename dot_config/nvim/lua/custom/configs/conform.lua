local options = {
  lsp_fallback = false,

  formatters_by_ft = {
    lua = { "stylua" },

    javascript = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    markdown = { "prettier" },

    sh = { "shfmt" },

    python = { "ruff_format" },

    rust = { "rustfmt" },
  },

  formatters = {
    prettier = {
      prepend_args = { "--prose-wrap", "always" },
    },
  },
}

require("conform").setup(options)
