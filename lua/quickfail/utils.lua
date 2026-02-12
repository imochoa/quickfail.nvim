local M = {}

---@require "quickfail.types"

--- Expand special symbols ~, %, %:p AND env vars!
---@param cmd string[]
---@returns string[]
M.expand_cmd = function(cmd)
  local out = {}
  for _, c in ipairs(cmd) do
    table.insert(out, vim.fn.expand(c))
  end
  return out
end

---See if the bufnr is loaded and valid
---@param bufnr integer?
---@returns boolean
M.check_buffer = function(bufnr)
  if bufnr == nil then
    return false
  end
  -- buffer object still exists (hasn't been wiped).
  -- buffer is loaded in memory
  return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

---Modifies t1 by appending t2 to it
---@param t1 {}
---@param t2 {}
M.table_append = function(t1, t2)
  local n = #t1
  for i = 1, #t2 do
    t1[n + i] = t2[i]
  end
  return t1
end

---@param menu_items any
---@returns nil
local fallback_menu = function(menu_items)
  -- Fallback to vim.ui.select if snacks is not available
  ---@type string[]
  local display = {}
  ---@type table<string,Entry>
  local choice2entry = {}
  local title = ""
  for i, entry in ipairs(menu_items) do
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

---@param ctx snacks.picker.preview.ctx
local snacks_preview_basic = function(ctx)
  -- preview = entry.cmd and type(entry.cmd) == "function" and "<function>" or table.concat(M.expand_cmd(entry.cmd or {}), " "),

  local cmd_preview = "<no command>"

  ---@type Entry
  local entry = ctx.item.entry

  if type(entry.cmd) == "function" then
    -- or table.concat(M.expand_cmd(ctx.item.entry.cmd or {}), " "),
    cmd_preview = entry.cmd()
  else
    cmd_preview = table.concat(entry.cmd or {}, " ")
    -- or table.concat(M.expand_cmd(ctx.item.entry.cmd or {}), " "),
  end
  ctx.preview:set_lines({
    "Command:",
    cmd_preview,
  })
end

---@param ctx snacks.picker.preview.ctx
local snacks_preview_fancy = function(ctx)
  local item = ctx.item
  ---@type Entry
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
end

---@param menu_items Entry[]
---@returns boolean
local snacks_menu = function(menu_items)
  local has_snacks, snacks = pcall(require, "snacks")
  if not has_snacks then
    return false
  end

  ---@type snacks.picker.finder.Item[]
  local items = {}
  for idx, entry in ipairs(menu_items) do
    table.insert(items, { idx = idx, entry = entry })
  end

  snacks.picker({
    title = "QuickFail Commands",
    items = items,
    layout = {
      preset = "default",
    },
    format = function(item)
      return {
        { string.format("[%s] ", item.entry.title or "No Title"), "SnacksPickerLabel" },
        { item.entry.desc, "SnacksPickerComment" },
      }
    end,
    preview = snacks_preview_basic,
    confirm = function(picker, item)
      picker:close()
      M.quickfail(item.entry)
    end,
  })

  return true
end

---comment
---@param menu_items any
---@returns nil
M.menu = function(menu_items)
  local has_snacks = snacks_menu(menu_items)
  if not has_snacks then
    fallback_menu(menu_items)
  end
end

return M
