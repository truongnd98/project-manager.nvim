ProjectManagerState = ProjectManagerState or {}
ProjectManagerState.project_state = {}

local M = {}

M.load = function()
	local p_state_dir = os.getenv("HOME") .. "/.local/state/nvim/project-manager.nvim/"

	local p_state_path = p_state_dir .. "state.json"

	if vim.fn.filereadable(p_state_path) == 0 then
		vim.fn.mkdir(p_state_dir, "p")
		vim.fn.writefile({ vim.fn.json_encode({ projects = {} }) }, p_state_path)
	end

	local state = vim.fn.json_decode(vim.fn.join(vim.fn.readfile(p_state_path)))
	ProjectManagerState.project_state = state or { projects = {} }
end

M.get_project_list = function()
	return ProjectManagerState.project_state.projects
end

M.add_project = function(project)
	ProjectManagerState.project_state.projects[project.path] = project
	M.persist()
end

M.persist = function()
	local p_state_path = os.getenv("HOME") .. "/.local/state/nvim/project-manager.nvim/state.json"
	vim.fn.writefile({ vim.fn.json_encode(ProjectManagerState.project_state) }, p_state_path)
end

M.remove_project_from_path = function(path)
	ProjectManagerState.project_state.projects[path] = nil
	M.persist()
end

return M
