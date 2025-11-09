---Activity tracker module - monitors typing and awards XP
local stats_module = require('triforce.stats')
local languages = require('triforce.languages')

local M = {}

---@type Stats|nil
M.current_stats = nil

---@type number|nil
M.autocmd_group = nil

-- Track line count per buffer to detect new lines
---@type table<number, number>
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
---@return table
local function get_xp_rewards()
  local config = require('triforce').config
  return config.xp_rewards or {
    char = 1,
    line = 1,
    save = 50,
  }
end

---Initialize the tracker
function M.setup()
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
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = M.autocmd_group,
    callback = function()
      M.on_save()
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = M.autocmd_group,
    callback = function()
      M.shutdown()
    end,
  })
  -- Auto-save timer (every 30 seconds if dirty)
  local timer = vim.loop.new_timer()
  timer:start(
    30000,
    30000,
    vim.schedule_wrap(function()
      if M.current_stats and M.dirty then
        local now = os.time()
        -- Debounce: only save if at least 5 seconds since last save
        if now - M.last_save_time >= 5 then
          local ok = stats_module.save(M.current_stats)
          if ok then
            M.dirty = false
            M.last_save_time = now
          end
        end
      end
    end)
  )
end

---Check if date has rolled over and update daily activity
local function check_date_rollover()
  local today = os.date('%Y-%m-%d')
  if today ~= M.current_date then
    -- Day changed - record yesterday's lines and reset
    if M.lines_today > 0 and M.current_stats then
      stats_module.record_daily_activity(M.current_stats, M.lines_today)
    end
    M.current_date = today
    M.lines_today = 0
  end
end

---Track characters typed (called on text change)
function M.on_text_changed()
  if not M.current_stats then
    return
  end

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
    local xp_rewards = get_xp_rewards()
    stats_module.add_xp(M.current_stats, xp_rewards.line * new_lines)
  end

  -- Update the tracked line count
  M.buffer_line_counts[bufnr] = current_line_count

  -- Track character typed
  M.current_stats.chars_typed = M.current_stats.chars_typed + 1
  M.dirty = true

  -- Track character by language
  local filetype = vim.bo[bufnr].filetype
  if filetype and filetype ~= '' then
    if languages.should_track(filetype) then
      -- Initialize if needed
      if not M.current_stats.chars_by_language then
        M.current_stats.chars_by_language = {}
      end

      M.current_stats.chars_by_language[filetype] = (M.current_stats.chars_by_language[filetype] or 0) + 1
    end
  end

  local xp_rewards = get_xp_rewards()
  local leveled_up = stats_module.add_xp(M.current_stats, xp_rewards.char)

  if leveled_up then
    M.notify_level_up()
  end

  local achievements = stats_module.check_achievements(M.current_stats)
  for _, achievement in ipairs(achievements) do
    M.notify_achievement(achievement.name, achievement.desc, achievement.icon)
  end
end

---Track new lines (could be enhanced with more detailed tracking)
function M.on_new_line()
  if not M.current_stats then
    return
  end

  M.current_stats.lines_typed = M.current_stats.lines_typed + 1
  local xp_rewards = get_xp_rewards()
  stats_module.add_xp(M.current_stats, xp_rewards.line)
end

---Track file saves
function M.on_save()
  if not M.current_stats then
    return
  end

  local xp_rewards = get_xp_rewards()
  local leveled_up = stats_module.add_xp(M.current_stats, xp_rewards.save)
  M.dirty = true

  if leveled_up then
    M.notify_level_up()
  end

  -- Save immediately on file save
  local now = os.time()
  if now - M.last_save_time >= 2 then -- Prevent saves more than once per 2 seconds
    local ok = stats_module.save(M.current_stats)
    if ok then
      M.dirty = false
      M.last_save_time = now
    end
  end
end

---Notify user of level up
function M.notify_level_up()
  if not M.current_stats then
    return
  end

  local config = require('triforce').config
  if not (config.notifications.enabled and config.notifications.level_up) then
    return
  end

  local level = M.current_stats.level
  local xp = M.current_stats.xp
  local next_xp = stats_module.xp_for_next_level(level)

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
  local config = require('triforce').config
  if not (config.notifications.enabled and config.notifications.achievements) then
    return
  end

  local icon = achievement_icon or '🏆'
  local message = icon .. ' ' .. achievement_name

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

  -- Record today's lines before shutdown
  if M.lines_today > 0 then
    stats_module.record_daily_activity(M.current_stats, M.lines_today)
  end

  stats_module.end_session(M.current_stats)

  -- Force save on shutdown, ignore debounce
  local ok = stats_module.save(M.current_stats)
  if ok then
    M.dirty = false
    M.last_save_time = os.time()
  else
    vim.notify('Failed to save stats on shutdown!', vim.log.levels.ERROR)
  end
end

---Reset all stats (for testing)
function M.reset_stats()
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
    msg = msg .. ('  %s: %d chars\n'):format(lang, chars)
    count = count + 1
  end

  if count == 0 then
    msg = 'No languages tracked yet'
  else
    msg = msg .. ('\nTotal: %d languages'):format(count)
  end

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

  local achievements = stats_module.get_all_achievements(M.current_stats)

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

  local old_level = M.current_stats.level
  local current_xp = M.current_stats.xp
  local calculated_level = stats_module.calculate_level(current_xp)

  if old_level == calculated_level then
    vim.notify(
      ('✓ No mismatch detected!\n\nLevel %d matches %d XP'):format(old_level, current_xp),
      vim.log.levels.INFO,
      { title = ' Triforce Debug' }
    )
  else
    M.current_stats.level = calculated_level
    M.dirty = true
    stats_module.save(M.current_stats)

    vim.notify(
      ('✓ Level fixed!\n\nOld: Level %d\nNew: Level %d\nXP: %d'):format(old_level, calculated_level, current_xp),
      vim.log.levels.WARN,
      { title = ' Triforce Debug', timeout = 5000 }
    )
  end
end

return M
