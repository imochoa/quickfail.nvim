local M = {}

---@require "quickfail.types"
local utils = require("quickfail.utils")
local shell_cmds = require("quickfail.shell_cmds")

---@type Entry[]
local all_entries = {}
for _, c in pairs(shell_cmds.entries) do
  table.insert(all_entries, c)
end

---@type Config
M.plugin_defaults = {
  menu = all_entries,
  -- menu = {
  --   shell_cmds.entries.precommit,
  --   shell_cmds.entries.bash,
  -- },
  defaults = {
    cmd = {},
    pattern = "*",
    keycodes = nil,
    subshell = true,
  },
}

---@enum user_commands
M.CMDS = {
  reload = "QuickFailReload",
  quit = "QuickFailQuit",
  select = "QuickFailSelect",
  manual = "QuickFailManual",
}
M.Augroup = vim.api.nvim_create_augroup("quickfail-group", { clear = true })

return M
