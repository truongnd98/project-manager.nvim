local Job = require("plenary.job")
local Path = require("plenary.path")

local utils = require("telescope.utils")

local pm = require("project-manager")
local state = require("project-manager.telescope.state")

local M = {}

local handle_entry_index = function(opts, t, k)
	local override = ((opts or {}).entry_index or {})[k]
	if not override then
		return
	end

	local val, save = override(t, opts)
	if save then
		rawset(t, k, val)
	end
	return val
end

do
	local lookup_keys = {
		ordinal = 1,
		value = 1,
		filename = 1,
		cwd = 2,
	}

	M.gen_from_dir = function(opts)
		opts = opts or {}

		local cwd = utils.path_expand(opts.cwd or vim.loop.cwd())

		local disable_devicons = opts.disable_devicons

		local mt_dir_entry = {}

		mt_dir_entry.cwd = cwd
		mt_dir_entry.display = function(entry)
			local hl_group, icon
			local display, path_style = utils.transform_path(opts, entry.value)
			path_style = { { { 0, #icon + 1 }, pm.get_hls().finder_folder_path.name } }

			if disable_devicons then
				return display, path_style
			end

			local path = Path:new({ cwd, entry.value }):absolute()

			if not state.get_entry_by_path(path) then
				Job:new({
					command = "fd",
					args = {
						"-q",
						"--full-path",
						path,
					},
					env = opts.env,
					cwd = opts.cwd,
					on_exit = vim.schedule_wrap(function(_, exit_code)
						state.set_entry({ path, type = "directory", is_empty = exit_code == 1 })
					end),
				}):start()
			end

			local is_empty = state.get_entry_by_path(path).is_empty

			icon = pm.get_icons().folder.default
			hl_group = pm.get_hls().finder_folder_icon_default.name
			if is_empty then
				icon = pm.get_icons().folder.empty
				hl_group = pm.get_hls().finder_folder_icon_empty.name
			end

			display = icon .. " " .. display

			if hl_group then
				local style = { { { 0, #icon + 1 }, hl_group } }
				style = utils.merge_styles(style, path_style, #icon + 1)
				return display, style
			else
				return display, path_style
			end
		end

		mt_dir_entry.__index = function(t, k)
			local override = handle_entry_index(opts, t, k)
			if override then
				return override
			end

			local raw = rawget(mt_dir_entry, k)
			if raw then
				return raw
			end

			if k == "path" then
				local retpath = Path:new({ t.cwd, t.value }):absolute()
				if not vim.loop.fs_access(retpath, "R") then
					retpath = t.value
				end
				return retpath
			end

			return rawget(t, rawget(lookup_keys, k))
		end

		return function(line)
			return setmetatable({ line }, mt_dir_entry)
		end
	end
end

return M
