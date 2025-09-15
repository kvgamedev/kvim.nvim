---@module "lazy"

---@class KPlug
local KPlug = {}
local H = {}

-- Setup hook
function KPlug.setup()
	_G.KPlug = KPlug
end

---@param opts LazySpec
function KPlug.add(opts)
	if opts.lazy and type(opts.lazy) == "boolean" then
		local event = opts.event or nil
		H.lazy_load(function()
			H.add_plugin(opts)
		end, event)

		return
	end
	H.add_plugin(opts)
end

-- Helper Functionality ========================================================

-- Add Plugin
---@param opts LazySpec
function H.add_plugin(opts)
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
		vim.pack.add({ { src = H.check_string_prefix(opts) } }, { confirm = false })
		return
	end

	if type(opts) == "table" then
		H.check_multi_spec(opts)
	end
end

---@param opts LazySpec[]|LazySpec
function H.check_multi_spec(opts)
	for _, spec in ipairs(opts) do
		if type(spec) == "table" then
			H.check_multi_spec(spec)
			H.install_spec(spec)
		end
	end
	H.install_spec(opts)
end

---@param str string
---@return string
function H.check_string_prefix(str)
	if str:sub(1,5) == "https" then
		return str
	end

	return "https://github.com" .. (str:sub(1, 1) ~= "/" and "/" or "") .. str
end

---@param opts vim.pack.Spec|{ config?: fun() }|{ src?: string }
function H.install_spec(opts)
	local src = ""
	if opts.src then
		src = H.check_string_prefix(opts.src)
	else
		for _, i in ipairs(opts) do
			if type(i) == "string" then
				src = H.check_string_prefix(i)
			end
		end
	end
	if src == "" then
		return
	end

	---@type vim.pack.keyset.add
	local add_opts = { confirm = false }

	---@type vim.pack.Spec
	local spec = { src = src }

	if opts.name then
		spec.name = opts.name
	end
	if opts.version then
		spec.version = opts.version
	end

	vim.pack.add({ spec }, add_opts)

	if opts.config and vim.is_callable(opts.config) then
		opts.config()
	end
end

-- Lazy Load Plugin
---@param callback fun(args?: vim.api.keyset.create_autocmd.callback_args)
---@param event? string
function H.lazy_load(callback, event)
	local gr = vim.api.nvim_create_augroup("LazyLoad", { clear = false })
	local ev = event ~= nil and event or "UIEnter"
	vim.api.nvim_create_autocmd(ev, {
		pattern = "*",
		once = true,
		group = gr,
		callback = ev ~= "UIEnter" and callback or function()
			vim.defer_fn(callback, 0)
		end,
	})
end

return KPlug
