local t_finders = require("telescope.finders")
local t_pickers = require("telescope.pickers")
local t_conf = require("telescope.config").values
local t_builtin = require("telescope.builtin")
local t_make_entry = require("telescope.make_entry")
local t_utils = require("telescope.utils")

local pm = require("project-manager")
local pm_t_previewers = require("project-manager.telescope.previewers")
local pm_t_make_entry = require("project-manager.telescope.make_entry")
local pm_t_sorters = require("project-manager.telescope.sorters")
local pm_t_utils = require("project-manager.telescope.utils")
local pm_state = require("project-manager.project.state")
local pm_actions = require("project-manager.telescope.actions")

local M = {}

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
		t_utils.notify("project-manager.telescope.find_files", {
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
			search_dirs[k] = t_utils.path_expand(v)
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
		opts.cwd = t_utils.path_expand(opts.cwd)
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
		local default_excludes = pm.get_config("fd").default_exclude

		if type(default_excludes) == "table" then
			for _, exclude in ipairs(default_excludes) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		elseif type(default_excludes) == "string" then
			vim.list_extend(find_command, { "--exclude", default_excludes })
		end
	end

	opts.entry_maker = opts.entry_maker or t_make_entry.gen_from_file(opts)

	return t_pickers
		.new(opts, {
			prompt_title = "Find Files",
			__locations_input = true,
			finder = t_finders.new_oneshot_job(find_command, opts),
			previewer = t_conf.grep_previewer(opts),
			sorter = t_conf.file_sorter(opts),
			debounce = 150,
		})
		:find()
end

M.live_grep = function(opts)
	opts.vimgrep_arguments = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		"--smart-case",
	}

	local hidden = opts.hidden
	local no_ignore = opts.no_ignore

	if hidden then
		table.insert(opts.vimgrep_arguments, "--hidden")
	end

	if no_ignore then
		table.insert(opts.vimgrep_arguments, "--no-ignore")
	end

	if opts.exclude then
		if type(opts.exclude) == "table" then
			for _, exclude in ipairs(opts.exclude) do
				table.insert(opts.vimgrep_arguments, "--glob")
				table.insert(opts.vimgrep_arguments, "!" .. exclude)
			end
		elseif type(opts.exclude) == "string" then
			table.insert(opts.vimgrep_arguments, "--glob")
			table.insert(opts.vimgrep_arguments, "!" .. opts.exclude)
		end
	else
		local default_excludes = pm.get_config("rg").default_exclude
		if type(default_excludes) == "table" then
			for _, exclude in ipairs(default_excludes) do
				table.insert(opts.vimgrep_arguments, "--glob")
				table.insert(opts.vimgrep_arguments, "!" .. exclude)
			end
		elseif type(default_excludes) == "string" then
			table.insert(opts.vimgrep_arguments, "--glob")
			table.insert(opts.vimgrep_arguments, "!" .. default_excludes)
		end
	end

	return t_builtin.live_grep(opts)
end

M.grep_string = function(opts)
	opts.vimgrep_arguments = {
		"rg",
		"--color=never",
		"--no-heading",
		"--with-filename",
		"--line-number",
		"--column",
		"--smart-case",
	}

	local hidden = opts.hidden
	local no_ignore = opts.no_ignore

	if hidden then
		table.insert(opts.vimgrep_arguments, "--hidden")
	end

	if no_ignore then
		table.insert(opts.vimgrep_arguments, "--no-ignore")
	end

	if opts.exclude then
		if type(opts.exclude) == "table" then
			for _, exclude in ipairs(opts.exclude) do
				table.insert(opts.vimgrep_arguments, "--glob")
				table.insert(opts.vimgrep_arguments, "!" .. exclude)
			end
		elseif type(opts.exclude) == "string" then
			table.insert(opts.vimgrep_arguments, "--glob")
			table.insert(opts.vimgrep_arguments, "!" .. opts.exclude)
		end
	else
		local default_excludes = pm.get_config("rg").default_exclude
		if type(default_excludes) == "table" then
			for _, exclude in ipairs(default_excludes) do
				table.insert(opts.vimgrep_arguments, "--glob")
				table.insert(opts.vimgrep_arguments, "!" .. exclude)
			end
		elseif type(default_excludes) == "string" then
			table.insert(opts.vimgrep_arguments, "--glob")
			table.insert(opts.vimgrep_arguments, "!" .. default_excludes)
		end
	end

	return t_builtin.grep_string(opts)
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
		t_utils.notify("project-manager.telescope.find_dirs", {
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
			search_dirs[k] = t_utils.path_expand(v)
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
		opts.cwd = t_utils.path_expand(opts.cwd)
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
		local default_excludes = pm.get_config("fd").default_exclude

		if type(default_excludes) == "table" then
			for _, exclude in ipairs(default_excludes) do
				vim.list_extend(find_command, { "--exclude", exclude })
			end
		elseif type(default_excludes) == "string" then
			vim.list_extend(find_command, { "--exclude", default_excludes })
		end
	end

	opts.__highlight = pm.get_hls()
	opts.__icons = pm.get_icons()
	opts.__eza_exclude = pm.get_config("eza").default_exclude

	opts.entry_maker = opts.entry_maker or pm_t_make_entry.gen_from_dir(opts)

	return t_pickers
		.new(opts, {
			prompt_title = "Find Directories",
			finder = t_finders.new_oneshot_job(find_command, opts),
			previewer = pm_t_previewers.eza(opts),
			sorter = pm_t_sorters.fzy_dir_sorter(opts),
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
			return { "fd", "--type", "d", "--color", "never", "--regex", "--full-path", "--max-results", "100" }
		end
	end)()

	if not find_command then
		t_utils.notify("project-manager.telescope.live_find_dirs", {
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
			search_dirs[k] = t_utils.path_expand(v)
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
		opts.cwd = t_utils.path_expand(opts.cwd)
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
		local default_excludes = pm.get_config("fd").default_exclude
		for _, exclude in ipairs(default_excludes) do
			vim.list_extend(find_command, { "--exclude", exclude })
		end
	end

	opts.__highlight = pm.get_hls()
	opts.__icons = pm.get_icons()
	opts.__eza_exclude = pm.get_config("eza").default_exclude

	opts.entry_maker = opts.entry_maker or pm_t_make_entry.gen_from_dir(opts)

	local generate_prompt = function(prompt)
		prompt = pm_t_utils.format_prompt(prompt)
		local prompt_generated = ".*"

		for i = 1, #prompt do
			local char = string.sub(prompt, i, i)
			local escaped_char = escape_char_map[char] or char
			prompt_generated = prompt_generated .. escaped_char .. ".*"
		end

		return prompt_generated
	end

	return t_pickers
		.new(opts, {
			prompt_title = "Live Find Directories",
			finder = t_finders.new_job(function(prompt)
				if not prompt or prompt == "" then
					return nil
				end
				return t_utils.flatten({ find_command, generate_prompt(prompt) })
			end, opts.entry_maker, _, opts.cwd),
			previewer = pm_t_previewers.eza(opts),
			sorter = pm_t_sorters.fzy_dir_sorter(opts),
			debounce = 150,
		})
		:find()
end

M.find_projects = function(opts)
	local projects = pm_state.get_project_list()
	local project_list = {}
	for _, project in pairs(projects) do
		table.insert(project_list, project.entry.value)
	end

	opts.__highlight = pm.get_hls()
	opts.__icons = pm.get_icons()
	opts.__eza_exclude = pm.get_config("eza").default_exclude

	opts.entry_maker = opts.entry_maker or pm_t_make_entry.gen_from_dir(opts)
	return t_pickers
		.new(opts, {
			prompt_title = "Find Projects",
			__locations_input = true,
			finder = t_finders.new_table({
				results = project_list,
				entry_maker = opts.entry_maker,
			}),
			previewer = pm_t_previewers.eza(opts),
			sorter = pm_t_sorters.fzy_dir_sorter(opts),
			attach_mappings = function(_, map)
				map("n", "<CR>", pm_actions.select_project)
				map("i", "<CR>", pm_actions.select_project)
				map("n", "d", pm_actions.remove_project)
				return true
			end,
		})
		:find()
end

M.find_and_open_project = function(opts)
	opts.attach_mappings = function(_, map)
		map("n", "<CR>", pm_actions.select_project)
		map("i", "<CR>", pm_actions.select_project)
		return true
	end
	return M.find_dirs(opts)
end

M.live_find_and_open_project = function(opts)
	opts.attach_mappings = function(_, map)
		map("n", "<CR>", pm_actions.select_project)
		map("i", "<CR>", pm_actions.select_project)
		return true
	end
	return M.live_find_dirs(opts)
end

return M
