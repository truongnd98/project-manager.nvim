local t_actions = require("telescope.actions")
local t_action_state = require("telescope.actions.state")

local pm_state = require("project-manager.project.state")

local M = {}

M.select_project = function(prompt_bufnr)
	local entry = t_action_state.get_selected_entry()
	if not entry then
		return
	end

	local choice = vim.fn.confirm(string.format('Open project "%s"?', entry.value), "&Yes\n&No")
	if choice == 1 then
		pm_state.add_project({
			path = entry.cwd .. "/" .. entry.value,
			entry = { cwd = entry.cwd, value = entry.value },
		})
		t_actions.select_default(prompt_bufnr)
	end
end

M.remove_project = function(prompt_bufnr)
	local entry = t_action_state.get_selected_entry()
	if not entry then
		return
	end

	local choice = vim.fn.confirm(string.format('Remove project "%s"?', entry.value), "&Yes\n&No")
	if choice == 1 then
		pm_state.remove_project_from_path(entry.cwd .. "/" .. entry.value)
	end
end

return M
