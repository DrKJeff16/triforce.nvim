local uv = vim.uv or vim.loop
local util = require('triforce.util')

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

---@type string|nil
M.db_path = nil

---Stats tracking and persistence module
---@class Stats
M.default_stats = {
  xp = 0, ---@type number Total experience points
  level = 1, ---@type integer Current level
  chars_typed = 0, ---@type integer Total characters typed
  lines_typed = 0, ---@type integer Total lines typed
  sessions = 0, ---@type integer Total sessions
  time_coding = 0, ---@type integer Total time in seconds
  last_session_start = 0, ---@type integer Timestamp of session start
  achievements = {}, ---@type table<string, boolean> Unlocked achievements
  chars_by_language = {}, ---@type table<string, integer> Characters typed per language
  daily_activity = {}, ---@type table<string, integer> Lines typed per day (`YYYY-MM-DD` format)
  current_streak = 0, ---@type integer Current consecutive day streak
  longest_streak = 0, ---@type integer Longest ever streak
  db_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'triforce_stats.json'), ---@type string
}

---Get the stats file path
---@return string db_path
local function get_stats_path()
  return M.db_path or M.default_stats.db_path
end

---Prepare stats for JSON encoding (handle empty tables)
---@param stats Stats
---@return Stats copy
local function prepare_for_save(stats)
  util.validate({ stats = { stats, { 'table' } } })

  local copy = vim.deepcopy(stats)

  -- Use `vim.empty_dict()` to ensure empty tables encode as `{}` not `[]`
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

  ---Read file using vim.fn for cross-platform compatibility
  ---@type string[]
  local lines = vim.fn.readfile(path)
  if not lines or #lines == 0 then
    return vim.deepcopy(M.default_stats)
  end

  local content = table.concat(lines, '\n')

  ---Parse JSON
  ---@type boolean, Stats?
  local ok, stats = pcall(vim.json.decode, content)
  if not ok or type(stats) ~= 'table' then
    -- Backup corrupted file
    local backup = ('%s.backup.%s'):format(path, os.time())
    vim.fn.writefile(lines, backup)
    vim.notify('Corrupted stats backed up to: ' .. backup, vim.log.levels.WARN)
    return vim.deepcopy(M.default_stats)
  end

  -- Fix chars_by_language if it was saved as array
  if stats.chars_by_language and vim.isarray(stats.chars_by_language) then
    stats.chars_by_language = {}
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
  if not merged.xp or merged.xp <= 0 then
    return merged
  end

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

  return merged
end

---Save stats to disk
---@param stats Stats|nil
---@return boolean success
function M.save(stats)
  util.validate({ stats = { stats, { 'table', 'nil' }, true } })
  if not stats then
    return false
  end

  -- Prepare data
  local data_to_save = prepare_for_save(stats)
  local path = get_stats_path()

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
  util.validate({ level = { level, { 'number' } } })
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
---@param xp number
---@return integer level
function M.calculate_level(xp)
  util.validate({ xp = { xp, { 'number' } } })
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
---@param amount number
---@return boolean leveled_up
function M.add_xp(stats, amount)
  util.validate({
    stats = { stats, { 'table' } },
    amount = { amount, { 'number' } },
  })

  local old_level = stats.level
  stats.xp = stats.xp + amount
  stats.level = M.calculate_level(stats.xp)

  return stats.level > old_level
end

---Start a new session
---@param stats Stats
function M.start_session(stats)
  util.validate({ stats = { stats, { 'table' } } })

  stats.sessions = stats.sessions + 1
  stats.last_session_start = os.time()
end

---End the current session
---@param stats Stats
function M.end_session(stats)
  util.validate({ stats = { stats, { 'table' } } })

  if stats.last_session_start <= 0 then
    return
  end

  local duration = os.time() - stats.last_session_start
  stats.time_coding = stats.time_coding + duration
  stats.last_session_start = 0
end

---Get current date in YYYY-MM-DD format
---@param timestamp integer|nil Optional timestamp, defaults to current time
local function get_date_string(timestamp)
  util.validate({ timestamp = { timestamp, { 'number', 'nil' }, true } })
  return os.date('%Y-%m-%d', timestamp or os.time())
end

---Get timestamp for start of day
---@param date_str string Date in YYYY-MM-DD format
local function get_day_start(date_str)
  util.validate({ date_str = { date_str, { 'string' } } })

  local year, month, day = date_str:match('(%d+)-(%d+)-(%d+)')
  return os.time({ year = year, month = month, day = day, hour = 0, min = 0, sec = 0 })
end

---Calculate streak from daily activity
---@param stats Stats
---@return integer current_streak
---@return integer longest_streak
function M.calculate_streaks(stats)
  util.validate({ stats = { stats, { 'table' } } })

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
  util.validate({
    stats = { stats, { 'table' } },
    lines_today = { lines_today, { 'number' } },
  })

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

---Export data to a specified JSON file
---@param stats Stats
---@param target string
---@param indent? string|nil
function M.export_to_json(stats, target, indent)
  util.validate({
    stats = { stats, { 'table' } },
    target = { target, { 'string' } },
    indent = { indent, { 'string', 'nil' }, true },
  })

  target = vim.fn.fnamemodify(target, ':p')

  local parent_stat = uv.fs_stat(vim.fn.fnamemodify(target, ':h'))
  if not parent_stat or parent_stat.type ~= 'directory' then
    error(('Target not in a valid directory: `%s`'):format(target), vim.log.levels.ERROR)
  end

  if vim.fn.isdirectory(target) == 1 then
    error(('Target is a directory: `%s`'):format(target), vim.log.levels.ERROR)
  end

  local fd = uv.fs_open(target, 'w', tonumber('644', 8))
  if not fd then
    error(('Unable to open target `%s`'):format(target), vim.log.levels.ERROR)
  end

  local ok, data = pcall(vim.json.encode, stats, { sort_keys = true, indent = indent })
  if not ok then
    uv.fs_close(fd)
    error('Unable to encode stats!', vim.log.levels.ERROR)
  end

  uv.fs_write(fd, data)
  uv.fs_close(fd)
end

---Export data to a specified Markdown file
---@param stats Stats
---@param target string
function M.export_to_md(stats, target)
  util.validate({
    stats = { stats, { 'table' } },
    target = { target, { 'string' } },
  })

  target = vim.fn.fnamemodify(target, ':p')

  local parent_stat = uv.fs_stat(vim.fn.fnamemodify(target, ':h'))
  if not parent_stat or parent_stat.type ~= 'directory' then
    error(('Target not in a valid directory: `%s`'):format(target), vim.log.levels.ERROR)
  end

  if vim.list_contains({ '/', '\\' }, target:sub(-1, -1)) or vim.fn.isdirectory(target) == 1 then
    error(('Target is a directory: `%s`'):format(target), vim.log.levels.ERROR)
  end

  local fd = uv.fs_open(target, 'w', tonumber('644', 8))
  if not fd then
    error(('Unable to open target `%s`'):format(target), vim.log.levels.ERROR)
  end

  local data = '# Triforce Stats\n'
  for k, v in pairs(stats) do
    data = ('%s\n## %s\n\n**Value**:'):format(data, k:sub(1, 1):upper() .. k:sub(2))
    if type(v) == 'table' then
      data = ('%s\n'):format(data)
      for key, val in pairs(v) do
        data = ('%s- **%s**: `%s`\n'):format(data, key, vim.inspect(val))
      end
    else
      data = ('%s `%s`\n'):format(data, tostring(v))
    end
  end

  uv.fs_write(fd, data)
  uv.fs_close(fd)
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
