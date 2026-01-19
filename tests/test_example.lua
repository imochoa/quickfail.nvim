local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create (but not start) child Neovim object
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/init.lua" })
      child.lua([[M = require('quickfail')]])
    end,
    post_once = child.stop,
  },
})

T["in child"] = MiniTest.new_set()

-- T["in child"]["works"] = function()
--   -- Execute Lua code inside child process, get its result and compare with
--   -- expected result
--   eq(child.lua_get([[M.add(2, 3)]]), 5)
-- end
--
-- -- Make parametrized tests. This will create three copies of each case
-- T["parametrize example"] = MiniTest.new_set({ parametrize = {
--   { 1, 1, 2 },
--   { 1, 0, 1 },
--   { 1, 9, 10 },
-- } })
--
-- -- Use arguments from test parametrization
-- T["parametrize example"]["adding"] = function(a, b, res)
--   eq(child.lua_get(string.format("M.add(%s, %s)", a, b)), res)
-- end

return T
