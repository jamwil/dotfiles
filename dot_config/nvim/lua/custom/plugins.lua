local overrides = require "custom.configs.overrides"

---@type NvPluginSpec[]
local plugins = {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    opts = overrides.nvimtree,
  },

  {
    "NvChad/nvterm",
    opts = overrides.nvterm,
  },

  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "stevearc/conform.nvim",
    config = function()
      require "custom.configs.conform"
    end,
  },

  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    opts = {},
  },

  {
    "rmagatti/auto-session",
    lazy = false,
    config = function()
      require("auto-session").setup {
        auto_session_suppress_dirs = { "~/", "~/projects", "~/Downloads", "/" },
        pre_save_cmds = { "NvimTreeClose", "OutlineClose" },
        post_restore_cmds = { "NvimTreeOpen" },
      }
    end,
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
    },
    config = function()
      -- Configure python
      require("dap-python").setup "~/.pyenv/shims/python"
      require("dap-python").test_runner = "pytest"

      -- Configure dapui events
      local dap, dapui = require "dap", require "dapui"
      local nvimtree = require "nvim-tree.api"
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
        nvimtree.tree.close()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
        nvimtree.tree.close()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
        nvimtree.tree.open()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
        nvimtree.tree.open()
      end
      require("dapui").setup()
    end,
  },
}

return plugins
