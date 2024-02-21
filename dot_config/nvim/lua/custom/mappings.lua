---@type MappingsTable
local M = {}

M.general = {
  t = {
    ["<C-`>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },
  },

  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    -- Toggle terminal like VS Code
    ["<C-`>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    -- Toggle outline.nvim
    ["<leader>o"] = { "<cmd> OutlineOpen <CR> <cmd> OutlineFocusOutline <CR>", "Focus outline" },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format { async = true }
      end,
      "formatting",
    },
  },

  v = {
    [">"] = { ">gv", "indent" },
  },
}

M.copilot = {
  i = {},
}

M.debug = {
  n = {
    -- dap mappings
    ["<F4>"] = {
      function()
        require("dap-ui").close()
      end,
      "Debug: Close debugger",
    },
    ["<F5>"] = {
      function()
        require("dap").continue()
      end,
      "Debug: Start/Continue debugging",
    },
    ["<F8>"] = {
      function()
        require("dap").toggle_breakpoint()
      end,
      "Debug: Toggle breakpoint",
    },
    ["<F10>"] = {
      function()
        require("dap").step_over()
      end,
      "Debug: Step over",
    },
    ["<F11>"] = {
      function()
        require("dap").step_into()
      end,
      "Debug: Step into",
    },
    ["<F12>"] = {
      function()
        require("dap").step_out()
      end,
      "Debug: Step out",
    },
    ["<leader>;"] = {
      function()
        require("dap-python").test_method()
      end,
      "Debug: Test method",
    },
  },
}

-- more keybinds!

return M
