local previewers = require("telescope.previewers")
local utils = require("telescope.utils")
local Path = require("plenary.path")
local putils = require("telescope.previewers.utils")
local from_entry = require("telescope.from_entry")

local M = {}

M.eza = function(opts)
	opts = opts or {}

	local cwd = opts.cwd or vim.loop.cwd()

	return previewers.new_termopen_previewer({
		title = "Eza Preview",
		dyn_title = function(_, entry)
			return Path:new(from_entry.path(entry, false, false)):normalize(cwd)
		end,

		get_buffer_by_name = function(_, entry)
			return from_entry.path(entry, false, false)
		end,

		get_command = function(entry)
			local dirname = from_entry.path(entry, true, false)
			if dirname == nil or dirname == "" then
				return
			end

			if not vim.fn.executable("eza") then
				utils.notify("project-manager.previewer.eza", {
					msg = "You need to install either eza",
					level = "ERROR",
				})
				return
			end

			return { "eza", "--tree", "--icons", "always", "--", utils.path_expand(dirname) }
		end,

		define_preview = function(self, entry)
			local dirname = from_entry.path(entry, true, false)
			if dirname == nil or dirname == "" then
				return
			end

			if not vim.fn.executable("eza") then
				utils.notify("project-manager.previewer.eza", {
					msg = "You need to install eza",
					level = "ERROR",
				})
				return
			end

			local cmd = { "eza", "--tree", "--icons", "always", "--", utils.path_expand(dirname) }

			putils.job_maker(cmd, self.state.bufnr, {
				value = entry.value,
				bufname = self.state.bufname,
				cwd = opts.cwd,
				callback = function(bufnr, content)
					if not content then
						return
					end

					utils.notify("previewer.eza", {
						msg = vim.inspect(content),
						level = "INFO",
					})
				end,
			})
		end,
	})
end

return M
