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

-- Flag to track if stats need saving
M.dirty = false

-- Last save timestamp to prevent rapid saves
M.last_save_time = 0

local XP_REWARDS = {
  char = 1,
  line = 10,
  save = 50,
}

---Initialize the tracker
function M.setup()
  M.current_stats = stats_module.load()
  stats_module.start_session(M.current_stats)
  stats_module.record_daily_activity(M.current_stats)
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

---Track characters typed (called on text change)
function M.on_text_changed()
  if not M.current_stats then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local current_line_count = vim.api.nvim_buf_line_count(bufnr)
  local previous_line_count = M.buffer_line_counts[bufnr] or current_line_count

  -- Track new lines if line count increased
  if current_line_count > previous_line_count then
    local new_lines = current_line_count - previous_line_count
    M.current_stats.lines_typed = M.current_stats.lines_typed + new_lines
    stats_module.add_xp(M.current_stats, XP_REWARDS.line * new_lines)
  end

  -- Update the tracked line count
  M.buffer_line_counts[bufnr] = current_line_count

  -- Track character typed
  M.current_stats.chars_typed = M.current_stats.chars_typed + 1
  M.dirty = true

  -- Track character by language
  local filetype = vim.bo[bufnr].filetype
  if filetype and filetype ~= "" then
    if languages.should_track(filetype) then
      -- Initialize if needed
      if not M.current_stats.chars_by_language then
        M.current_stats.chars_by_language = {}
      end

      M.current_stats.chars_by_language[filetype] = (M.current_stats.chars_by_language[filetype] or 0) + 1
    end
  end

  local leveled_up = stats_module.add_xp(M.current_stats, XP_REWARDS.char)

  if leveled_up then
    M.notify_level_up()
  end
  local achievements = stats_module.check_achievements(M.current_stats)
  for _, achievement in ipairs(achievements) do
    M.notify_achievement(achievement)
  end
end

---Track new lines (could be enhanced with more detailed tracking)
function M.on_new_line()
  if not M.current_stats then
    return
  end

  M.current_stats.lines_typed = M.current_stats.lines_typed + 1
  stats_module.add_xp(M.current_stats, XP_REWARDS.line)
end

---Track file saves
function M.on_save()
  if not M.current_stats then
    return
  end

  local leveled_up = stats_module.add_xp(M.current_stats, XP_REWARDS.save)
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

  vim.notify(
    string.format('Level Up! You are now level %d!', M.current_stats.level),
    vim.log.levels.INFO,
    { title = 'Triforce' }
  )
end

---Notify user of achievement unlock
---@param achievement_name string
function M.notify_achievement(achievement_name)
  vim.notify(
    string.format('Achievement Unlocked: %s!', achievement_name),
    vim.log.levels.INFO,
    { title = 'Triforce' }
  )
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
  local msg = "Languages tracked:\n"

  for lang, chars in pairs(langs) do
    msg = msg .. string.format("  %s: %d chars\n", lang, chars)
    count = count + 1
  end

  if count == 0 then
    msg = "No languages tracked yet"
  else
    msg = msg .. string.format("\nTotal: %d languages", count)
  end

  vim.notify(msg, vim.log.levels.INFO)

  -- Also print to check current filetype
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  vim.notify(string.format("Current filetype: '%s'", ft or "none"), vim.log.levels.INFO)
end

return M
