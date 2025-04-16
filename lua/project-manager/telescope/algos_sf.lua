local MATCH_MAX_LENGTH = 1024

local sf = {}

local function case_sensitive_has_match(needle, haystack)
  local pos_start, pos_end = string.find(haystack, needle)
  if not pos_start or pos_end < pos_start then
    return false
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

function sf.has_match(opt, needle, haystack)
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


local function case_sensitive_positions(needle, haystack)
  local positions = {}
  local init = 1

  local max = math.min(string.len(haystack), MATCH_MAX_LENGTH)

  while init <= max do
    local pos_start, pos_end = string.find(haystack, needle, init)
    if not pos_start or pos_end < pos_start then
      break
    end

    table.insert(positions, {
      start = pos_start,
      finish = pos_end,
    })

    init = pos_end + 1
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

function sf.positions(opt, needle, haystack)
  local n = string.len(needle)
  local m = string.len(haystack)

  if n == 0 or m == 0 or m > MATCH_MAX_LENGTH or n > MATCH_MAX_LENGTH then
    return {}
  elseif n == m then
    local consecutive = {}
    for i = 1, n do
      consecutive[i] = i
    end
    return consecutive
  end

  if opt == "s" then
    return case_sensitive_positions(needle, haystack)
  end

  if opt == "i" then
    return case_insensitive_positions(needle, haystack)
  end

  return smart_case_positions(needle, haystack)
end

function sf.score()
  return 1
end

return sf
