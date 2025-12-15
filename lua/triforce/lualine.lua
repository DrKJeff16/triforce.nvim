local util = require('triforce.util')

---Level component config
---@class LevelShow
---Show level number
---@field level? boolean
---Show progress bar
---@field bar? boolean
---Show percentage
---@field percent? boolean
---Show XP numbers (current/needed)
---@field xp? boolean

---@class BarOptions
---@field length? integer
---@field chars? { filled: string, empty: string }

---Level component config
---@class Triforce.LualineConfig.Level
---Text prefix before level number
---@field prefix? string|'Lv.'
---Stores which components will be shown
---@field show? LevelShow
---Bar options
---@field bar BarOptions

---Achievements component config
---@class Triforce.LualineConfig.Achievements
---Nerd Font trophy icon
---@field icon? string|''
---Show unlocked/total count
---@field show_count? boolean

---Streak component config
---@class Triforce.LualineConfig.Streak
---Nerd Font flame icon
---@field icon? string|''
---Show number of days
---@field show_days?  boolean

---Session time component config
---@class Triforce.LualineConfig.SessionTime
---Nerd Font clock icon
---@field icon? string|''
---Show time duration
---@field show_duration? boolean
---Can be either `'short'` (`2h 34m`) or `'long'` (`2:34:12`)
---@field format 'short'|'long'

---@class Triforce.LualineConfig
---Level component config
---@field level Triforce.LualineConfig.Level
---Achievements component config
---@field achievements Triforce.LualineConfig.Achievements
---Streak component config
---@field streak Triforce.LualineConfig.Streak
---Session time component config
---@field session_time Triforce.LualineConfig.SessionTime

---Lualine integration components for Triforce
---Provides the following modular statusline components:
--- - level
--- - achievements
--- - streak
--- - session time
---@class Triforce.Lualine
local Lualine = {
  ---Default configuration for lualine components
  config = { ---@type Triforce.LualineConfig
    level = {
      prefix = 'Lv.',
      show = { level = true, bar = true, percent = false, xp = false },
      bar = { length = 8, chars = { filled = '█', empty = '░' } },
    },
    achievements = { icon = '', show_count = true },
    streak = { icon = '', show_days = true },
    session_time = { icon = '', show_duration = true, format = 'short' },
  },
}

