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

    -- Move tabs left and right
    ["<leader>-"] = {
      function()
        require("nvchad.tabufline").move_buf(-1)
      end,
      "Move tab left",
    },
    ["<leader>="] = {
      function()
        require("nvchad.tabufline").move_buf(1)
      end,
      "Move tab right",
    },

    -- Toggle terminal like VS Code
    ["<C-`>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    -- Toggle outline.nvim
    ["<leader>o"] = { "<cmd> OutlineOpen <CR> <cmd> OutlineFocusOutline <CR>", "Focus outline" },

    -- Open copilot chat
    ["<leader>ll"] = { "<cmd> CopilotChatOpen <CR>", "Focus CopilotChat" },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format { async = true }
      end,
      "formatting",
    },

    -- Open Diffview
    ["<leader>dv"] = { "<cmd> DiffviewOpen <CR>", "Open Diffview" },

    -- Open Diffview file history
    ["<leader>dh"] = { "<cmd> DiffviewFileHistory <CR>", "Open Diffview file history" },

    -- Restore auto-session
    ["<leader>sr"] = { "<cmd> SessionRestore <CR>", "Restore session" },
  },

  v = {
    [">"] = { ">gv", "indent" },
  },
}

M.debug = {
  n = {
    -- dap mappings
    ["<F4>"] = {
      function()
        require("dapui").close()
        require("nvim-tree.api").tree.open()
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

M.refactor = {
  n = {
    ["<leader>rr"] = {
      function()
        require("refactoring").select_refactor()
      end,
      "Refactor: select refactor",
    },
    ["<leader>ri"] = {
      "<cmd> Refactor inline <CR>",
      "Refactor: inline variable",
    },
    ["<leader>rI"] = {
      "<cmd> Refactor inline_func <CR>",
      "Refactor: inline function",
    },
    ["<leader>rb"] = {
      "<cmd> Refactor extract_block <CR>",
      "Refactor: extract block",
    },
    ["<leader>rbf"] = {
      "<cmd> Refactor extract_block_to_file <CR>",
      "Refactor: extract block to file",
    },
  },
  x = {
    ["<leader>rr"] = {
      function()
        require("refactoring").select_refactor()
      end,
      "Refactor: select refactor",
    },
    ["<leader>re"] = {
      "<cmd> Refactor extract <CR>",
      "Refactor: extract to function",
    },
    ["<leader>ref"] = {
      "<cmd> Refactor extract_to_file <CR>",
      "Refactor: extract function to file",
    },
    ["<leader>rv"] = {
      "<cmd> Refactor extract_var <CR>",
      "Refactor: extract variable",
    },
  },
}

return M
