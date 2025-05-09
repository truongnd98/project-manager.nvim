local has_path, Path = pcall(require, "plenary.path")
if not has_path then
  Path = {
    path = {
      separator = "/",
    },
  }
end

local SCORE_GAP_LEADING = -0.005
local SCORE_GAP_TRAILING = -0.005
local SCORE_GAP_INNER = -0.01
local SCORE_MATCH_CONSECUTIVE = 1.0
local SCORE_MATCH_SLASH = 0.9
local SCORE_MATCH_WORD = 0.8
local SCORE_MATCH_CAPITAL = 0.7
local SCORE_MATCH_DOT = 0.6
local SCORE_MAX = math.huge
local SCORE_MIN = -math.huge
local MATCH_MAX_LENGTH = 1024

local fzy = {}

local function case_sensitive_has_match(needle, haystack)
  local j = 1
  for i = 1, string.len(needle) do
    j = string.find(haystack, needle:sub(i, i), j, true)
    if not j then
      return false
    else
      j = j + 1
    end
  end

  return true
end

local function case_insensitive_has_match(needle, haystack)
  needle = string.lower(needle)
  haystack = string.lower(haystack)
  return case_sensitive_has_match(needle, haystack)
end

local function smart_case_has_match(needle, haystack)
  if needle:match '%u' then
    return case_sensitive_has_match(needle, haystack)
  end

  return case_insensitive_has_match(needle, haystack)
end


function fzy.has_match(opt, needle, haystack)
  if string.len(needle) == 0 then
    return true
  end

  if string.len(haystack) < string.len(needle) then
    return false
  end

  if opt == "s" then
    return case_sensitive_has_match(needle, haystack)
  end

  if opt == "i" then
    return case_insensitive_has_match(needle, haystack)
  end

  return smart_case_has_match(needle, haystack)
end

local function is_lower(c)
  return c:match "%l"
end

local function is_upper(c)
  return c:match "%u"
end

local function precompute_bonus(haystack)
  local match_bonus = {}

  local last_char = Path.path.sep
  for i = 1, string.len(haystack) do
    local this_char = haystack:sub(i, i)
    if last_char == Path.path.sep then
      match_bonus[i] = SCORE_MATCH_SLASH
    elseif last_char == "-" or last_char == "_" or last_char == " " then
      match_bonus[i] = SCORE_MATCH_WORD
    elseif last_char == "." then
      match_bonus[i] = SCORE_MATCH_DOT
    elseif is_lower(last_char) and is_upper(this_char) then
      match_bonus[i] = SCORE_MATCH_CAPITAL
    else
      match_bonus[i] = 0
    end

    last_char = this_char
  end

  return match_bonus
end

local function compute(needle, haystack, D, M)
  local match_bonus = precompute_bonus(haystack)
  local n = string.len(needle)
  local m = string.len(haystack)

  -- Because lua only grants access to chars through substring extraction,
  -- get all the characters from the haystack once now, to reuse below.
  local haystack_chars = {}
  for i = 1, m do
    haystack_chars[i] = haystack:sub(i, i)
  end

  for i = 1, n do
    D[i] = {}
    M[i] = {}

    local prev_score = SCORE_MIN
    local gap_score = i == n and SCORE_GAP_TRAILING or SCORE_GAP_INNER
    local needle_char = needle:sub(i, i)

    for j = 1, m do
      if needle_char == haystack_chars[j] then
        local score = SCORE_MIN
        if i == 1 then
          score = ((j - 1) * SCORE_GAP_LEADING) + match_bonus[j]
        elseif j > 1 then
          local a = M[i - 1][j - 1] + match_bonus[j]
          local b = D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE
          score = math.max(a, b)
        end
        D[i][j] = score
        prev_score = math.max(score, prev_score + gap_score)
        M[i][j] = prev_score
      else
        D[i][j] = SCORE_MIN
        prev_score = prev_score + gap_score
        M[i][j] = prev_score
      end
    end
  end
end

local function case_sensitive_score(needle, haystack)
  local n = string.len(needle)
  local m = string.len(haystack)

  if n == 0 or m == 0 or m > MATCH_MAX_LENGTH or n > MATCH_MAX_LENGTH then
    return SCORE_MIN
  elseif n == m then
    return SCORE_MAX
  else
    local D = {}
    local M = {}
    compute(needle, haystack, D, M)
    return M[n][m]
  end
end

local function case_insensitive_score(needle, haystack)
  needle = string.lower(needle)
  haystack = string.lower(haystack)
  return case_sensitive_score(needle, haystack)
end

local function smart_case_score(needle, haystack)
  if needle:match '%u' then
    return case_sensitive_score(needle, haystack)
  end

  return case_insensitive_score(needle, haystack)
end

function fzy.score(opt, needle, haystack)
  if opt == "s" then
    return case_sensitive_score(needle, haystack)
  end

  if opt == "i" then
    return case_insensitive_score(needle, haystack)
  end

  return smart_case_score(needle, haystack)
end

local function case_sensitive_positions(needle, haystack)
  local n = string.len(needle)
  local m = string.len(haystack)

  if n == 0 or m == 0 or m > MATCH_MAX_LENGTH or n > MATCH_MAX_LENGTH then
    return {}
  elseif n == m then
    return { start = 1, finish = n }
  end

  local D = {}
  local M = {}
  compute(needle, haystack, D, M)

  local positions = {}
  local match_required = false
  local j = m
  local pos = nil
  local matched = nil
  for i = n, 1, -1 do
    while j >= 1 do
      if D[i][j] ~= SCORE_MIN and (match_required or D[i][j] == M[i][j]) then
        match_required = (i ~= 1) and (j ~= 1) and (M[i][j] == D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE)
        matched = j
        j = j - 1
        break
      else
        j = j - 1
      end
    end

    if matched then
      if not pos then
        pos = { start = matched, finish = matched }
      else
        if pos.start - 1 == matched then
          pos.start = matched
        else
          table.insert(positions, { start = pos.start, finish = pos.finish })
          pos = { start = matched, finish = matched }
        end
      end

      matched = nil
    end

    if i == 1 and pos then
      table.insert(positions, { start = pos.start, finish = pos.finish })
    end
  end

  return positions
end

local function case_insensitive_positions(needle, haystack)
  needle = string.lower(needle)
  haystack = string.lower(haystack)
  return case_sensitive_positions(needle, haystack)
end

local function smart_case_positions(needle, haystack)
  if needle:match '%u' then
    return case_sensitive_positions(needle, haystack)
  end

  return case_insensitive_positions(needle, haystack)
end

function fzy.positions(opt, needle, haystack)
  if opt == "s" then
    return case_sensitive_positions(needle, haystack)
  end

  if opt == "i" then
    return case_insensitive_positions(needle, haystack)
  end

  return smart_case_positions(needle, haystack)
end

-- If strings a or b are empty or too long, `fzy.score(a, b) == fzy.get_score_min()`.
function fzy.get_score_min()
  return SCORE_MIN
end

-- For exact matches, `fzy.score(s, s) == fzy.get_score_max()`.
function fzy.get_score_max()
  return SCORE_MAX
end

-- For all strings a and b that
--  - are not covered by either `fzy.get_score_min()` or fzy.get_score_max()`, and
--  - are matched, such that `fzy.has_match(a, b) == true`,
-- then `fzy.score(a, b) > fzy.get_score_floor()` will be true.
function fzy.get_score_floor()
  return (MATCH_MAX_LENGTH + 1) * SCORE_GAP_INNER
end

return fzy
