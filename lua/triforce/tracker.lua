local util = require('triforce.util')
local uv = vim.uv or vim.loop

---@class Triforce.Tracker
local M = {}

---@type Stats|nil
M.current_stats = nil

---@type integer|nil
M.autocmd_group = nil

-- Track line count per buffer to detect new lines
---@type table<integer, integer>
M.buffer_line_counts = {}

-- Track lines typed today
M.lines_today = 0

-- Track current date to detect day rollover
M.current_date = os.date('%Y-%m-%d')

-- Flag to track if stats need saving
M.dirty = false

-- Last save timestamp to prevent rapid saves
M.last_save_time = 0

---Get XP rewards from config
---@return XPRewards rewards
local function get_xp_rewards()
  return require('triforce').config.xp_rewards or { char = 1, line = 1, save = 50 }
end

---Initialize the tracker
function M.setup()
  local stats_module = require('triforce.stats')

  M.current_stats = stats_module.load()
  M.current_date = os.date('%Y-%m-%d')
  M.lines_today = 0
  stats_module.start_session(M.current_stats)
  M.autocmd_group = vim.api.nvim_create_augroup('TriforceTracker', { clear = true })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = M.autocmd_group,
    callback = function()
      M.on_text_changed()
    end,
  })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = M.autocmd_group,
    callback = function(ev)
      if vim.api.nvim_get_option_value('modified', { buf = ev.buf }) then
        M.on_save()
      end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = M.autocmd_group,
    callback = function()
      M.shutdown()
    end,
  })
  -- Auto-save timer (every 30 seconds if dirty)
  local timer = uv.new_timer()
  if not timer then
    return
  end

  timer:start(
    30000,
    30000,
    vim.schedule_wrap(function()
      if not (M.current_stats and M.dirty) then
        return
      end

      local now = os.time()
      if now - M.last_save_time < 5 then -- Debounce: only save if at least 5 seconds since last save
        return
      end

      if not stats_module.save(M.current_stats) then
        return
      end

      M.dirty = false
      M.last_save_time = now
    end)
  )
end

---Check if date has rolled over and update daily activity
local function check_date_rollover()
  local today = os.date('%Y-%m-%d')
  if today == M.current_date then
    return
  end

  -- Day changed - record yesterday's lines and reset
  if M.lines_today > 0 and M.current_stats then
    require('triforce.stats').record_daily_activity(M.current_stats, M.lines_today)
  end
  M.current_date = today
  M.lines_today = 0
end

---Track characters typed (called on text change)
function M.on_text_changed()
  if not M.current_stats then
    return
  end

  local stats_module = require('triforce.stats')

  -- Check for day rollover
  check_date_rollover()

  local bufnr = vim.api.nvim_get_current_buf()
  local current_line_count = vim.api.nvim_buf_line_count(bufnr)
  local previous_line_count = M.buffer_line_counts[bufnr] or current_line_count

  -- Track new lines if line count increased
  if current_line_count > previous_line_count then
    local new_lines = current_line_count - previous_line_count
    M.current_stats.lines_typed = M.current_stats.lines_typed + new_lines
    M.lines_today = M.lines_today + new_lines
    stats_module.add_xp(M.current_stats, get_xp_rewards().line * new_lines)
  end

  -- Update the tracked line count
  M.buffer_line_counts[bufnr] = current_line_count

  -- Track character typed
  M.current_stats.chars_typed = M.current_stats.chars_typed + 1
  M.dirty = true

  -- Track character by language
  local filetype = vim.bo[bufnr].filetype
  if filetype and filetype ~= '' and require('triforce.languages').should_track(filetype) then
    -- Initialize if needed
    if not M.current_stats.chars_by_language then
      M.current_stats.chars_by_language = {}
    end

    M.current_stats.chars_by_language[filetype] = (M.current_stats.chars_by_language[filetype] or 0) + 1
  end

  if stats_module.add_xp(M.current_stats, get_xp_rewards().char) then
    M.notify_level_up()
  end

  for _, achievement in ipairs(stats_module.check_achievements(M.current_stats)) do
    M.notify_achievement(achievement.name, achievement.desc, achievement.icon)
  end
end

---Track new lines (could be enhanced with more detailed tracking)
function M.on_new_line()
  if not M.current_stats then
    return
  end

  M.current_stats.lines_typed = M.current_stats.lines_typed + 1
  require('triforce.stats').add_xp(M.current_stats, get_xp_rewards().line)
end

---Track file saves
function M.on_save()
  if not M.current_stats then
    return
  end

  local leveled_up = require('triforce.stats').add_xp(M.current_stats, get_xp_rewards().save)
  M.dirty = true

  if leveled_up then
    M.notify_level_up()
  end

  -- Save immediately on file save
  local now = os.time()
  if now - M.last_save_time < 2 then -- Prevent saves more than once per 2 seconds
    return
  end

  if require('triforce.stats').save(M.current_stats) then
    M.dirty = false
    M.last_save_time = now
  end
end

---Notify user of level up
function M.notify_level_up()
  if not M.current_stats then
    return
  end

  local notifications = require('triforce').config.notifications
  if not notifications or not (notifications.enabled and notifications.level_up) then
    return
  end

  local level = M.current_stats.level
  local xp = M.current_stats.xp
  local next_xp = require('triforce.stats').xp_for_next_level(level)

  vim.notify(
    ('󰓏 Level %d Achieved!\n\n%d XP earned • %d XP to next level'):format(level, xp, next_xp - xp),
    vim.log.levels.INFO,
    { title = ' Triforce', timeout = 3000 }
  )
