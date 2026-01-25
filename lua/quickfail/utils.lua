local M = {}

---@require "quickfail.types"

--- Expand special symbols ~, %, %:p AND env vars!
---@param cmd string[]
---@returns string
M.expand_cmd = function(cmd)
  local exp_str = ""
  for _, c in ipairs(cmd) do
    exp_str = exp_str .. vim.fn.expand(c) .. " "
  end
  return exp_str
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

return M
