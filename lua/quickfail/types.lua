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


		  -- clear_env:  (boolean) `env` defines the job environment
		  --      exactly, instead of merging current environment.
		  -- cwd:	      (string, default=|current-directory|) Working
		  --      directory of the job.
		  -- detach:     (boolean) Detach the job process: it will not be
		  --      killed when Nvim exits. If the process exits
		  --      before Nvim, `on_exit` will be invoked.
		  -- env:	      (dict) Map of environment variable name:value
		  --      pairs extending (or replace with "clear_env")
		  --      the current environment. |jobstart-env|
		  -- |on_exit|:    (function) Callback invoked when the job exits.
		  -- |on_stdout|:  (function) Callback invoked when the job emits
		  --      stdout data.
		  -- |on_stderr|:  (function) Callback invoked when the job emits
		  --      stderr data.
		  -- overlapped: (boolean) Sets FILE_FLAG_OVERLAPPED for the
		  --      stdio passed to the child process. Only on
		  --      MS-Windows; ignored on other platforms.
		  -- pty:	      (boolean) Connect the job to a new pseudo
		  --      terminal, and its streams to the master file
		  --      descriptor. `on_stdout` receives all output,
		  --      `on_stderr` is ignored. |terminal-start|
		  -- rpc:	      (boolean) Use |msgpack-rpc| to communicate with
		  --      the job over stdio. Then `on_stdout` is ignored,
		  --      but `on_stderr` can still be used.
		  -- stderr_buffered: (boolean) Collect data until EOF (stream closed)
		  --      before invoking `on_stderr`. |channel-buffered|
		  -- stdout_buffered: (boolean) Collect data until EOF (stream
		  --      closed) before invoking `on_stdout`. |channel-buffered|
		  -- stdin:      (string) Either "pipe" (default) to connect the
		  --      job's stdin to a channel or "null" to disconnect
		  --      stdin.
		  -- term:	    (boolean) Spawns {cmd} in a new pseudo-terminal session
		  --         connected to the current (unmodified) buffer. Implies "pty".
		  --         Default "height" and "width" are set to the current window
		  --         dimensions. |jobstart()|. Defaults $TERM to "xterm-256color".
		  -- width:      (number) Width of the `pty` terminal.
		  -- height:     (number) Height of the `pty` terminal.

---@class (exact) Entry
---@field cmd string[] command to run
---@field keycodes string?
---@field pattern string?
---@field title string?
---@field desc string?
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

---@alias uint8 number (0-255) integers
