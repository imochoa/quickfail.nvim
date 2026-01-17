set positional-arguments := true
set shell := ["bash", "-euco", "pipefail"]

[no-cd]
_default:
    @just --list --list-submodules

[group('ci')]
fmt-just:
    @just --fmt --unstable

setup:
    printf "mini.nvim & tests"
    mkdir -p deps
    git clone --filter=blob:none https://github.com/nvim-mini/mini.nvim deps/mini.nvim

# Run all test files
[group('test')]
test-all:
    nvim --headless --noplugin -u "./scripts/init.lua" -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable ????
[group('test')]
test-file file="./tests/test_same_proc.lua":
    nvim --headless --noplugin -u "./scripts/init.lua" -c "lua MiniTest.run_file('{{ file }}')"

# nvim --headless --noplugin -u "./scripts/headless_init.lua" -c "lua MiniTest.run_file('$(FILE)')"
#
# nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"
# - `:lua MiniTest.run_file()`
# nvim --headless --noplugin --cmd ":luafile ./scripts/minimal_init.lua" # --cmd "echo hoho"
#
# multi-line command
# nvim --headless -c 'call mkdir(stdpath("config"), "p") | exe "edit" stdpath("config") . "/init.lua" | write | quit'
#
#
# Autocommands
# :help autocmd-intro
#
# local augroup = vim.api.nvim_create_augroup('user_cmds', {clear = true})

# vim.api.nvim_create_autocmd('FileType', {
#   pattern = {'help', 'man'},
#   group = augroup,
#   desc = 'Use q to close the window',
#   command = 'nnoremap <buffer> q <cmd>quit<cr>'
# })
#
# vim.api.nvim_create_autocmd('TextYankPost', {
#   group = augroup,
#   desc = 'Highlight on yank',
#   callback = function(event)
#     vim.highlight.on_yank({higroup = 'Visual', timeout = 200})
#   end
# })
