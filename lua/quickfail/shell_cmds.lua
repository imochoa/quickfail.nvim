local M = {}

---@require "quickfail.types"
local utils = require("quickfail.utils")

---@type {[string]: fcnCmd}
M.functions = {
  mk_cmd = function()
    local cmd = { "echo", "word!" }
    utils.table_append(cmd, utils.expand_cmd({ "echo", "%:p" }))
    return cmd
  end,
  quadlet_iterate = function()
    local extension = vim.fn.expand("%:e"):lower()
    if extension ~= "container" then
      return {}
    end
    local service_name = vim.fn.expand("%:t:r") .. ".service"

    local cmd = { "systemctl", "--user", "daemon-reload" }
    utils.table_append(cmd, { "&&", "systemctl", "--user", "restart", service_name })
    utils.table_append(cmd, { "&&", "journalctl", "--user", "-xeu", service_name })
    return cmd
  end,
}

---@type Entry[]
M.entries = {
  precommit = { cmd = { "pre-commit", "run", "-a" }, title = "pre-commit", desc = "Test!" },
  bash = { cmd = { "bash", "%" }, title = "bash", desc = "Test!" },
  execute = { cmd = { "%:p" }, title = "Execute", desc = "Test!" },
  source = { cmd = { "source", "%:p" }, title = "Source", desc = "Test!" },
  nix_repl = { cmd = { "nix", "eval", "--file", "%", "output.printThis" }, title = "nix", desc = "Test!" },
  -- -- # --debug
  -- -- # --verbose
  -- -- # --write-to ./out
  -- -- nix repl --verbose --debug --debugger --file ./example.nix
  -- { cmd = { "cat", "%" }, title = "cat", desc = "Test!" },
  -- { cmd = { "python", "%" }, title = "python", desc = "Run python file" },
  -- { cmd = { "just", "%" }, title = "just", desc = "Run Just recipe" },
  -- { cmd = mk_cmd, title = "function test", desc = "Test!" },
  -- { cmd = quadlet_iterate, title = "Quadlet", desc = "Test!" },
  -- docs
  -- { cmd = { "echo", "%:p" }, title = "Absolute Path", desc = "Test!" },
  -- { cmd = { "echo", "%:p:r" }, title = "No Ext", desc = "Test!" },
  -- { cmd = { "echo", "%:p:r", ";", "echo", "second" }, title = "multi-cmd", desc = "Test!" },
  -- -- h: filename-modifiers
  -- -- % filename
  -- -- %< filename without extension
  -- -- %:p full path
  -- -- %:. relative path
  -- -- %:~ path from home
  -- -- %:h head (parent directory)
  -- -- %:h:h head head (grand-parent directory)
  -- -- %:h tail (filename)
  -- -- %:h tail (filename)
  -- { cmd = { "echo", "$HOME" }, title = "Env vars work", desc = "Test!" },
  -- { cmd = { "echo", "%:p:h" }, title = "Absolute Path", desc = "Test!" },
}

return M
