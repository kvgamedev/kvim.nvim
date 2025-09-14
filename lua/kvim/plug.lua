local KPlug = {}
local H = {}

-- Setup ----------------------------------------------------------------------
KPlug.setup = function()
	_G.KPlug = KPlug
end

-- Manage Plugin --------------------------------------------------------------
---src: format: username/repo
---version: plugin version to use, can be a commit or vim.version.range
---name: name of the plugin
---config: function to execute after plugin installation
---lazy: lazy load the plugin? default false
---event: if lazy loading, additionally specify the vim event which triggers the installation, eg. "InsertEnter"
---@class opts: table
---@field src? string
---@field name? string
---@field version? vim.VersionRange|string
---@field config? function
---@field lazy? boolean
---@field event? string
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
		H.check_multi_spec(opts)
	end
end

H.check_multi_spec = function(opts)
	for _, i in ipairs(opts) do
		if type(i) == "table" then
			H.check_multi_spec(i)
			H.install_spec(i)
		end
	end
	H.install_spec(opts)
end

H.install_spec = function(opts)
	local src = ""
	if opts.src then
		src = "https://github.com/" .. opts.src
	else
		for _, i in ipairs(opts) do
			if type(i) == "string" then
				src = "https://github.com/" .. i
			end
		end
	end
	if src == "" then
		return
	end

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
