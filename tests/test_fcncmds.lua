local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create (but not start) child Neovim object
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/init.lua" })
      child.lua([[M = require('quickfail.shell_cmds')]])
    end,
    post_once = child.stop,
  },
})

-- T["fcncmds"] = MiniTest.new_set()
--
-- T["fcncmds"]["path"] = function()
--   child.cmd([[edit tests/example.txt]])
--   -- eq(child.cmd_lua([[return vim.fn.expand("%:p")]]), child.lua_get([[vim.fn.getcwd() .. "/tests/example.txt"]]))
--   eq(child.lua_get([[vim.fn.expand("%:p")]]), "meow")
-- end
--
-- T["fcncmds"]["works"] = function()
--   eq(child.lua_get([[M.functions.quadlet_iterate()]]), 5)
-- end
--
T["quadlet"] = MiniTest.new_set({
  parametrize = {
    -- Do not run for these files
    { "file.txt", {} },
    { "file.py", {} },
    { "file.c", {} },
    -- These are OK!
    {
      "file.container",
      {
        "systemctl",
        "--user",
        "daemon-reload",
        "&&",
        "systemctl",
        "--user",
        "restart",
        "file.service",
        "&&",
        "journalctl",
        "--user",
        "-xeu",
        "file.service",
      },
    },
  },
})

T["quadlet"]["run or not"] = function(file, soll)
  -- Open a file of the target type
  child.cmd(string.format("edit tests/%s", file))
  local ist = child.lua_get([[M.functions.quadlet_iterate()]])
  eq(#ist > 0, #soll > 0)
  eq(ist, soll)
end

-- T["quadlet"]["match output"] = function(file, soll)
--   -- Open a file of the target type
--   child.cmd(string.format("edit tests/%s", file))
--   eq(child.lua_get([[M.functions.quadlet_iterate()]]), soll)
-- end

return T
