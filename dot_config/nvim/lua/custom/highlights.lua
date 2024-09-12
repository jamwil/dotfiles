-- To find any highlight groups: "<cmd> Telescope highlights"
-- Each highlight group can take a table with variables fg, bg, bold, italic, etc
-- base30 variable names can also be used as colors

local M = {}

---@type Base46HLGroupsList
M.override = {
  Comment = {
    fg = "#777777",
    italic = true,
  },
  ["@comment"] = {
    fg = "#777777",
    italic = true,
  },
  LineNr = {
    fg = "#777777",
  },
  SignColumn = {
    fg = "#dddddd",
  },
}

---@type HLTable
M.add = {
  NvimTreeOpenedFolderName = { fg = "green", bold = true },
}

return M
