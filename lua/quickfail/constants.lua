local M = {}

---@require "quickfail.types"
local utils = require("quickfail.utils")

---You will need to call expand_cmd/vim.fn.expand yourself
---@returns string[]
local mk_cmd = function()
  return table.concat({
    { "echo", "word!", "&&" },
    utils.expand_cmd({ "echo", "%:p" }),
  })
end

---You will need to call expand_cmd yourself
---@returns string[]
local quadlet_iterate = function()
  local service_name = vim.fn.expand("%:t:r") .. ".service"
  -- │ {"systemctl" ,"--user","restart", service_name, "&&"}..│ {"journalctl", "--user", "-xeu",service_name }
  return table.concat({
    { "systemctl", "--user", "daemon-reload" },
    { "&&", "systemctl", "--user", "restart", service_name },
    { "&&", "journalctl", "--user", "-xeu", service_name },
  })
end

---@type Config
M.plugin_defaults = {
  menu = {
    { cmd = { "bash", "%" }, title = "bash", desc = "Test!" },
    { cmd = { "%:p" }, title = "Execute", desc = "Test!" },
    { cmd = { "source", "%:p" }, title = "Source", desc = "Test!" },
    { cmd = { "echo", "%:p" }, title = "Absolute Path", desc = "Test!" },
    { cmd = { "echo", "%:p:r" }, title = "No Ext", desc = "Test!" },
    { cmd = { "echo", "%:p:r", ";", "echo", "second" }, title = "multi-cmd", desc = "Test!" },
    { cmd = mk_cmd, title = "function test", desc = "Test!" },
    { cmd = quadlet_iterate, title = "Quadlet", desc = "Test!" },
    -- h: filename-modifiers
    -- % filename
    -- %< filename without extension
    -- %:p full path
    -- %:. relative path
    -- %:~ path from home
    -- %:h head (parent directory)
    -- %:h:h head head (grand-parent directory)
    -- %:h tail (filename)
    -- %:h tail (filename)
    { cmd = { "echo", "$HOME" }, title = "Env vars work", desc = "Test!" },
    { cmd = { "echo", "%:p:h" }, title = "Absolute Path", desc = "Test!" },
    { cmd = { "nix", "eval", "--file", "%", "output.printThis" }, title = "nix", desc = "Test!" },
    -- # --debug
    -- # --verbose
    -- # --write-to ./out
    -- nix repl --verbose --debug --debugger --file ./example.nix
    { cmd = { "cat", "%" }, title = "cat", desc = "Test!" },
    { cmd = { "python", "%" }, title = "python", desc = "Run python file" },
    { cmd = { "just", "%" }, title = "just", desc = "Run Just recipe" },
  },
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
