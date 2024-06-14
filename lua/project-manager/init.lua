local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")
local t_make_entry = require("telescope.make_entry")
local t_conf = require("telescope.config").values

local custom_previewers = require("project-manager.telescope.previewers")
local custom_make_entry = require("project-manager.telescope.make_entry")
local custom_sorters = require("project-manager.telescope.sorters")
local custom_utils = require("project-manager.telescope.utils")

local M = {}

local DEFAULT_OPTS = {
	icons = {
		folder = {
			default = "",
			open = "",
			empty = "",
			empty_open = "",
		},
	},
	highlights = {
		finder_folder_icon_default = {
			name = "PMFinderFolderIconDefault",
			fg = "#7AA2F7",
			bg = "",
		},
		finder_folder_icon_empty = {
			name = "PMFinderFolderIconEmpty",
			fg = "#7AA2F7",
			bg = "",
		},
		finder_folder_path = {
			name = "PMFinderFolderPath",
			fg = "",
			bg = "",
		},
		finder_filter_matching = {
			name = "PMFinderFilterMatching",
			fg = "#E0AF68",
			bg = "",
		},
		previewer_folder_icon = {
			name = "PMPreviewerFolderIcon",
			fg = "#7AA2F7",
			bg = "",
		},
		previewer_folder_name = {
			name = "PMPreviewerFolderName",
			fg = "#7AA2F7",
			bg = "",
		},
		previewer_file_name = {
			name = "PMPreviewerFileName",
			fg = "#E0AF68",
			bg = "",
		},
		previewer_tree_indent = {
			name = "PMPreviewerTreeIndent",
			fg = "#7AA2F7",
			bg = "",
		},
		previewer_tree_root_path = {
			name = "PMPreviewerTreeRootPath",
			fg = "#7AA2F7",
			bg = "",
		},
	},
	fd = {
		default_exclude = {
			"node_modules",
			".git",
		},
	},
	eza = {
		default_exclude = {
			"node_modules",
			".git",
		},
	},
}

local function merge_options(conf)
	return vim.tbl_deep_extend("force", DEFAULT_OPTS, conf or {})
end

local function validate_options(conf)
	return conf
end

local function setup_hl(hls)
	local set_hl = vim.api.nvim_set_hl
	for _, v in pairs(hls) do
		set_hl(0, v.name, { fg = v.fg, bg = v.bg, gui = v.gui, sp = v.sp, reverse = v.reverse })
	end
end

M.setup = function(conf)
	validate_options(conf)

	local opts = merge_options(conf)
	M.config = opts

	setup_hl(M.config.highlights)
end

M.get_icons = function()
	return M.config.icons
end

M.get_hls = function()
	return M.config.highlights
end

M.get_config = function(key)
	return M.config[key]
end

local escape_char_map = {
	["/"] = "\\/",
	["\\"] = "\\\\",
	["-"] = "\\-",
	["("] = "\\(",
	[")"] = "\\)",
	["["] = "\\[",
	["]"] = "\\]",
	["{"] = "\\{",
	["}"] = "\\}",
	["?"] = "\\?",
	["+"] = "\\+",
	["*"] = "\\*",
	["^"] = "\\^",
	["$"] = "\\$",
	["."] = "\\.",
}

