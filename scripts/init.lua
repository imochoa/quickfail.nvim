local filename = vim.fn.expand("%:p")
if #filename == 0 then
  -- INFO: when run with `nvim --headless`
  -- WARN: should be called from project root...
  print("No current file... using cwd" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
  vim.cmd([[let &rtp.=','.getcwd()]])
else
  -- INFO: when run with `:luafile %`
  -- -- local buf_path = vim.api.nvim_buf_get_name(0)
  local bufdir = vim.fn.expand("%:p:h")
  local repodir = vim.fn.expand("%:p:h:h")
  --
  vim.opt.rtp:append(bufdir)
  vim.opt.rtp:append(repodir)
  vim.opt.rtp:append(repodir .. "plugin")

  -- vim.cmd(string.format(":luafile %s/plugin/loadit.lua", repodir))
end

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  print("no UI! set up tests...")
  -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
  -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
  vim.cmd("set rtp+=deps/mini.nvim")
  require("mini.test").setup()
end
