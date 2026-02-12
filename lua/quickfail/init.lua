--- Automatic command execution on file save
---
--- MIT License Copyright (c) 2025
---
--- Features:
--- - Run commands automatically on file save with configurable patterns
--- - Display command output in a persistent terminal split window
--- - Support for both static commands and dynamic Lua functions
--- - File pattern matching for auto-execution (e.g., "*.lua", "*.py")
--- - Optional keyboard shortcuts for manual command execution
--- - Support for environment variables and filename modifiers (%, %:p, etc.)
--- - Integration with Snacks.nvim picker for interactive command selection
--- - Multiple simultaneous jobs with independent terminal windows
---
--- # Setup ~
---
--- This module needs a setup with `require('quickfail').setup({})` (replace
--- `{}` with your `config` table). It will create global Lua table `M` which
--- you can use for scripting or manually (with `:lua require('quickfail').*`).
---
--- See |quickfail.setup()| for configuration options.
---
--- # Example usage ~
--- >lua
---   require('quickfail').setup({
---     menu = {
---       { cmd = { "python", "%" }, title = "Run Python", desc = "Execute current file" },
---       { cmd = { "just", "test" }, title = "Run Tests", desc = "Run test suite" },
---     },
---     defaults = {
---       pattern = "*",
---       subshell = true,
---     },
---   })
--- <
---
--- # Commands ~
---
--- - |:QuickFailSelect| - Open picker to select and run a command
--- - |:QuickFailManual| - Manually enter a command to run
--- - |:QuickFailQuit| - Stop all active QuickFail jobs
--- - |:QuickFailReload| - Reload the QuickFail plugin
---
--- # Highlight groups ~
---
--- This plugin uses highlight groups from Snacks.nvim picker when available:
--- - `SnacksPickerLabel` - Item index labels in picker
--- - `SnacksPickerTitle` - Command titles in picker
--- - `SnacksPickerComment` - Command descriptions in picker
---
---@tag quickfail quickfail.nvim

---@toc quickfail.contents

-- Module definition ==========================================================
local M = {}

---@require "quickfail.types"
local utils = require("quickfail.utils")
local constants = require("quickfail.constants")

-- Private vars & fcns

---@type Job[] cache of active jobs
M.jobs = {}

---Remove invalid jobs
---@returns nil
M.check_jobs = function()
  for i = #M.jobs, 1, -1 do
    local job = M.jobs[i]
    if not utils.check_buffer(job.buffer) then
      vim.notify("Job buffer invalid, removing job", vim.log.levels.WARN, {})
      if job.autocmd_id then
        vim.api.nvim_del_autocmd(job.autocmd_id)
      end
      -- remove from jobs
      table.remove(M.jobs, i)
      --
    end
  end
end

