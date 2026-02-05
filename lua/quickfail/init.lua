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

---@returns nil
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

---@returns nil
function M.select()
  -- Check if snacks.nvim is available
  local has_snacks, snacks = pcall(require, "snacks")
  if not has_snacks then
    -- Fallback to vim.ui.select if snacks is not available
    ---@type string[]
    local display = {}
    ---@type table<string,Entry>
    local choice2entry = {}
    local title = ""
    for i, entry in ipairs(M.config.menu) do
      title = string.format("[%s] %s", i, entry.title)
      table.insert(display, title)
      choice2entry[title] = entry
    end

    vim.ui.select(display, { prompt = "Choose:" }, function(choice)
      print("selected:", choice)
      if not choice then
        return
      end
      M.quickfail(choice2entry[choice])
    end)
    return
  end

  -- Build items for snacks picker
  ---@type table[]
  local items = {}
  for i, entry in ipairs(M.config.menu) do
    local title = entry.title or string.format("Command %d", i)
    local desc = entry.desc or ""
    table.insert(items, {
      idx = i,
      text = title,
      desc = desc,
      entry = entry,
    })
  end

  -- Use snacks picker with custom format and preview
  snacks.picker({
    title = "QuickFail Commands",
    items = items,
    layout = {
      preset = "default",
    },
    format = function(item)
      local ret = {}
      -- Format: [idx] title - description
      ret[#ret + 1] = { string.format("[%d] ", item.idx), "SnacksPickerLabel" }
      ret[#ret + 1] = { item.text, "SnacksPickerTitle" }
      if item.desc and item.desc ~= "" then
        ret[#ret + 1] = { " - ", "Comment" }
        ret[#ret + 1] = { item.desc, "SnacksPickerComment" }
      end
      return ret
    end,
    preview = function(ctx)
      local item = ctx.item
      local entry = item.entry
      local lines = {}

      -- Header
      table.insert(lines, "# QuickFail Command Details")
      table.insert(lines, "")

      -- Command section
      table.insert(lines, "## Command")
      if type(entry.cmd) == "function" then
        table.insert(lines, "```lua")
        table.insert(lines, "<function>")
        table.insert(lines, "```")
        table.insert(lines, "")
        table.insert(lines, "_Note: This is a Lua function that generates the command dynamically._")
      else
        table.insert(lines, "```bash")
        table.insert(lines, table.concat(entry.cmd, " "))
        table.insert(lines, "```")
      end
      table.insert(lines, "")

      -- Expanded command (if not a function and current buffer exists)
      if type(entry.cmd) ~= "function" and vim.api.nvim_buf_is_valid(0) then
        local has_expansion = false
        local expanded = {}
        for _, c in ipairs(entry.cmd) do
          local exp = vim.fn.expand(c)
          table.insert(expanded, exp)
          if exp ~= c then
            has_expansion = true
          end
        end

        if has_expansion then
          table.insert(lines, "## Expanded Command (Current File)")
          table.insert(lines, "```bash")
          table.insert(lines, table.concat(expanded, " "))
          table.insert(lines, "```")
          table.insert(lines, "")
        end
      end

      -- Additional details
      if entry.pattern and entry.pattern ~= "" then
        table.insert(lines, "## Auto-run Pattern")
        table.insert(lines, "`" .. entry.pattern .. "`")
        table.insert(lines, "")
      end

      if entry.keycodes and entry.keycodes ~= "" then
        table.insert(lines, "## Keyboard Shortcut")
        table.insert(lines, "`" .. entry.keycodes .. "`")
        table.insert(lines, "")
      end

      if entry.desc and entry.desc ~= "" then
        table.insert(lines, "## Description")
        table.insert(lines, entry.desc)
        table.insert(lines, "")
      end

      if entry.subshell ~= nil then
        table.insert(lines, "## Subshell")
        table.insert(lines, entry.subshell and "Yes" or "No")
      end

      -- Set buffer content and filetype for syntax highlighting
      vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
      vim.bo[ctx.buf].filetype = "markdown"
    end,
    confirm = function(picker, item)
      picker:close()
      M.quickfail(item.entry)
    end,
  })
end

---@returns nil
function M.quit()
  for _, job in ipairs(M.jobs) do
    if job.autocmd_id then
      vim.api.nvim_del_autocmd(job.autocmd_id)
    end
    vim.api.nvim_buf_delete(job.buffer, { force = true })
  end
end

--- Initial (Default) configuration
---@type Config
M.config = {}

--- Setup function that users call
---@param user_config Config?
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
