---@class KTerm
local KTerm = {}
local H = {}

-- Setup
function KTerm.setup()
	_G.KTerm = KTerm

	H.create_keybinds()
	H.create_user_commands()
end

-- Run Command in Floating Window
---@param command string
function KTerm.run_cmd(command)
	if not vim.fn.executable(command) == 1 then
		vim.notify("!!! Please Install " .. command .. " !!!", vim.log.levels.ERROR)
		return
	end

	KTerm.state.job = H.createFloatingWin({ buf = KTerm.state.job.buf, title = command })
	vim.fn.jobstart(command, {
		term = true,
		on_exit = function()
			vim.api.nvim_win_close(KTerm.state.job.win, true)
			vim.api.nvim_buf_delete(KTerm.state.job.buf, { force = true })
		end,
	})

	vim.cmd.startinsert()
end

-- Open Terminal in Floating Window
function KTerm.terminal()
	KTerm.state.terminal = H.createFloatingWin({ buf = KTerm.state.terminal.buf })
	if vim.bo[KTerm.state.terminal.buf].buftype ~= "terminal" then
		vim.cmd.terminal()
		vim.keymap.set("n", "<c-q>", function()
			vim.api.nvim_win_hide(0)
		end, { buffer = true, noremap = true, silent = true })
	end
	vim.cmd.startinsert()
end

-- Terminal and Job Data
---@class KTerm.State
KTerm.state = {
	terminal = {
		win = -1,
		buf = -1,
	},
	job = {
		buf = -1,
		win = -1,
	},
}

-- Helper functionality =======================================================

-- Set keybinds
function H.create_keybinds()
	vim.keymap.set("t", "<c-q>", "<c-\\><c-n>", {
	    desc = "Exit Terminal Mode",
	    noremap = true,
	    silent = true,
	})
end

-- Window creation hook
---@param opts? vim.api.keyset.win_config|{ buf: integer }
---@return { buf: integer, win: integer }
function H.createFloatingWin(opts)
	opts = opts or {}
	local width = math.floor(vim.o.columns * (opts.width or 0.8))
	local height = math.floor(vim.o.lines * (opts.height or 0.8))
	local buf = vim.api.nvim_buf_is_valid(opts.buf) and opts.buf
	    or vim.api.nvim_create_buf(false, true)

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

-- User Command creator
function H.create_user_commands()
	vim.api.nvim_create_user_command("Term", function(opts)
		if opts.args == "" then
			KTerm.terminal()
		else
			KTerm.run_cmd(opts.args)
		end
	end, { nargs = "*" })
end

return KTerm
