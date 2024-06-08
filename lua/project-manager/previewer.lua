local utils = require("telescope.utils")
local Path = require("plenary.path")
local from_entry = require("telescope.from_entry")

local defaulter = utils.make_default_callable

local previewers = {}

previewers.eza = defaulter(function(opts)
	opts = opts or {}

	local cwd = opts.cwd or vim.loop.cwd()

	return previewers.new_termopen_previewer({
		title = "Eza Preview",
		dyn_title = function(_, entry)
			return Path:new(from_entry.path(entry, false, false)):normalize(cwd)
		end,

		get_command = function(entry)
			local dirname = from_entry.path(entry, true, false)
			if dirname == nil or dirname == "" then
				return
			end

			if not vim.fn.executable("eza") then
				utils.notify("previewers.eza", {
					msg = "You need to install either `eza` or `ls`",
					level = "ERROR",
				})
				return
			end

			return { "eza", "--tree", utils.path_expand(dirname) }
		end,
	})
end, {})

return previewers
