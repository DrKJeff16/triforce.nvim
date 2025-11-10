---Lualine integration components for Triforce
---Provides modular statusline components for level, achievements, streak, and session time
---@class Triforce.Lualine
local M = {}

---Default configuration for lualine components
---@class Triforce.Lualine.Config
M.config = {
  -- Level component config
  level = {
    prefix = 'Lv.', -- Text prefix before level number
    show_level = true, -- Show level number
    show_bar = true, -- Show progress bar
    show_percent = false, -- Show percentage
    show_xp = false, -- Show XP numbers (current/needed)
    bar_length = 6, -- Length of progress bar
    bar_chars = { filled = '█', empty = '░' }, -- Bar characters
  },

  -- Achievements component config
  achievements = {
    icon = '', -- Nerd Font trophy icon
    show_count = true, -- Show unlocked/total count
  },

  -- Streak component config
  streak = {
    icon = '', -- Nerd Font flame icon
    show_days = true, -- Show number of days
  },

  -- Session time component config
  session_time = {
    icon = '', -- Nerd Font clock icon
    show_duration = true, -- Show time duration
    format = 'short', -- 'short' (2h 34m) or 'long' (2:34:12)
  },
}

---Setup lualine integration with custom config
---@param opts Triforce.Lualine.Config|nil User configuration
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend('force', M.config, opts)
  end
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
  if max == 0 then
    return chars.empty:rep(length)
  end

  local filled = math.floor((current / max) * length)
  filled = math.min(filled, length) -- Clamp to bar length

  local bar = chars.filled:rep(filled) .. chars.empty:rep(length - filled)
  return bar
end

---Format time duration
---@param seconds number Total seconds
---@param format string 'short' or 'long'
---@return string formatted
local function format_time(seconds, format)
  if seconds < 60 then
    return (format == 'short' and '%ds' or '0:00:%02d'):format(seconds)
  end

  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60

  if format == 'short' then
    if hours > 0 then
      return ('%dh %dm'):format(hours, minutes)
    end

    return ('%dm'):format(minutes)
  end

  return ('%d:%02d:%02d'):format(hours, minutes, secs)
end

---Level component - Shows level and XP progress
---@param opts table|nil Component-specific options
---@return string component
function M.level(opts)
  local config = vim.tbl_deep_extend('force', M.config.level, opts or {})
  local stats = get_stats()

  if not stats then
    return ''
  end

  -- Get XP info
  local stats_module = require('triforce.stats')
  local current_xp = stats.xp
  local level = stats.level
  local xp_for_current = stats_module.xp_for_next_level(level - 1)
  local xp_for_next = stats_module.xp_for_next_level(level)
  local xp_needed = xp_for_next - xp_for_current
  local xp_progress = current_xp - xp_for_current

  -- Build component parts
  local parts = {} ---@type string[]

  -- Prefix and level number
  if config.show_level then
    local level_text = config.prefix and config.prefix .. level or tostring(level)
    table.insert(parts, level_text)
  end

  -- Progress bar
  if config.show_bar then
    local bar = create_progress_bar(xp_progress, xp_needed, config.bar_length, config.bar_chars)
    table.insert(parts, bar)
  end

  -- Percentage
  if config.show_percent then
    local percent = math.floor((xp_progress / xp_needed) * 100)
    table.insert(parts, ('%d%%'):format(percent))
  end

  -- XP numbers
  if config.show_xp then
    table.insert(parts, ('%d/%d'):format(xp_progress, xp_needed))
  end

  return table.concat(parts, ' ')
end

---Achievements component - Shows unlocked achievement count
---@param opts { icon: string, show_count: boolean }|nil Component-specific options
---@return string component
function M.achievements(opts)
  local config = vim.tbl_deep_extend('force', M.config.achievements, opts or {})
  local stats = get_stats()

  if not stats then
    return ''
  end

  -- Count achievements
  local stats_module = require('triforce.stats')
  local all_achievements = stats_module.get_all_achievements(stats)
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
---@param opts { icon: string, show_days: boolean }|nil Component-specific options
---@return string component
function M.streak(opts)
  local config = vim.tbl_deep_extend('force', M.config.streak, opts or {})
  local stats = get_stats()

  if not stats then
    return ''
  end

  local streak = stats.current_streak or 0

  -- Don't show if no streak
  if streak == 0 then
    return ''
  end

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
---@param opts { format: string, icon: string, show_duration: boolean }|nil Component-specific options
---@return string component
function M.session_time(opts)
  local config = vim.tbl_deep_extend('force', M.config.session_time, opts or {})
  local stats = get_stats()

  if not stats then
    return ''
  end

  -- Calculate session duration
  local session_start = stats.last_session_start or 0
  if session_start == 0 then
    return '' -- No active session
  end

  local duration = os.time() - session_start

  -- Build component
  local parts = {} ---@type string[]

  if config.icon ~= '' then
    table.insert(parts, config.icon)
  end

  if config.show_duration then
    table.insert(parts, format_time(duration, config.format))
  end

  return table.concat(parts, ' ')
end

---Convenience function to get all components at once
---@param opts table|nil Configuration for all components
---@return table components Table with level, achievements, streak, session_time functions
function M.components(opts)
  M.setup(opts)

  return {
    level = function()
      return M.level()
    end,
    achievements = function()
      return M.achievements()
    end,
    streak = function()
      return M.streak()
    end,
    session_time = function()
      return M.session_time()
    end,
  }
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
