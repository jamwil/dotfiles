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
    config = function(_, opts)
      require("nvim-treesitter.install").compilers = { "clang" }
      dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    version = "v1.6",
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
    lazy = false,
    cmd = { "Outline", "OutlineOpen" },
    opts = {
      outline_window = {
        width = 50,
        relative_width = false,
      },
    },
  },

  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      auto_session_suppress_dirs = { "~/", "~/projects", "~/Downloads", "/" },
      pre_save_cmds = { "NvimTreeClose", "OutlineClose" },
      post_restore_cmds = { "NvimTreeOpen" },
      auto_restore = false,
      lazy_support = true,
      continue_restore_on_error = false,
      log_level = "info",
    },
  },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
  },

  {
    "mfussenegger/nvim-dap-python",
    config = function()
      local path = require("mason-registry").get_package("debugpy"):get_install_path()
      if vim.loop.os_uname().sysname == "Windows_NT" then
        require("dap-python").setup(path .. "/venv/Scripts/python")
      else
        require("dap-python").setup(path .. "/venv/bin/python")
      end
      require("dap-python").test_runner = "pytest"
    end,
  },

  {
    "rcarriga/nvim-dap-ui",
    config = function()
      local dap, dapui = require "dap", require "dapui"
      local nvimtree = require "nvim-tree.api"

      dap.listeners.before.attach.dapui_config = function()
        nvimtree.tree.close()
        dapui.open { reset = true }
      end
      dap.listeners.before.launch.dapui_config = function()
        nvimtree.tree.close()
        dapui.open { reset = true }
      end
      dap.listeners.before.event_terminated.dapui_config = function() end
      dap.listeners.before.event_exited.dapui_config = function() end
      require("dapui").setup {
        layouts = {
          {
            elements = {
              {
                id = "scopes",
                size = 0.45,
              },
              {
                id = "breakpoints",
                size = 0.1,
              },
              {
                id = "watches",
                size = 0.25,
              },
              {
                id = "stacks",
                size = 0.25,
              },
            },
            position = "left",
            size = 55,
          },
          {
            elements = {
              {
                id = "repl",
                size = 0.50,
              },
              {
                id = "console",
                size = 0.50,
              },
            },
            position = "bottom",
            size = 0.4,
          },
        },
      }
    end,
  },

  {
    "sindrets/diffview.nvim",
    lazy = false,
  },

  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = "Refactor",
    event = "BufEnter",
    opts = {
      prompt_func_return_type = {},
      prompt_func_param_type = {},
      printf_statements = {},
      print_var_statements = {},
      show_success_message = true,
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
      model = "claude-3.7-sonnet",
      chat_autocomplete = true,
      window = {
        width = 80,
      },
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-*",
        callback = function()
          vim.opt.completeopt = vim.opt.completeopt + "noinsert" + "noselect"
        end,
      })
      vim.api.nvim_create_autocmd("BufLeave", {
        pattern = "copilot-*",
        callback = function()
          vim.opt.completeopt = vim.opt.completeopt - "noinsert" - "noselect"
        end,
      })
    end,
  },

  {
    "L3MON4D3/LuaSnip",
    dependencies = "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip").config.set_config {
        history = true,
        updateevents = "TextChanged,TextChangedI",
      }

      require "custom.snippets"
    end,
  },

  {
    "pest-parser/pest.vim",
    ft = "pest",
  },
}

return plugins
