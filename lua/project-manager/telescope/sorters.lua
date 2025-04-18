local t_sorters = require("telescope.sorters")

local pm_utils = require("project-manager.telescope.utils")

local M = {}

function M.fzy_dir_sorter(opts)
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
      prompt = string.gsub(prompt, "^/", "", 1)
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

local function getS(s)
  return string.match(s, "[#*]")
end

local function getC(s)
  return string.match(s, "[si]")
end

local function getFlagOpt(s)
  local flag_patterns = {
    "^#>",
    "^*>",
    "^s>",
    "^i>",
    "^#s>",
    "^#i>",
    "^*s>",
    "^*i>",
  }

  local opt = {}

  for _, flag_pattern in ipairs(flag_patterns) do
    local flag = string.match(s, flag_pattern)

    if flag then
      opt = {
        f = flag,
        s = getS(flag),
        c = getC(flag),
      }
      break
    end
  end

  return opt
end

function M.sf_sorter(opts)
  opts = opts or {}
  local sf = require("project-manager.telescope.algos_sf")
  local fzy = opts.fzy_mod or require("project-manager.telescope.algos_fzy")
  local OFFSET = -fzy.get_score_floor()

  return t_sorters.Sorter:new({
    discard = true,

    scoring_function = function(sorter, prompt, line)
      prompt = pm_utils.format_prompt(prompt)

      if string.len(prompt) < 4 then
        sorter._discard_state.filtered = {}
      end

      if not sorter.state.flag then
        sorter.state.flag = {}
      end

      local flagOpt = sorter.state.flag
      local preFlag = flagOpt.f

      if not preFlag or not string.find(prompt, "^" .. preFlag, nil, false) then
        flagOpt = getFlagOpt(prompt)
        sorter.state.flag = flagOpt
      end

      prompt = string.gsub(prompt, "^" .. (flagOpt.f or ""), "")

      if flagOpt.s == "#" then
        if not sf.has_match(flagOpt.c, prompt, line) then
          return -1
        end

        return sf.score()
      end

      if flagOpt.s == "*" then
        if not fzy.has_match(flagOpt.c, prompt, line) then
          return -1
        end

        local fzy_score = fzy.score(flagOpt.c, prompt, line)

        if fzy_score == fzy.get_score_min() then
          return 1
        end

        return 1 / (fzy_score + OFFSET)
      end

      if not fzy.has_match(flagOpt.c, prompt, line) then
        return -1
      end

      local fzy_score = fzy.score(flagOpt.c, prompt, line)

      if fzy_score == fzy.get_score_min() then
        return 1
      end

      return 1 / (fzy_score + OFFSET)
    end,

    highlighter = function (sorter, prompt, display)
      prompt = pm_utils.format_prompt(prompt)

      local line = display
      local _, entry_end = string.find(display, "^ *.* ", nil, false)
      if entry_end then
        line = string.sub(display, entry_end + 1, string.len(display))
      end

      local positions = {}

      if not sorter.state.flag then
        sorter.state.flag = {}
      end

      local flagOpt = sorter.state.flag
      local preFlag = flagOpt.f

      if not preFlag or not string.find(prompt, "^" .. preFlag, nil, false) then
        flagOpt = getFlagOpt(prompt)
        sorter.state.flag = flagOpt
      end

      prompt = string.gsub(prompt, "^" .. (flagOpt.f or ""), "", 1)

      if flagOpt.s == "#" then
        positions = sf.positions(flagOpt.c, prompt, line)
      end

      if flagOpt.s == "*" then
        positions = fzy.positions(flagOpt.c, prompt, line)
      end

      if not flagOpt.s then
        positions = fzy.positions(flagOpt.c, prompt, line)
      end

      local hls = {}
      local highlight = opts.__highlight.finder_filter_matching.name or "TelescopeMatching"

      for _, value in ipairs(positions) do
        table.insert(hls, {
          start = value.start + (entry_end or  0),
          finish = value.finish + (entry_end or 0),
          highlight = highlight,
        })
      end

      return hls
    end
  })
end

return M
