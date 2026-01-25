---@meta

--- @class (exact) JobStartOpts h: jobstart-options
--- @field clear_env boolean?
--- @field cwd string?
--- @field detach boolean?
--- @field env table<string, string>?
--- @field on_exit fun(job_id:integer, exit_code:integer, event:string)|nil
--- @field on_stdout fun(job_id:integer, data:string[], event:string)|nil
--- @field on_stderr fun(job_id:integer, data:string[], event:string)|nil
--- @field overlapped boolean?
--- @field pty boolean?
--- @field rpc boolean?
--- @field stderr_buffered boolean?
--- @field stdout_buffered boolean?
--- @field stdin string? "pipe" (default) or "null"
--- @field term boolean?

---@class (exact) Entry
---@field cmd string[] | fun():string[] command to run
---@field keycodes string?
---@field pattern string?
---@field title string?
---@field desc string?
---@field subshell boolean?
---@field opts JobStartOpts?

---@class (exact) Job More info with 'help: highlight', 'help: highlight-args'
---@field entry Entry
---@field callback function(nil):nil
---@field buffer integer what buffer it is running in
---@field window integer what window it is running in
---@field chan integer channel id
---@field autocmd_id integer? autocmd id

---@class (exact) Config
---@field menu Entry[]
---@field entry_defaults Entry

---@alias uint8 number (0-255) integers
