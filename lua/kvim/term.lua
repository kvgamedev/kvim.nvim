---@class KTerm
local M = {}
local H = {}

-- Setup
function M.setup()
	_G.KTerm = M

	H.create_user_commands()
	H.create_autocommands()
end

-- Run Command in Floating Window
function M.run_cmd(command)
	if not vim.fn.executable(command) == 1 then
		print("!!! Please Install " .. command .. " !!!")
		return
	end
	M.state.job = H.createFloatingWin({ buf = M.state.job.buf, title = command })
	vim.fn.jobstart(command, {
		term = true,
		on_exit = function()
			vim.api.nvim_win_close(M.state.job.win, true)
			vim.api.nvim_buf_delete(M.state.job.buf, { force = true })
		end,
	})
	vim.cmd.startinsert()
end

-- Open Terminal in Floating Window
function M.terminal()
	M.state.terminal = H.createFloatingWin({ buf = M.state.terminal.buf })
	if vim.bo[M.state.terminal.buf].buftype ~= "terminal" then
		vim.cmd.terminal()
		vim.keymap.set("n", "<c-q>", function()
			vim.api.nvim_win_hide(0)
		end, { buffer = true })
	end
	vim.cmd.startinsert()
end

-- Terminal & Job Data
---@class KTerm.State
M.state = {
	terminal = {
		win = -1,
		buf = -1,
	},
	job = {
		buf = -1,
		win = -1,
	},
}

-- HELPER
-- Window
function H.createFloatingWin(opts)
	opts = opts or {}
	local width = math.floor(vim.o.columns * (opts.width or 0.8))
	local height = math.floor(vim.o.lines * (opts.height or 0.8))
	local buf = nil
	if vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true)
	end

	local config = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = opts.style or "minimal",
		border = opts.border or "rounded",
		title = opts.title or "Floating Window",
		title_pos = "center",
	}
	local win = vim.api.nvim_open_win(buf, true, config)

	return { buf = buf, win = win }
end

-- Commands
function H.create_user_commands()
	vim.api.nvim_create_user_command("Term", function(opts)
		if opts.args == "" then
			M.terminal()
		else
			M.run_cmd(opts.args)
		end
	end, { nargs = "*" })
end

-- Autocommands
function H.create_autocommands()
	local gr = vim.api.nvim_create_augroup("KTerm", { clear = true })
	vim.api.nvim_create_autocmd("VimResized", {
		group = gr,
		callback = function()
			vim.cmd("windo wincmd =")
		end
	})
end

return M
