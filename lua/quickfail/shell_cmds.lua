local M = {}

---@require "quickfail.types"
local utils = require("quickfail.utils")

---@param cmds string[][]
---@return string[]
local amp_concat = function(cmds)
  if #cmds == 0 then
    return {}
  end
  if #cmds == 1 then
    return cmds[1]
  end

  local full_cmd = {}
  for _, cmd_part in ipairs(cmds) do
    for _, c in ipairs(cmd_part) do
      table.insert(full_cmd, c)
    end
    table.insert(full_cmd, "&&")
  end
  return full_cmd
end

---@param ext string
---@param allowed_extensions string[]
---@return boolean
local ext_check = function(ext, allowed_extensions)
  for _, e in ipairs(allowed_extensions) do
    if e == ext then
      return true
    end
  end
  return false
end

---You will need to call expand_cmd/vim.fn.expand yourself
---@type {[string]: fcnCmd}
M.functions = {
  test_cmd = function()
    -- utils.table_append(cmd, utils.expand_cmd({ "echo", "%:p" }))
    return amp_concat({ { "echo", "hello" }, { "echo", "world" } })
  end,
  quadlet_iterate = function()
    local extension = vim.fn.expand("%:e"):lower()

    if not ext_check(extension, { "container", "pod" }) then
      return {}
    end

    local service_name = vim.fn.expand("%:t:r") .. ".service"

    return amp_concat({
      { "systemctl", "--user", "daemon-reload" },
      { "systemctl", "--user", "restart", service_name },
      { "journalctl", "--user", "-xeu", service_name },
    })
  end,
}

---@type {[any]: Entry}
M.entries = {}
M.entries.quadlet = { title = "quadlet", cmd = M.functions.quadlet_iterate, desc = "Fancy \n Stuff" }
M.entries.precommit =
  { title = "pre-commit", cmd = { "pre-commit", "run", "-a" }, desc = "Run all pre-commit hooks over all files" }
-- M.entries.bash = { title="bash",cmd = { "bash", "%" }, desc = "Test!" }
M.entries.execute = { title = "Run", cmd = { "%:p" }, desc = "In default shell" }
M.entries.source = { title = "source", cmd = { "source", "%:p" }, desc = "Default shell" }
-- M.entries.cat = { title = "cat", cmd = { "cat", "%" }, desc = "Test!" }
M.entries.python = { title = "python", cmd = { "python", "%" }, desc = "Run with python " }
M.entries.just = { title = "just", cmd = { "just", "%" }, desc = "Run Just recipe" }

return M