---@param entry Entry
---@returns nil
M.quickfail = function(entry)
  if type(entry.cmd) ~= "function" and #entry.cmd == 0 then
    vim.notify("Command is required!", vim.log.levels.ERROR, {})
    return
  end

  if (entry.pattern or "") == "" then
    entry.pattern = M.config.defaults.pattern
  end

  -- nil check?
  entry.subshell = entry.subshell or M.config.defaults.subshell

  vim.notify(
    string.format("Will \n\tRunning:%s\n\ton Saving %s\n\tor pressing %s", entry.cmd, entry.pattern, entry.keycodes),
    vim.log.levels.INFO,
    {}
  )

  -- local prev_bufnr = vim.api.nvim_get_current_buf()
  local prev_window = vim.api.nvim_get_current_win()
  local prev_cursor = vim.api.nvim_win_get_cursor(prev_window)

  vim.cmd("vsplit new")

  ---@type Job
  local job = {
    entry = entry,
    buffer = vim.api.nvim_get_current_buf(),
    window = vim.api.nvim_get_current_win(),
    autocmd_id = nil,
    callback = function() end,
    -- start a persistent shell in a terminal buffer; this returns a job/channel id
    chan = vim.fn.jobstart({ vim.o.shell or "sh" }, {
      term = true,
      -- cwd={},
      -- env={},
    }),
  }

  -- leave Terminal-Job mode (like <C-\><C-n>)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", true)

  -- move cursor to last line (nvim_buf_line_count is 1-indexed) (to tail it....)
  local last_line = vim.api.nvim_buf_line_count(job.buffer)
  vim.api.nvim_win_set_cursor(job.window, { last_line, 0 })

  -- recover cursor position in previous window
  vim.api.nvim_set_current_win(prev_window)
  vim.api.nvim_win_set_cursor(prev_window, prev_cursor)

  job.callback = function()
    if not utils.check_buffer(job.buffer) then
      -- TODO:remove job from M.jobs
      return
    end

    ---@type string[]
    local cmd = {}
    if type(entry.cmd) == "function" then
      cmd = entry.cmd()
    else
      cmd = utils.expand_cmd(entry.cmd)
    end

    local cmd_str = ""
    for _, c in ipairs(cmd) do
      cmd_str = cmd_str .. vim.fn.expand(c) .. " "
    end

    vim.print(entry.cmd)
    -- local cmd_str = utils.expand_cmd(entry.cmd)
    if job.entry.subshell or false then
      cmd_str = "( " .. cmd_str .. " )"
    end
    -- TODO: interrupt cmd?
    vim.api.nvim_chan_send(job.chan, "clear\n" .. cmd_str .. "\n")
  end

  -- TODO: add oneshot jobs

  -- TODO: allow sending interrupt command e.g. 'q' before running

  -- Escape to close the terminal split
  vim.keymap.set("n", "<q>", function()
    vim.api.nvim_buf_delete(job.buffer, { force = true })
    -- TODO: remove job as well
    if job.autocmd_id then
      vim.api.nvim_del_autocmd(job.autocmd_id)
    end
  end, { buffer = job.buffer })

  if (entry.keycodes or "") ~= "" then
    vim.keymap.set({ "n" }, entry.keycodes, function()
      -- vim.notify(cmd, vim.log.levels.DEBUG, {})
      job.callback()
    end, {})
  end

  if (entry.pattern or "") ~= "" then
    job.autocmd_id = vim.api.nvim_create_autocmd("BufWritePost", {
      group = constants.Augroup,
      pattern = entry.pattern,
      callback = job.callback,
    })
  end

  table.insert(M.jobs, job)

  -- run immediately
  job.callback()
end

--- Manually enter and run a command
---
--- Prompts the user for:
--- - Command to run (space-separated arguments)
--- - File pattern for auto-run on save (optional, empty for none)
--- - Keyboard shortcut (optional, e.g., "<F13>")
---
--- The command will be executed immediately and set up for future triggers
--- based on the provided pattern and/or keycode.
---
---@return nil
function M.manual()
  -- vim.print(args)
  local cmd_str = vim.fn.input("cmd to run")
  cmd_str = cmd_str:gsub("%s+", " ")

  ---@type Entry
  local entry = {
    cmd = vim.split(cmd_str, "%s+", {}),
    pattern = vim.fn.input("Pattern (empty for all): "),
    keycodes = vim.fn.input("Key code e.g. <F13>"),
  }
  M.quickfail(entry)
end

--- Open interactive picker to select and run a command
---
--- Displays a picker (using Snacks.nvim if available, falling back to
--- vim.ui.select) with all configured menu commands. The picker shows:
--- - Command title and description in the main list
--- - Detailed preview with command, pattern, keycodes, and description
--- - Expanded command showing how special symbols (%, %:p, etc.) resolve
---
--- Navigate with j/k or arrow keys, filter with fuzzy search, and press
--- Enter to select and execute a command.
---
---@return nil
function M.select()
  utils.menu(M.config.menu)
end

--- Stop all active QuickFail jobs
---
--- Closes all terminal buffers and removes all autocommands created by
--- active QuickFail jobs. This is useful for cleanup when you want to
--- stop all running commands and close their terminal windows.
---
---@return nil
function M.quit()
  for _, job in ipairs(M.jobs) do
    if job.autocmd_id then
      vim.api.nvim_del_autocmd(job.autocmd_id)
    end
    vim.api.nvim_buf_delete(job.buffer, { force = true })
  end
end