M.find_files = function(opts)
	local find_command = (function()
		if opts.find_command then
			if type(opts.find_command) == "function" then
				return opts.find_command(opts)
			end
			return opts.find_command
		elseif 1 == vim.fn.executable("fd") then
			return { "fd", "--type", "f", "--color", "never" }
		end
	end)()

	if not find_command then
		utils.notify("project-manager.find_files", {
			msg = "You need to install fd",
			level = "ERROR",
		})
		return
	end

	local hidden = opts.hidden
	local no_ignore = opts.no_ignore
	local no_ignore_parent = opts.no_ignore_parent
	local follow = opts.follow
	local search_dirs = opts.search_dirs

	if search_dirs then
		for k, v in pairs(search_dirs) do
			search_dirs[k] = utils.path_expand(v)
		end
	end

	if hidden then
		find_command[#find_command + 1] = "--hidden"
	end
	if no_ignore then
		find_command[#find_command + 1] = "--no-ignore"
	end
	if no_ignore_parent then
		find_command[#find_command + 1] = "--no-ignore-parent"
	end
	if follow then
		find_command[#find_command + 1] = "-L"
	end
	if search_dirs then
		vim.list_extend(find_command, search_dirs)
	end
	if opts.cwd then
		opts.cwd = utils.path_expand(opts.cwd)
	end
	if opts.exclude then
		if type(opts.exclude) == "table" then
			for _, exclude in ipairs(opts.exclude) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		elseif type(opts.exclude) == "string" then
			vim.list_extend(find_command, { "--exclude", opts.exclude })
		end
	else
		local default_excludes = M.get_config("fd").default_exclude

		if type(default_excludes) == "table" then
			for _, exclude in ipairs(default_excludes) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		elseif type(default_excludes) == "string" then
			vim.list_extend(find_command, { "--exclude", default_excludes })
		end
	end

	opts.entry_maker = opts.entry_maker or t_make_entry.gen_from_file(opts)

	return pickers
		.new(opts, {
			prompt_title = "Find Files",
			__locations_input = true,
			finder = finders.new_oneshot_job(find_command, opts),
			previewer = t_conf.grep_previewer(opts),
			sorter = t_conf.file_sorter(opts),
			debounce = 150,
		})
		:find()
end

M.find_dirs = function(opts)
	local find_command = (function()
		if opts.find_command then
			if type(opts.find_command) == "function" then
				return opts.find_command(opts)
			end
			return opts.find_command
		elseif 1 == vim.fn.executable("fd") then
			return { "fd", "--type", "d", "--color", "never" }
		end
	end)()

	if not find_command then
		utils.notify("project-manager.find_dirs", {
			msg = "You need to install fd",
			level = "ERROR",
		})
		return
	end

	local hidden = opts.hidden
	local no_ignore = opts.no_ignore
	local no_ignore_parent = opts.no_ignore_parent
	local follow = opts.follow
	local search_dirs = opts.search_dirs

	if search_dirs then
		for k, v in pairs(search_dirs) do
			search_dirs[k] = utils.path_expand(v)
		end
	end

	if hidden then
		find_command[#find_command + 1] = "--hidden"
	end
	if no_ignore then
		find_command[#find_command + 1] = "--no-ignore"
	end
	if no_ignore_parent then
		find_command[#find_command + 1] = "--no-ignore-parent"
	end
	if follow then
		find_command[#find_command + 1] = "-L"
	end
	if search_dirs then
		vim.list_extend(find_command, search_dirs)
	end
	if opts.cwd then
		opts.cwd = utils.path_expand(opts.cwd)
	end
	if opts.exclude then
		if type(opts.exclude) == "table" then
			for _, exclude in ipairs(opts.exclude) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		elseif type(opts.exclude) == "string" then
			vim.list_extend(find_command, { "--exclude", opts.exclude })
		end
	else
		local default_excludes = M.get_config("fd").default_exclude

		if type(default_excludes) == "table" then
			for _, exclude in ipairs(default_excludes) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		elseif type(default_excludes) == "string" then
			vim.list_extend(find_command, { "--exclude", default_excludes })
		end
	end

	opts.__highlight = M.get_hls()
	opts.__icons = M.get_icons()
	opts.__eza_exclude = M.get_config("eza").default_exclude

	opts.entry_maker = opts.entry_maker or custom_make_entry.gen_from_dir(opts)

	return pickers
		.new(opts, {
			prompt_title = "Find Directories",
			finder = finders.new_oneshot_job(find_command, opts),
			previewer = custom_previewers.eza(opts),
			sorter = custom_sorters.fzy_dir_sorter(opts),
			debounce = 150,
		})
		:find()
end

M.live_find_dirs = function(opts)
	local find_command = (function()
		if opts.find_command then
			if type(opts.find_command) == "function" then
				return opts.find_command(opts)
			end
			return opts.find_command
		elseif 1 == vim.fn.executable("fd") then
			return { "fd", "--type", "d", "--color", "never", "--regex", "--full-path" }
		end
	end)()

	if not find_command then
		utils.notify("project-manager.live_find_dirs", {
			msg = "You need to install fd",
			level = "ERROR",
		})
		return
	end

	local hidden = opts.hidden
	local no_ignore = opts.no_ignore
	local no_ignore_parent = opts.no_ignore_parent
	local follow = opts.follow
	local search_dirs = opts.search_dirs

	if search_dirs then
		for k, v in pairs(search_dirs) do
			search_dirs[k] = utils.path_expand(v)
		end
	end

	if hidden then
		find_command[#find_command + 1] = "--hidden"
	end
	if no_ignore then
		find_command[#find_command + 1] = "--no-ignore"
	end
	if no_ignore_parent then
		find_command[#find_command + 1] = "--no-ignore-parent"
	end
	if follow then
		find_command[#find_command + 1] = "-L"
	end
	if search_dirs then
		vim.list_extend(find_command, search_dirs)
	end
	if opts.cwd then
		opts.cwd = utils.path_expand(opts.cwd)
	end
	if opts.exclude then
		if type(opts.exclude) == "table" then
			for _, exclude in ipairs(opts.exclude) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		else
			vim.list_extend(find_command, { "--exclude", opts.exclude })
		end
	else
		local default_excludes = M.get_config("fd").default_exclude
		for _, exclude in ipairs(default_excludes) do
			vim.list_extend(find_command, { "--exclude", exclude })
		end
	end

	opts.__highlight = M.get_hls()
	opts.__icons = M.get_icons()
	opts.__eza_exclude = M.get_config("eza").default_exclude

	opts.entry_maker = opts.entry_maker or custom_make_entry.gen_from_dir(opts)

	local generate_prompt = function(prompt)
		prompt = custom_utils.format_prompt(prompt)
		local prompt_generated = ".*"

		for i = 1, #prompt do
			local char = string.sub(prompt, i, i)
			local escaped_char = escape_char_map[char] or char
			prompt_generated = prompt_generated .. escaped_char .. ".*"
		end

		return prompt_generated
	end

	return pickers
		.new(opts, {
			prompt_title = "Live Find Directories",
			finder = finders.new_job(function(prompt)
				if not prompt or prompt == "" then
					return nil
				end
				return utils.flatten({ find_command, generate_prompt(prompt) })
			end, opts.entry_maker, _, opts.cwd),
			previewer = custom_previewers.eza(opts),
			sorter = custom_sorters.fzy_dir_sorter(opts),
			debounce = 150,
		})
		:find()
end

return M
