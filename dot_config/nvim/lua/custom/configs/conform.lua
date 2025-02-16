local options = {
  lsp_fallback = false,

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
  },

  formatters = {
    prettier = {
      prepend_args = { "--prose-wrap", "always" },
    },
    djlint = {
      prepend_args = { "--format-js", "--format-css", "--indent", "2", "--indent-css", "2", "--indent-js", "2" },
    },
  },

  log_level = vim.log.levels.DEBUG,
  notify_on_error = true,
  notify_no_formatters = true,
}

require("conform").setup(options)