--- Module configuration
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text
--- # Configuration structure ~
---
--- `menu` is an array of Entry tables with the following fields:
--- - `cmd` (string[]|function) - Command to run. Can be a table of strings
---   (e.g., {"python", "%"}) or a Lua function that returns such a table.
---   Supports special symbols: %, %:p, %:h, $VAR, etc.
--- - `title` (string?) - Display name in the picker menu
--- - `desc` (string?) - Description shown in picker preview
--- - `pattern` (string?) - File pattern for auto-run (e.g., "*.lua", "*")
--- - `keycodes` (string?) - Keyboard shortcut (e.g., "<F13>")
--- - `subshell` (boolean?) - Whether to run command in a subshell
---
--- `defaults` contains fallback values for optional Entry fields.
---
---@type Config
M.config = {
  menu = {},
  defaults = {
    cmd = {},
    pattern = "*",
    keycodes = nil,
    subshell = true,
  },
}
--minidoc_afterlines_end

--- Module setup
---
--- Configure QuickFail with menu items and default settings. This function
--- must be called before using any QuickFail commands. It will:
--- - Merge user configuration with defaults
--- - Create user commands (:QuickFailSelect, :QuickFailManual, etc.)
--- - Set up autocommands and keymaps as needed
---
---@param user_config Config? Module config table. See |quickfail.config|.
---
---@usage >lua
---   require('quickfail').setup({
---     menu = {
---       { cmd = { "python", "%" }, title = "Run Python", pattern = "*.py" },
---       { cmd = { "just", "test" }, title = "Run Tests" },
---     },
---   })
--- <
---    -- { cmd = { "pre-commit", "run", "-a" }, title = "pre-commit", desc = "Test!" }, -- { cmd = { "bash", "%" }, title = "bash", desc = "Test!" }, -- { cmd = { "%:p" }, title = "Execute", desc = "Test!" }, -- { cmd = { "source", "%:p" }, title = "Source", desc = "Test!" }, -- { cmd = { "echo", "%:p" }, title = "Absolute Path", desc = "Test!" }, -- { cmd = { "echo", "%:p:r" }, title = "No Ext", desc = "Test!" },
---    -- { cmd = { "echo", "%:p:r", ";", "echo", "second" }, title = "multi-cmd", desc = "Test!" },
---    -- { cmd = mk_cmd, title = "function test", desc = "Test!" },
---    -- { cmd = quadlet_iterate, title = "Quadlet", desc = "Test!" },
---    -- -- h: filename-modifiers
---    -- -- % filename
---    -- -- %< filename without extension
---    -- -- %:p full path
---    -- -- %:. relative path
---    -- -- %:~ path from home
---    -- -- %:h head (parent directory)
---    -- -- %:h:h head head (grand-parent directory)
---    -- -- %:h tail (filename)
---    -- -- %:h tail (filename)
---    -- { cmd = { "echo", "$HOME" }, title = "Env vars work", desc = "Test!" },
---    -- { cmd = { "echo", "%:p:h" }, title = "Absolute Path", desc = "Test!" },
---    -- { cmd = { "nix", "eval", "--file", "%", "output.printThis" }, title = "nix", desc = "Test!" },
---    -- -- # --debug
---    -- -- # --verbose
---    -- -- # --write-to ./out
---    -- -- nix repl --verbose --debug --debugger --file ./example.nix
---    -- { cmd = { "cat", "%" }, title = "cat", desc = "Test!" },
---    -- { cmd = { "python", "%" }, title = "python", desc = "Run python file" },
---    -- { cmd = { "just", "%" }, title = "just", desc = "Run Just recipe" },
---
---@return nil
function M.setup(user_config)
  user_config = user_config or {}
  M.config = vim.tbl_deep_extend("force", constants.plugin_defaults, user_config)

  vim.api.nvim_create_user_command(constants.CMDS.quit, M.quit, { desc = "Stop Active QuickFail jobs" })
  vim.api.nvim_create_user_command(constants.CMDS.reload, function()
    package.loaded["quickfail"] = nil
    require("quickfail").setup()
  end, { desc = "Reload QuickFail plugin" })

  --- use like `vim.cmd[[QuickFailCustom]]`
  vim.api.nvim_create_user_command(constants.CMDS.manual, M.manual, {
    desc = "Rerun everything",
    nargs = "*",
  })

  vim.api.nvim_create_user_command(constants.CMDS.select, M.select, {
    desc = "Choose from some options",
  })
end

return M
