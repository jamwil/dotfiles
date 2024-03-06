local options = {
  lsp_fallback = false,

  formatters_by_ft = {
    lua = { "stylua" },

    javascript = { "prettier" },
    css = { "prettier" },
    html = { "djlint" },
    markdown = { "prettier" },

    sh = { "shfmt" },

    python = { "ruff_fix", "black" },

    rust = { "rustfmt" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 1000,
    lsp_fallback = false,
  },

  formatters = {
    prettier = {
      prepend_args = { "--prose-wrap", "always" },
    },
  },
}

require("conform").setup(options)
