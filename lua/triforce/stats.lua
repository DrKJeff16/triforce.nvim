---Stats tracking and persistence module
---@class Stats
---@field xp number Total experience points
---@field level number Current level
---@field chars_typed number Total characters typed
---@field lines_typed number Total lines typed
---@field sessions number Total sessions
---@field time_coding number Total time in seconds
---@field last_session_start number Timestamp of session start
---@field achievements table<string, boolean> Unlocked achievements

local M = {}

---@type Stats
M.default_stats = {
  xp = 0,
  level = 1,
  chars_typed = 0,
  lines_typed = 0,
  sessions = 0,
  time_coding = 0,
  last_session_start = 0,
  achievements = {},
}

---Get the stats file path
---@return string
local function get_stats_path()
  local data_path = vim.fn.stdpath('data')
  return data_path .. '/triforce_stats.json'
end

---Load stats from disk
---@return Stats
function M.load()
  local path = get_stats_path()
  local file = io.open(path, 'r')

  if not file then
    return vim.deepcopy(M.default_stats)
  end

  local content = file:read('*a')
  file:close()

  local ok, stats = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Failed to parse stats file, using defaults', vim.log.levels.WARN)
    return vim.deepcopy(M.default_stats)
  end

  -- Merge with defaults to handle new fields
  return vim.tbl_deep_extend('force', M.default_stats, stats)
end

---Save stats to disk
---@param stats Stats
function M.save(stats)
  local path = get_stats_path()
  local content = vim.json.encode(stats)

  local file = io.open(path, 'w')
  if not file then
    vim.notify('Failed to save stats', vim.log.levels.ERROR)
    return
  end

  file:write(content)
  file:close()
end

---Calculate level from XP
---@param xp number
---@return number level
function M.calculate_level(xp)
  -- Level formula: level = floor(sqrt(xp / 100)) + 1
  -- This means: Level 2 = 100 XP, Level 3 = 400 XP, Level 4 = 900 XP, etc.
  return math.floor(math.sqrt(xp / 100)) + 1
end

---Calculate XP needed for next level
---@param current_level number
---@return number xp_needed
function M.xp_for_next_level(current_level)
  -- XP needed = (level ^ 2) * 100
  return (current_level ^ 2) * 100
end

---Add XP and update level
---@param stats Stats
---@param amount number
---@return boolean leveled_up
function M.add_xp(stats, amount)
  local old_level = stats.level
  stats.xp = stats.xp + amount

  -- Recalculate level
  stats.level = M.calculate_level(stats.xp)

  return stats.level > old_level
end

---Start a new session
---@param stats Stats
function M.start_session(stats)
  stats.sessions = stats.sessions + 1
  stats.last_session_start = os.time()
end

---End the current session
---@param stats Stats
function M.end_session(stats)
  if stats.last_session_start > 0 then
    local duration = os.time() - stats.last_session_start
    stats.time_coding = stats.time_coding + duration
    stats.last_session_start = 0
  end
end

---Check and unlock achievements
---@param stats Stats
---@return table<string> newly_unlocked
function M.check_achievements(stats)
  local newly_unlocked = {}

  local achievements = {
    { id = 'first_100', check = stats.chars_typed >= 100, name = 'First Steps' },
    { id = 'first_1000', check = stats.chars_typed >= 1000, name = 'Getting Started' },
    { id = 'first_10000', check = stats.chars_typed >= 10000, name = 'Dedicated Coder' },
    { id = 'level_5', check = stats.level >= 5, name = 'Rising Star' },
    { id = 'level_10', check = stats.level >= 10, name = 'Expert Coder' },
    { id = 'sessions_10', check = stats.sessions >= 10, name = 'Regular Visitor' },
    { id = 'sessions_50', check = stats.sessions >= 50, name = 'Creature of Habit' },
  }

  for _, achievement in ipairs(achievements) do
    if achievement.check and not stats.achievements[achievement.id] then
      stats.achievements[achievement.id] = true
      table.insert(newly_unlocked, achievement.name)
    end
  end

  return newly_unlocked
end

return M
