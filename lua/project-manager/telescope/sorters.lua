local t_sorters = require("telescope.sorters")

local pm_utils = require("project-manager.telescope.utils")

local M = {}

M.fzy_dir_sorter = function(opts)
	opts = opts or {}
	local fzy = opts.fzy_mod or require("telescope.algos.fzy")
	local OFFSET = -fzy.get_score_floor()

	return t_sorters.Sorter:new({
		discard = true,

		scoring_function = function(_, prompt, line)
			prompt = pm_utils.format_prompt(prompt)
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
			local positions = fzy.positions(prompt, display)

			local hls = {}
			local highlight = opts.__highlight.finder_filter_matching.name or "TelescopeMatching"

			for _, value in ipairs(positions) do
				table.insert(hls, { start = value, highlight = highlight })
			end

			return hls
		end,
	})
end

return M
