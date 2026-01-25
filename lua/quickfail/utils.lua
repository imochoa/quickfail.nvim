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

return M
