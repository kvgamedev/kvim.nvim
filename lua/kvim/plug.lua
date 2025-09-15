local M = {}
local H = {}

M.add = function(opts)
	if type(opts) == "string" then
		H.packadd(H.set_src(opts))
	else
		H.check_table(opts)
	end
end

H.check_table = function(opts)
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

H.packadd = function(spec)
	vim.pack.add({ spec }, { confirm = true })
end

H.install_spec = function(opts)
	opts = opts or {}

	opts = H.find_src(opts)
	if not opts.src then
		return
	end
	opts.src = H.set_src(opts.src)

	if opts.lazy then
		if opts.event then
			H.lazy_load(function() H.exec_installation(opts) end, opts.event)
		else
			H.lazy_load(function() H.exec_installation(opts) end)
		end
	else
		H.exec_installation(opts)
	end
end

local gr = vim.api.nvim_create_augroup("LazyLoad", { clear = true })
H.lazy_load = function(callback, event)
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

H.exec_installation = function(opts)
	if opts.dependencies then
		M.add(opts.dependencies)
	end

	H.packadd({ src = opts.src, name = opts.name, version = opts.version })
	if opts.config then opts.config() end
end

H.find_src = function(opts)
	if not opts.src then
		for _, i in ipairs(opts) do
			if type(i) == "string" then
				opts.src = i
			end
		end
	end
	return opts
end

H.set_src = function(src)
	if src:sub(1, 5) == "https" then
		return src
	else
		return "https://github.com/" .. src
	end
end

_G.KPLUG = M
return M
