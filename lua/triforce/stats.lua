---@class Triforce.Stats
local M = {}

---Configurable level progression
---@type LevelProgression
M.level_config = {
  -- XP required per level for each tier
  tier_1 = { min_level = 1, max_level = 10, xp_per_level = 300 }, -- Levels 1-10: 300 XP each
  tier_2 = { min_level = 11, max_level = 20, xp_per_level = 500 }, -- Levels 11-20: 500 XP each
  tier_3 = { min_level = 21, max_level = math.huge, xp_per_level = 1000 }, -- Levels 21+: 1000 XP each
}

---Stats tracking and persistence module
---@class Stats
---@field xp integer Total experience points
---@field level integer Current level
---@field chars_typed integer Total characters typed
---@field lines_typed integer Total lines typed
---@field sessions integer Total sessions
---@field time_coding integer Total time in seconds
---@field last_session_start integer Timestamp of session start
---@field achievements table<string, boolean> Unlocked achievements
---@field chars_by_language table<string, integer> Characters typed per language
---@field daily_activity table<string, integer> Lines typed per day (YYYY-MM-DD format)
---@field current_streak integer Current consecutive day streak
---@field longest_streak integer Longest ever streak
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
local function get_stats_path()
  return vim.fn.stdpath('data') .. '/triforce_stats.json'
end

