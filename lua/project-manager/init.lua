local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")
local conf = require("telescope.config").values
local log = require("telescope.log")

local previewers = require("project-manager.previewer")

local flatten = utils.flatten

local M = {}

M.find_dirs = function(opts)
	local find_command = (function()
		if opts.find_command then
			if type(opts.find_command) == "function" then
				return opts.find_command(opts)
			end
			return opts.find_command
		elseif 1 == vim.fn.executable("fd") then
			return { "fd", "--type", "d", "--color", "never" }
		elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
			return { "find", ".", "-type", "d" }
		end
	end)()

	if not find_command then
		utils.notify("M.find_dirs", {
			msg = "You need to install either `fd` or `find`",
			level = "ERROR",
		})
		return
	end

	local command = find_command[1]
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

	if command == "fd" then
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
	elseif command == "find" then
		if not hidden then
			table.insert(find_command, { "-not", "-path", "*/.*" })
			find_command = flatten(find_command)
		end
		if no_ignore ~= nil then
			log.warn("The `no_ignore` key is not available for the `find` command in `find_files`.")
		end
		if no_ignore_parent ~= nil then
			log.warn("The `no_ignore_parent` key is not available for the `find` command in `find_files`.")
		end
		if follow then
			table.insert(find_command, 2, "-L")
		end
		if search_dirs then
			table.remove(find_command, 2)
			for _, v in pairs(search_dirs) do
				table.insert(find_command, 2, v)
			end
		end
	end

	if opts.cwd then
		opts.cwd = utils.path_expand(opts.cwd)
	end

	opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

	print(vim.inspect(find_command))

	return pickers
		.new(opts, {
			prompt_title = "Find Directories",
			__locations_input = true,
			finder = finders.new_oneshot_job(find_command, opts),
			previewer = previewers.eza(opts),
			sorter = conf.file_sorter(opts),
		})
		:find()
end

return M
