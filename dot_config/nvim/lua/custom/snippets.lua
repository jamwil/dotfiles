local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

-- Add the snippet for all filetypes (global snippet)
ls.add_snippets("all", {
    s("--", { t("—") }), -- Replaces `--` with an em-dash
})
