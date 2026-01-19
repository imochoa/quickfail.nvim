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
test-file file="./tests/example.lua":
    nvim --headless --noplugin -u "./scripts/init.lua" -c "lua MiniTest.run_file('{{ file }}')"