---Setup lualine integration with custom config
---@param opts? Triforce.LualineConfig User configuration
function Lualine.setup(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Lualine.config = vim.tbl_deep_extend('force', Lualine.config, opts or {})
end

---Get current stats safely
---@return Stats|nil stats
local function get_stats()
  local ok, triforce = pcall(require, 'triforce')
  if not ok then
    return
  end

  return triforce.get_stats()
end

---Generate progress bar
---@param current number Current value
---@param max number Maximum value
---@param length integer Bar length
---@param chars table<string, string> Characters for filled and empty
---@return string bar
local function create_progress_bar(current, max, length, chars)
  util.validate({
    current = { current, { 'number' } },
    max = { max, { 'number' } },
    length = { length, { 'number' } },
    chars = { chars, { 'table' } },
  })

  if max == 0 then
    return chars.empty:rep(length)
  end

  local filled = math.min(math.floor((current / max) * length), length)
  return chars.filled:rep(filled) .. chars.empty:rep(length - filled)
end

---Format time duration
---@param seconds integer Total seconds
---@param format 'short'|'long'
---@return string formatted
local function format_time(seconds, format)
  util.validate({
    seconds = { seconds, { 'number' } },
    format = { format, { 'string' } },
  })
  format = vim.list_contains({ 'short', 'long' }, format) and format or 'long'

  if seconds < 60 then
    return (format == 'short' and '%ds' or '0:00:%02d'):format(seconds)
  end

  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  local fmt
  local items
  if format == 'long' then
    fmt, items = '%d:%02d:%02d', { hours, minutes, seconds % 60 }
  elseif hours > 0 then
    fmt, items = '%dh %dm', { hours, minutes }
  else
    fmt, items = '%dm', { minutes }
  end

  return fmt:format(unpack(items))
end

---Level component - Shows level and XP progress
---@param opts? Triforce.LualineConfig.Level Component-specific options
---@return string component
function Lualine.level(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local stats = get_stats()
  if not stats then
    return ''
  end

  local config = vim.tbl_deep_extend('force', Lualine.config.level, opts or {})

  -- Get XP info
  local stats_module = require('triforce.stats')
  local xp_for_current = stats_module.xp_for_next_level(stats.level - 1)
  local xp_for_next = stats_module.xp_for_next_level(stats.level)
  local xp_needed = xp_for_next - xp_for_current
  local xp_progress = stats.xp - xp_for_current

  -- Build component parts
  local parts = {} ---@type string[]

  -- Prefix and level number
  if config.show.level then
    table.insert(parts, not config.prefix and tostring(stats.level) or (config.prefix .. stats.level))
  end

  -- Progress bar
  if config.show.bar then
    table.insert(parts, create_progress_bar(xp_progress, xp_needed, config.bar.length, config.bar.chars))
  end

  -- Percentage
  if config.show.percent then
    table.insert(parts, ('%d%%'):format(math.floor(xp_progress / xp_needed) * 100))
  end

  -- XP numbers
  if config.show.xp then
    table.insert(parts, ('%d/%d'):format(xp_progress, xp_needed))
  end

  return table.concat(parts, ' ')
end

---Achievements component - Shows unlocked achievement count
---@param opts? { icon: string, show_count: boolean } Component-specific options
---@return string component
function Lualine.achievements(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local stats = get_stats()
  if not stats then
    return ''
  end

  local config = vim.tbl_deep_extend('force', Lualine.config.achievements, opts or {})

  -- Count achievements
  local all_achievements = require('triforce.achievement').get_all_achievements(stats)
  local total = #all_achievements
  local unlocked = 0

  for _, _ in ipairs(stats.achievements or {}) do
    unlocked = unlocked + 1
  end

  -- Build component
  local parts = {} ---@type string[]

  if config.icon ~= '' then
    table.insert(parts, config.icon)
  end

  if config.show_count then
    table.insert(parts, ('%d/%d'):format(unlocked, total))
  end

  return table.concat(parts, ' ')
end

---Streak component - Shows current coding streak
---@param opts? { icon: string, show_days: boolean } Component-specific options
---@return string|'' component
function Lualine.streak(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local stats = get_stats()
  if not stats then
    return ''
  end

  local streak = stats.current_streak or 0

  -- Don't show if no streak
  if streak == 0 then
    return ''
  end

  local config = vim.tbl_deep_extend('force', Lualine.config.streak, opts or {})

  -- Build component
  local parts = {} ---@type string[]

  if config.icon ~= '' then
    table.insert(parts, config.icon)
  end

  if config.show_days then
    table.insert(parts, tostring(streak))
  end

  return table.concat(parts, ' ')
end

---Session time component - Shows current session duration
---@param opts? Triforce.LualineConfig.SessionTime Component-specific options
---@return string component
function Lualine.session_time(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local stats = get_stats()
  if not stats then
    return ''
  end

  -- Calculate session duration
  local session_start = stats.last_session_start or 0
  if session_start == 0 then
    return '' -- No active session
  end

  local config = vim.tbl_deep_extend('force', Lualine.config.session_time, opts or {})

  -- Build component
  local parts = {} ---@type string[]
  local duration = os.time() - session_start

  if config.icon ~= '' then
    table.insert(parts, config.icon)
  end

  if config.show_duration then
    table.insert(parts, format_time(duration, config.format))
  end

  return table.concat(parts, ' ')
end

---Convenience function to get all components at once
---@param opts? Triforce.LualineConfig Configuration for all components
---@return Triforce.LualineConfig components Table with level, achievements, streak, session_time functions
function Lualine.components(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Lualine.setup(opts)
  return {
    level = Lualine.level,
    achievements = Lualine.achievements,
    streak = Lualine.streak,
    session_time = Lualine.session_time,
  }
end

return Lualine
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
