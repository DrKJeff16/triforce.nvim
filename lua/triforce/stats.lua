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
---@field chars_by_language table<string, number> Characters typed per language
---@field daily_activity table<string, boolean> Dates with activity (YYYY-MM-DD format)
---@field current_streak number Current consecutive day streak
---@field longest_streak number Longest ever streak

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
  chars_by_language = {},
  daily_activity = {},
  current_streak = 0,
  longest_streak = 0,
}

---Get the stats file path
---@return string
local function get_stats_path()
  local data_path = vim.fn.stdpath('data')
  return data_path .. '/triforce_stats.json'
end

---Prepare stats for JSON encoding (handle empty tables)
---@param stats Stats
---@return Stats
local function prepare_for_save(stats)
  local copy = vim.deepcopy(stats)

  -- Use vim.empty_dict() to ensure empty tables encode as {} not []
  if vim.tbl_isempty(copy.achievements) then
    copy.achievements = vim.empty_dict()
  end

  if vim.tbl_isempty(copy.chars_by_language) then
    copy.chars_by_language = vim.empty_dict()
  end

  if vim.tbl_isempty(copy.daily_activity) then
    copy.daily_activity = vim.empty_dict()
  end

  return copy
end

---Load stats from disk
---@return Stats
function M.load()
  local path = get_stats_path()

  -- Check if file exists
  if vim.fn.filereadable(path) == 0 then
    return vim.deepcopy(M.default_stats)
  end

  -- Read file using vim.fn for cross-platform compatibility
  local lines = vim.fn.readfile(path)
  if not lines or #lines == 0 then
    return vim.deepcopy(M.default_stats)
  end

  local content = table.concat(lines, '\n')

  -- Parse JSON
  local ok, stats = pcall(vim.json.decode, content)
  if not ok or type(stats) ~= 'table' then
    -- Backup corrupted file
    local backup = path .. '.backup.' .. os.time()
    vim.fn.writefile(lines, backup)
    vim.notify('Corrupted stats backed up to: ' .. backup, vim.log.levels.WARN)
    return vim.deepcopy(M.default_stats)
  end

  -- Fix chars_by_language if it was saved as array
  if stats.chars_by_language then
    if vim.isarray(stats.chars_by_language) then
      stats.chars_by_language = {}
    end
  end

  -- Merge with defaults to ensure all fields exist
  return vim.tbl_deep_extend('force', vim.deepcopy(M.default_stats), stats)
end

---Save stats to disk
---@param stats Stats
---@return boolean success
function M.save(stats)
  if not stats then
    return false
  end

  local path = get_stats_path()

  -- Prepare data
  local data_to_save = prepare_for_save(stats)

  -- Encode to JSON
  local ok, json = pcall(vim.json.encode, data_to_save)
  if not ok then
    vim.notify('Failed to encode stats to JSON', vim.log.levels.ERROR)
    return false
  end

  -- Create backup of existing file
  if vim.fn.filereadable(path) == 1 then
    local backup_path = path .. '.bak'
    vim.fn.writefile(vim.fn.readfile(path), backup_path)
  end

  -- Write to file using vim.fn.writefile (more reliable on Windows)
  local write_ok = vim.fn.writefile({json}, path)

  if write_ok == -1 then
    vim.notify('Failed to write stats file to: ' .. path, vim.log.levels.ERROR)
    return false
  end

  return true
end

---Calculate level from XP
---Level formula: level = floor(sqrt(xp / 100)) + 1
---Level 2 = 100 XP, Level 3 = 400 XP, Level 4 = 900 XP, etc.
---@param xp number
---@return number level
function M.calculate_level(xp)
  return math.floor(math.sqrt(xp / 100)) + 1
end

---Calculate XP needed for next level
---XP needed = (level ^ 2) * 100
---@param current_level number
---@return number xp_needed
function M.xp_for_next_level(current_level)
  return (current_level ^ 2) * 100
end

---Add XP and update level
---@param stats Stats
---@param amount number
---@return boolean leveled_up
function M.add_xp(stats, amount)
  local old_level = stats.level
  stats.xp = stats.xp + amount
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