end

---Notify user of achievement unlock
---@param achievement_name string
---@param achievement_desc string|nil
---@param achievement_icon string|nil
function M.notify_achievement(achievement_name, achievement_desc, achievement_icon)
  util.validate({
    achievement_name = { achievement_name, { 'string' } },
    achievement_desc = { achievement_desc, { 'string', 'nil' }, true },
    achievement_icon = { achievement_icon, { 'string', 'nil' }, true },
  })

  local notifications = require('triforce').config.notifications
  if not notifications or not (notifications.enabled and notifications.achievements) then
    return
  end

  local message = (achievement_icon or '🏆') .. ' ' .. achievement_name
  if achievement_desc then
    message = message .. '\n\n' .. achievement_desc
  end

  vim.notify(message, vim.log.levels.INFO, { title = ' Achievement Unlocked', timeout = 3500 })
end

---Get current stats
---@return Stats|nil
function M.get_stats()
  return M.current_stats
end

---Shutdown tracker and save
function M.shutdown()
  if not M.current_stats then
    return
  end

  local stats_module = require('triforce.stats')

  -- Record today's lines before shutdown
  if M.lines_today > 0 then
    stats_module.record_daily_activity(M.current_stats, M.lines_today)
  end

  stats_module.end_session(M.current_stats)

  -- Force save on shutdown, ignore debounce
  if not stats_module.save(M.current_stats) then
    vim.notify('Failed to save stats on shutdown!', vim.log.levels.ERROR)
    return
  end

  M.dirty = false
  M.last_save_time = os.time()
end

---Reset all stats (for testing)
function M.reset_stats()
  local stats_module = require('triforce.stats')

  M.current_stats = vim.deepcopy(stats_module.default_stats)

  stats_module.save(M.current_stats)
  vim.notify('Stats reset!', vim.log.levels.INFO)
end

---Debug: Print current language stats
function M.debug_languages()
  if not M.current_stats then
    vim.notify('No stats loaded', vim.log.levels.WARN)
    return
  end

  local langs = M.current_stats.chars_by_language or {}
  local count = 0
  local msg = 'Languages tracked:\n'

  for lang, chars in pairs(langs) do
    msg = ('%s  %s: %d chars\n'):format(msg, lang, chars)
    count = count + 1
  end

  msg = count == 0 and 'No languages tracked yet' or ('%s\nTotal: %d languages'):format(msg, count)
  vim.notify(msg, vim.log.levels.INFO)

  -- Also print to check current filetype
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  vim.notify(("Current filetype: '%s'"):format(ft or 'none'), vim.log.levels.INFO)
end

---Debug: Show current XP progress
function M.debug_xp()
  if not M.current_stats then
    vim.notify('No stats loaded', vim.log.levels.WARN)
    return
  end

  local stats_module = require('triforce.stats')

  local current_xp = M.current_stats.xp
  local current_level = M.current_stats.level
  local next_level_xp = stats_module.xp_for_next_level(current_level)
  local prev_level_xp = current_level > 1 and stats_module.xp_for_next_level(current_level - 1) or 0
  local xp_in_level = current_xp - prev_level_xp
  local xp_needed = next_level_xp - prev_level_xp
  local progress = math.floor((xp_in_level / xp_needed) * 100)

  vim.notify(
    ('󰓏 Level %d\n\nCurrent XP: %d / %d\nProgress: %d%%\nXP to next level: %d'):format(
      current_level,
      xp_in_level,
      xp_needed,
      progress,
      next_level_xp - current_xp
    ),
    vim.log.levels.INFO,
    { title = ' Triforce Debug', timeout = 5000 }
  )
end

---Debug: Show random achievement notification (for testing)
function M.debug_achievement()
  if not M.current_stats then
    vim.notify('No stats loaded', vim.log.levels.WARN)
    return
  end

  local achievements = require('triforce.stats').get_all_achievements(M.current_stats)

  -- Pick a random achievement
  local random_idx = math.random(1, #achievements)
  local achievement = achievements[random_idx]

  -- Show notification
  M.notify_achievement(achievement.name, achievement.desc, achievement.icon)

  -- Also show status in separate notification
  local status = achievement.check and '✓ Unlocked' or '✗ Locked'
  vim.notify(
    ('Test notification for: %s\n\nStatus: %s'):format(achievement.name, status),
    vim.log.levels.INFO,
    { title = ' Debug Info', timeout = 2000 }
  )
end

---Debug: Fix level/XP mismatch by recalculating level from XP
function M.debug_fix_level()
  if not M.current_stats then
    vim.notify('No stats loaded', vim.log.levels.WARN)
    return
  end

  local stats_module = require('triforce.stats')

  local old_level = M.current_stats.level
  local current_xp = M.current_stats.xp
  local calculated_level = stats_module.calculate_level(current_xp)

  if old_level == calculated_level then
    vim.notify(
      ('✓ No mismatch detected!\n\nLevel %d matches %d XP'):format(old_level, current_xp),
      vim.log.levels.INFO,
      { title = ' Triforce Debug' }
    )
    return
  end

  M.current_stats.level = calculated_level
  M.dirty = true
  stats_module.save(M.current_stats)

  vim.notify(
    ('✓ Level fixed!\n\nOld: Level %d\nNew: Level %d\nXP: %d'):format(old_level, calculated_level, current_xp),
    vim.log.levels.WARN,
    { title = ' Triforce Debug', timeout = 5000 }
  )
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
