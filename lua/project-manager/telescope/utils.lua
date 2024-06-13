local M = {}

M.format_prompt = function(prompt)
	-- Remove the first character if it is a slash
	local prompt_formated = string.gsub(prompt, "^/", "")
	return prompt_formated
end

return M
