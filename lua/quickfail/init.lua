local M = {}

---@require "quickfail.types"

-- Private vars & fcns

---@enum user_commands
local CMDS = {
  reload = "QuickFailReload",
  quit = "QuickFailQuit",
  select = "QuickFailSelect",
  manual = "QuickFailManual",
}
---@type Entry
local DefaultEntry = {
  cmd = {},
  pattern = "*",
  keycodes = nil,
  subshell = true,
}
local Augroup = vim.api.nvim_create_augroup("quickfail-group", { clear = true })

--- Expand special symbols ~, %, %:p AND env vars!
---@param cmd string[]
---@returns string
local expand_cmd = function(cmd)
  local exp_str = ""
  for _, c in ipairs(cmd) do
    exp_str = exp_str .. vim.fn.expand(c) .. " "
  end
  return exp_str
end

---See if the bufnr is loaded and valid
---@param bufnr integer?
---@returns boolean
local check_buffer = function(bufnr)
  if bufnr == nil then
    return false
  end
  -- buffer object still exists (hasn't been wiped).
  -- buffer is loaded in memory
  return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

------@return nil
------@param job Job
---local rm_job = function(job)
---  vim.api.nvim_del_autocmd(job.autocmd_id)
---  -- remove from table!
---end

---@type Job[] cache of active jobs
M.jobs = {}

---Remove invalid jobs
---@returns nil
M.check_jobs = function()
  for i = #M.jobs, 1, -1 do
    local job = M.jobs[i]
    if not check_buffer(job.buffer) then
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
  if #entry.cmd == 0 then
    vim.notify("Command is required!", vim.log.levels.ERROR, {})
    return
  end

  if (entry.pattern or "") == "" then
    entry.pattern = DefaultEntry.pattern
  end

  -- nil check?
  entry.subshell = entry.subshell or DefaultEntry.subshell

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

  -- vim.notify(Job, vim.log.levels.DEBUG, {})

  -- leave Terminal-Job mode (like <C-\><C-n>)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", true)

  -- move cursor to last line (nvim_buf_line_count is 1-indexed) (to tail it....)
  local last_line = vim.api.nvim_buf_line_count(job.buffer)
  vim.api.nvim_win_set_cursor(job.window, { last_line, 0 })

  -- recover cursor position in previous window
  vim.api.nvim_set_current_win(prev_window)
  vim.api.nvim_win_set_cursor(prev_window, prev_cursor)

  job.callback = function()
    if not check_buffer(job.buffer) then
      -- TODO:remove job from M.jobs
      return
    end
    vim.print(entry.cmd)
    local cmd_str = expand_cmd(entry.cmd)
    if job.entry.subshell or false then
      cmd_str = "( " .. cmd_str .. " )"
    end
    vim.api.nvim_chan_send(job.chan, "clear\n" .. cmd_str .. "\n")
  end

  -- Escape to close the terminal split
  vim.keymap.set("n", "<Esc>", function()
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
      group = Augroup,
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
M.config = {
  menu = {
    { cmd = { "bash", "%" }, title = "bash", desc = "Test!" },
    { cmd = { "%:p" }, title = "Execute", desc = "Test!" },
    { cmd = { "source", "%:p" }, title = "Source", desc = "Test!" },
    { cmd = { "echo", "%:p" }, title = "Absolute Path", desc = "Test!" },
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
}

--- Setup function that users call
---@param user_config Config?
---@return nil
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

  vim.api.nvim_create_user_command(CMDS.quit, M.quit, { desc = "Stop Active QuickFail jobs" })
  vim.api.nvim_create_user_command(CMDS.reload, function()
    -- Easy Reloading
    package.loaded["quickfail"] = nil
    require("quickfail").setup()
  end, { desc = "Reload QuickFail plugin" })

  --- use like `vim.cmd[[QuickFailCustom]]`
  vim.api.nvim_create_user_command(CMDS.manual, M.manual, {
    desc = "Rerun everything",
    nargs = "*",
  })

  vim.api.nvim_create_user_command(CMDS.select, M.select, {
    desc = "Choose from some options",
  })
end

return M
