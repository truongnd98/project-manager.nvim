local sorters = require("telescope.sorters")

local utils = require("project-manager.telescope.utils")

local M = {}

M.fzy_dir_sorter = function(opts)
	opts = opts or {}
	local fzy = opts.fzy_mod or require("telescope.algos.fzy")
	local OFFSET = -fzy.get_score_floor()

	return sorters.Sorter:new({
		discard = true,

		scoring_function = function(_, prompt, line)
			prompt = utils.format_prompt(prompt)
			-- Check for actual matches before running the scoring alogrithm.
			if not fzy.has_match(prompt, line) then
				return -1
			end

			local fzy_score = fzy.score(prompt, line)

			if fzy_score == fzy.get_score_min() then
				return 1
			end

			return 1 / (fzy_score + OFFSET)
		end,

		highlighter = function(_, prompt, display)
			prompt = string.gsub(prompt, "^/", "")
			return fzy.positions(prompt, display)
		end,
	})
end

return M
