local KPlug = {}
local H = {}

-- Setup ----------------------------------------------------------------------
KPlug.setup = function()
	_G.KPlug = KPlug
end

-- Manage Plugin --------------------------------------------------------------
KPlug.add = function(opts)
	if opts.lazy then
		if opts.event then
			H.lazy_load(function()
				H.add_plugin(opts)
			end, opts.event)
		else
			H.lazy_load(function()
				H.add_plugin(opts)
			end)
		end
		return
	end
	H.add_plugin(opts)
end

-- Helper Functionality ========================================================
-- Add Plugin ------------------------------------------------------------------
H.add_plugin = function(opts)
	if opts.dependencies then
		if type(opts.dependencies) == "table" then
			for _, dependency in ipairs(opts.dependencies) do
				H.add_plugin(dependency)
			end
		else
			H.add_plugin(opts.dependencies)
		end
	end

	if type(opts) == "string" then
		vim.pack.add({ { src = "https://github.com/" .. opts } }, { confirm = false })
		return
	elseif type(opts) == "table" then
		if H.check_multi_spec(opts) == true then
			for _, i in ipairs(opts) do
				H.install_spec(i)
			end
		else
			H.install_spec(opts)
		end
	end
end

H.check_multi_spec = function(opts)
		local multi_spec = false
		for _, i in ipairs(opts) do
			if type(i) == "table" then
				multi_spec = true
			end
		end
		return multi_spec
end
H.install_spec = function(opts)
	local src = "https://github.com/" .. opts.src
	if opts.name and opts.version then
		vim.pack.add({ { src = src, name = opts.name, version = opts.version } }, { confirm = false })
	elseif opts.name then
		vim.pack.add({ { src = src, name = opts.name } }, { confirm = false })
	elseif opts.version then
		vim.pack.add({ { src = src, version = opts.version } }, { confirm = false })
	else
		vim.pack.add({ { src = src } }, { confirm = false })
	end

	if opts.config then
		opts.config()
	end
end
-- Lazy Load Plugin ------------------------------------------------------------
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

return KPlug
