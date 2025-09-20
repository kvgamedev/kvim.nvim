---@class KPlug
local M = {}
local H = {}

-- Add Spec(s)
function M.add(opts)
	if type(opts) == "string" then
		H.packadd(H.set_src(opts))
	else
		H.check_table(opts)
	end
end

-- Recursively check for spec tables inside spec tables
function H.check_table(opts)
	for _, i in ipairs(opts) do
		if type(i) == "table" then
			H.check_table(i)
			H.install_spec(i)
		elseif type(i) == "string" then
			H.packadd(H.set_src(i))
		end
	end
	H.install_spec(opts)
end

-- Add spec
function H.packadd(spec)
	vim.pack.add({ spec }, { confirm = false })
end

-- Get spec data, then execute installation
function H.install_spec(opts)
	opts = opts or {}

	opts = H.find_src(opts)
	if not opts.src then
		if opts.config then
			opts.config()
		end
	end
	opts.src = H.set_src(opts.src)

	if opts.lazy then
		if opts.event then
			H.lazy_load(function()
				H.exec_installation(opts)
			end, opts.event)
			return
		end
		H.lazy_load(function()
			H.exec_installation(opts)
		end)
		return
	end
	H.exec_installation(opts)
end

-- Lazy Load spec
local gr = vim.api.nvim_create_augroup("LazyLoad", { clear = true })
function H.lazy_load(callback, event)
	if event then
		vim.api.nvim_create_autocmd(event, {
			pattern = "*",
			once = true,
			group = gr,
			callback = callback,
		})
		return
	end
	vim.api.nvim_create_autocmd("UIEnter", {
		pattern = "*",
		once = true,
		group = gr,
		callback = function()
			vim.defer_fn(callback, 0)
		end,
	})
end

-- Install spec and execute config function
function H.exec_installation(opts)
	if opts.dependencies then
		M.add(opts.dependencies)
	end

	if opts.src then
		H.packadd({ src = opts.src, name = opts.name, version = opts.version })
	end
	if opts.config then
		opts.config()
	end
end

-- Get source in spec, either a plain string or, spec.src
function H.find_src(opts)
	if not opts.src then
		for _, i in ipairs(opts) do
			if type(i) == "string" then
				opts.src = i
			end
		end
	end
	return opts
end

-- prepend github url, so the user only needs to add user/repository as source
-- if the src begins with https, then it will be used as is
function H.set_src(src)
	if src:sub(1, 5) == "https" or src == nil then
		return src
	else
		return "https://github.com/" .. src
	end
end

-- Set Global variable KPlug
_G.KPlug = M
return M
