ProjectManagerState = ProjectManagerState or {}
ProjectManagerState.entry_state = {}

local M = {}

M.get_entry_state = function()
	return ProjectManagerState.entry_state
end

---Get entry by path
---@param path string
---@return { path: string, type: string, is_empty: boolean } | nil
M.get_entry_by_path = function(path)
	return ProjectManagerState.entry_state[path]
end

---Set entry
---@param entry {path: string, type: string, is_empty: boolean}
M.set_entry = function(entry)
	ProjectManagerState.entry_state[entry.path] = entry
end

return M
