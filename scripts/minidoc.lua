-- Script to generate help file for quickfail.nvim using mini.doc
local minidoc = require("mini.doc")

-- Setup mini.doc if not already done
if _G.MiniDoc == nil then
  minidoc.setup()
end

-- Generate documentation from main module
MiniDoc.generate({ "lua/quickfail/init.lua" }, "doc/quickfail.txt")
