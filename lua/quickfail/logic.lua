local M = {}

--- TODO: defaults, split into something that can be mapped to Fkeys or some other keybinding
---@param pattern string matching pattern for BufWritePost (defaults to *)
---@param cmd string[] to be run in the terminal split
---@param keycodes string keycode to bind
---@returns nil
M.rerecmd = function(pattern, cmd, keycodes)
	pattern = pattern or "*"
	-- cmd = pattern or "*"
	keycodes = keycodes or "<F13>"
	-- vim.print(args)
	local augroup_name = "reruncmd-group"
	-- local keycodes = "<F13>"
	-- local pattern = vim.fn.input("Pattern (empty for all): ")
	-- if #pattern == 0 then
	--   pattern = "*"
	-- end

	-- local cmd = vim.fn.input("cmd to run")
	-- if #cmd == 0 then
	--   vim.notify("Command is required!", vim.log.levels.ERROR, {})
	--   return
	-- end
	vim.notify(
		string.format("Will \n\tRunning:%s\n\ton Saving %s\n\tor pressing %s", cmd, pattern, keycodes),
		vim.log.levels.INFO,
		{}
	)
	local prev_bufnr = vim.api.nvim_get_current_buf()
	local window_nr = vim.api.nvim_get_current_win()

	vim.cmd("vsplit new")
	Bufnr = vim.api.nvim_get_current_buf()

	-- start a persistent shell in a terminal buffer; this returns a job/channel id
	Job = vim.fn.jobstart({ vim.o.shell or "sh" }, {
		term = true,
		-- cwd={}, env={}
	})
	-- vim.notify(Job, vim.log.levels.DEBUG, {})

	-- leave Terminal-Job mode (like <C-\><C-n>)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", true)

	-- move cursor to last line (nvim_buf_line_count is 1-indexed) (to tail it....)
	local last_line = vim.api.nvim_buf_line_count(Bufnr)
	vim.api.nvim_win_set_cursor(0, { last_line, 0 })

	local run_job = function()
		-- Expand special symbols ~, %, %:p
		-- local exp_cmd = {}
		local exp_str = ""
		for i, c in ipairs(cmd) do
			-- exp_cmd[i] = vim.fn.expand(c)
			-- vim.notify(c, vim.log.levels.DEBUG, {})
			-- vim.notify(vim.fn.expand(c), vim.log.levels.DEBUG, {})
			exp_str = exp_str .. vim.fn.expand(c) .. " "
		end
		vim.api.nvim_chan_send(Job, "clear\n( " .. exp_str .. " )\n")
	end

	-- Escape to close the terminal split
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_buf_delete(Bufnr, { force = true })
	end, { buffer = Bufnr })

	-- TODO: re-enable
	-- vim.keymap.set({ "n" }, keycodes, function()
	--   vim.notify(cmd, vim.log.levels.DEBUG, {})
	--   run_job()
	-- end, {})

	Augroup_id = vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
		pattern = pattern,
		callback = run_job,
	})

	vim.api.nvim_create_user_command("ReRunStop", function()
		-- vim.api.nvim_del_augroup_by_id(Augroup_id)
		vim.api.nvim_del_augroup_by_name(augroup_name)
		vim.api.nvim_buf_delete(Bufnr, { force = true })
	end, { desc = "Stop Active rerecmd" })

	run_job()
end

return M