---Get current date in YYYY-MM-DD format
---@param timestamp? number Optional timestamp, defaults to current time
---@return string
local function get_date_string(timestamp)
  return os.date('%Y-%m-%d', timestamp or os.time())
end

---Get timestamp for start of day
---@param date_str string Date in YYYY-MM-DD format
---@return number
local function get_day_start(date_str)
  local year, month, day = date_str:match('(%d+)-(%d+)-(%d+)')
  return os.time({ year = year, month = month, day = day, hour = 0, min = 0, sec = 0 })
end

---Calculate streak from daily activity
---@param stats Stats
---@return number current_streak, number longest_streak
function M.calculate_streaks(stats)
  if not stats.daily_activity then
    stats.daily_activity = {}
    return 0, 0
  end

  -- Get sorted dates
  local dates = {}
  for date in pairs(stats.daily_activity) do
    table.insert(dates, date)
  end
  table.sort(dates)

  if #dates == 0 then
    return 0, 0
  end

  local current_streak = 0
  local longest_streak = 0
  local streak = 0
  local today = get_date_string()
  local yesterday = get_date_string(os.time() - 86400)

  -- Calculate streaks by iterating through sorted dates
  for i = #dates, 1, -1 do
    local date = dates[i]

    if i == #dates then
      -- Start with most recent date
      if date == today or date == yesterday then
        streak = 1
        current_streak = 1
      end
    else
      local current_time = get_day_start(date)
      local next_time = get_day_start(dates[i + 1])
      local diff_days = math.floor((next_time - current_time) / 86400)

      if diff_days == 1 then
        -- Consecutive day
        streak = streak + 1
        if i == #dates - 1 or (date == today or date == yesterday) then
          current_streak = streak
        end
      else
        -- Streak broken
        if streak > longest_streak then
          longest_streak = streak
        end
        streak = 1
      end
    end
  end

  -- Check final streak
  if streak > longest_streak then
    longest_streak = streak
  end

  -- If most recent activity wasn't today or yesterday, current streak is 0
  if dates[#dates] ~= today and dates[#dates] ~= yesterday then
    current_streak = 0
  end

  return current_streak, longest_streak
end

---Record activity for today
---@param stats Stats
function M.record_daily_activity(stats)
  if not stats.daily_activity then
    stats.daily_activity = {}
  end

  local today = get_date_string()
  stats.daily_activity[today] = true

  -- Update streaks
  local current, longest = M.calculate_streaks(stats)
  stats.current_streak = current
  stats.longest_streak = longest
end

---Check and unlock achievements
---@param stats Stats
---@return table<string> newly_unlocked
function M.check_achievements(stats)
  local newly_unlocked = {}

  -- Count unique languages
  local unique_languages = 0
  for _ in pairs(stats.chars_by_language or {}) do
    unique_languages = unique_languages + 1
  end

  local achievements = {
    { id = 'first_100', check = stats.chars_typed >= 100, name = 'First Steps' },
    { id = 'first_1000', check = stats.chars_typed >= 1000, name = 'Getting Started' },
    { id = 'first_10000', check = stats.chars_typed >= 10000, name = 'Dedicated Coder' },
    { id = 'level_5', check = stats.level >= 5, name = 'Rising Star' },
    { id = 'level_10', check = stats.level >= 10, name = 'Expert Coder' },
    { id = 'sessions_10', check = stats.sessions >= 10, name = 'Regular Visitor' },
    { id = 'sessions_50', check = stats.sessions >= 50, name = 'Creature of Habit' },
    { id = 'polyglot_3', check = unique_languages >= 3, name = 'Polyglot Beginner' },
    { id = 'polyglot_5', check = unique_languages >= 5, name = 'Polyglot' },
    { id = 'polyglot_10', check = unique_languages >= 10, name = 'Master Polyglot' },
    { id = 'polyglot_15', check = unique_languages >= 15, name = 'Language Virtuoso' },
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