---Prepare stats for JSON encoding (handle empty tables)
---@param stats Stats
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

  -- Migrate daily_activity from boolean to number (old format compatibility)
  if stats.daily_activity then
    for date, value in pairs(stats.daily_activity) do
      if type(value) == 'boolean' then
        -- Old format: true → 0 (can't recover historical line counts)
        stats.daily_activity[date] = value and 0 or 0
      end
    end
  end

  -- Merge with defaults to ensure all fields exist
  local merged = vim.tbl_deep_extend('force', vim.deepcopy(M.default_stats), stats)

  -- Recalculate level from XP to fix any inconsistencies
  -- (e.g., if user changed level progression config after playing)
  if merged.xp and merged.xp > 0 then
    local calculated_level = M.calculate_level(merged.xp)
    if calculated_level ~= merged.level then
      vim.notify(
        ('Level mismatch detected! Recalculating from XP.\nOld level: %d → New level: %d (based on %d XP)'):format(
          merged.level,
          calculated_level,
          merged.xp
        ),
        vim.log.levels.WARN,
        { title = ' Triforce' }
      )
      merged.level = calculated_level
    end
  end

  return merged
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
  local write_ok = vim.fn.writefile({ json }, path)

  if write_ok == -1 then
    vim.notify('Failed to write stats file to: ' .. path, vim.log.levels.ERROR)
    return false
  end

  return true
end

---Calculate total XP needed to reach a specific level
---@param level integer
---@return integer total_xp
local function get_total_xp_for_level(level)
  if level <= 1 then
    return 0
  end

  local total_xp = 0
  local config = M.level_config

  -- Calculate XP for tier 1 (levels 1-10)
  if level > config.tier_1.min_level then
    local tier_1_levels = math.min(level - 1, config.tier_1.max_level)
    total_xp = total_xp + (tier_1_levels * config.tier_1.xp_per_level)
  end

  -- Calculate XP for tier 2 (levels 11-20)
  if level > config.tier_2.min_level then
    local tier_2_start = config.tier_2.min_level
    local tier_2_end = math.min(level - 1, config.tier_2.max_level)
    local tier_2_levels = tier_2_end - tier_2_start + 1
    if tier_2_levels > 0 then
      total_xp = total_xp + (tier_2_levels * config.tier_2.xp_per_level)
    end
  end

  -- Calculate XP for tier 3 (levels 21+)
  if level > config.tier_3.min_level then
    local tier_3_start = config.tier_3.min_level
    local tier_3_levels = level - tier_3_start
    total_xp = total_xp + (tier_3_levels * config.tier_3.xp_per_level)
  end

  return total_xp
end

---Calculate level from XP
---Simple tier-based progression:
---  Levels 1-10: 300 XP each
---  Levels 11-20: 500 XP each
---  Levels 21+: 1000 XP each
---@param xp integer
---@return integer level
function M.calculate_level(xp)
  if xp <= 0 then
    return 1
  end

  local level = 1
  local accumulated_xp = 0
  local config = M.level_config

  -- Tier 1: Levels 1-10 (300 XP each)
  local tier_1_total = config.tier_1.max_level * config.tier_1.xp_per_level
  if xp <= tier_1_total then
    return 1 + math.floor(xp / config.tier_1.xp_per_level)
  end
  accumulated_xp = tier_1_total
  level = config.tier_1.max_level

  -- Tier 2: Levels 11-20 (500 XP each)
  local tier_2_range = config.tier_2.max_level - config.tier_2.min_level + 1
  local tier_2_total = tier_2_range * config.tier_2.xp_per_level
  if xp <= accumulated_xp + tier_2_total then
    local xp_in_tier = xp - accumulated_xp
    return (level + 1) + math.floor(xp_in_tier / config.tier_2.xp_per_level)
  end
  accumulated_xp = accumulated_xp + tier_2_total
  level = config.tier_2.max_level

  -- Tier 3: Levels 21+ (1000 XP each)
  local xp_in_tier = xp - accumulated_xp
  return (level + 1) + math.floor(xp_in_tier / config.tier_3.xp_per_level)
end

---Calculate XP needed for next level
---@param current_level integer
---@return integer xp_needed
function M.xp_for_next_level(current_level)
  return get_total_xp_for_level(current_level + 1)
end

---Add XP and update level
---@param stats Stats
---@param amount integer
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
---@param timestamp integer|nil Optional timestamp, defaults to current time
local function get_date_string(timestamp)
  return os.date('%Y-%m-%d', timestamp or os.time())
end

---Get timestamp for start of day
---@param date_str string Date in YYYY-MM-DD format
local function get_day_start(date_str)
  local year, month, day = date_str:match('(%d+)-(%d+)-(%d+)')
  return os.time({ year = year, month = month, day = day, hour = 0, min = 0, sec = 0 })
end

---Calculate streak from daily activity
---@param stats Stats
---@return integer current_streak
---@return integer longest_streak
function M.calculate_streaks(stats)
  if not stats.daily_activity then
    stats.daily_activity = {}
    return 0, 0
  end

  -- Get sorted dates (only those with activity > 0)
  local dates = {}
  for date, lines in pairs(stats.daily_activity) do
    if lines > 0 then
      table.insert(dates, date)
    end
  end
  table.sort(dates)

  if vim.tbl_isempty(dates) then
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
  if not vim.list_contains({ today, yesterday }, dates[#dates]) then
    current_streak = 0
  end

  return current_streak, longest_streak
end

---Record activity for today
---@param stats Stats
---@param lines_today integer Number of lines typed today
function M.record_daily_activity(stats, lines_today)
  if not stats.daily_activity then
    stats.daily_activity = {}
  end

  local today = get_date_string()
  stats.daily_activity[today] = (stats.daily_activity[today] or 0) + lines_today

  -- Update streaks
  local current, longest = M.calculate_streaks(stats)
  stats.current_streak = current
  stats.longest_streak = longest
end

---Get all achievements with their unlock status
---@param stats Stats
---@return { id: string, name: string, desc: string, icon: string, check: boolean }[] achievements List of achievement objects { id, name, desc, icon, check }
function M.get_all_achievements(stats)
  -- Count unique languages
  local unique_languages = 0
  for _ in pairs(stats.chars_by_language or {}) do
    unique_languages = unique_languages + 1
  end

  return {
    {
      id = 'first_100',
      name = 'First Steps',
      desc = 'Type 100 characters',
      icon = '🌱',
      check = stats.chars_typed >= 100,
    },
    {
      id = 'first_1000',
      name = 'Getting Started',
      desc = 'Type 1,000 characters',
      icon = '⚔️',
      check = stats.chars_typed >= 1000,
    },
    {
      id = 'first_10000',
      name = 'Dedicated Coder',
      desc = 'Type 10,000 characters',
      icon = '🛡️',
      check = stats.chars_typed >= 10000,
    },
    {
      id = 'first_100000',
      name = 'Master Scribe',
      desc = 'Type 100,000 characters',
      icon = '📜',
      check = stats.chars_typed >= 100000,
    },
    { id = 'level_5', name = 'Rising Star', desc = 'Reach level 5', icon = '⭐', check = stats.level >= 5 },
    { id = 'level_10', name = 'Expert Coder', desc = 'Reach level 10', icon = '💎', check = stats.level >= 10 },
    { id = 'level_25', name = 'Champion', desc = 'Reach level 25', icon = '👑', check = stats.level >= 25 },
    { id = 'level_50', name = 'Legend', desc = 'Reach level 50', icon = '🔱', check = stats.level >= 50 },
    {
      id = 'sessions_10',
      name = 'Regular Visitor',
      desc = 'Complete 10 sessions',
      icon = '🔄',
      check = stats.sessions >= 10,
    },
    {
      id = 'sessions_50',
      name = 'Creature of Habit',
      desc = 'Complete 50 sessions',
      icon = '📅',
      check = stats.sessions >= 50,
    },
    {
      id = 'sessions_100',
      name = 'Dedicated Hero',
      desc = 'Complete 100 sessions',
      icon = '🏆',
      check = stats.sessions >= 100,
    },
    {
      id = 'time_1h',
      name = 'First Hour',
      desc = 'Code for 1 hour total',
      icon = '⏰',
      check = stats.time_coding >= 3600,
    },
    {
      id = 'time_10h',
      name = 'Committed',
      desc = 'Code for 10 hours total',
      icon = '⌛',
      check = stats.time_coding >= 36000,
    },
    {
      id = 'time_100h',
      name = 'Veteran',
      desc = 'Code for 100 hours total',
      icon = '🕐',
      check = stats.time_coding >= 360000,
    },
    {
      id = 'polyglot_3',
      name = 'Polyglot Beginner',
      desc = 'Code in 3 different languages',
      icon = '🌍',
      check = unique_languages >= 3,
    },
    {
      id = 'polyglot_5',
      name = 'Polyglot',
      desc = 'Code in 5 different languages',
      icon = '🌎',
      check = unique_languages >= 5,
    },
    {
      id = 'polyglot_10',
      name = 'Master Polyglot',
      desc = 'Code in 10 different languages',
      icon = '🌏',
      check = unique_languages >= 10,
    },
    {
      id = 'polyglot_15',
      name = 'Language Virtuoso',
      desc = 'Code in 15 different languages',
      icon = '🗺️',
      check = unique_languages >= 15,
    },
  }
end

---Check and unlock achievements
---@param stats Stats
---@return table newly_unlocked List of achievement objects { name, desc, icon, id, check }
function M.check_achievements(stats)
  local newly_unlocked = {}
  local achievements = M.get_all_achievements(stats)

  for _, achievement in ipairs(achievements) do
    if achievement.check and not stats.achievements[achievement.id] then
      stats.achievements[achievement.id] = true
      table.insert(newly_unlocked, {
        id = achievement.id,
        check = achievement.check,
        name = achievement.name,
        desc = achievement.desc,
        icon = achievement.icon,
      })
    end
  end

  return newly_unlocked
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
