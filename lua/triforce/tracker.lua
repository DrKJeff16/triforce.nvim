---Activity tracker module - monitors typing and awards XP
local stats_module = require('triforce.stats')

local M = {}

---@type Stats|nil
M.current_stats = nil

---@type number|nil
M.autocmd_group = nil

---XP rewards
local XP_REWARDS = {
  char = 1, -- 1 XP per character
  line = 10, -- 10 XP per new line
  save = 50, -- 50 XP per save
}

---Initialize the tracker
function M.setup()
  -- Load stats
  M.current_stats = stats_module.load()

  -- Start session
  stats_module.start_session(M.current_stats)

  -- Create autocmd group
  M.autocmd_group = vim.api.nvim_create_augroup('TriforceTracker', { clear = true })

  -- Track text changes
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = M.autocmd_group,
    callback = function()
      M.on_text_changed()
    end,
  })

  -- Track saves
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = M.autocmd_group,
    callback = function()
      M.on_save()
    end,
  })

  -- Save stats on exit
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = M.autocmd_group,
    callback = function()
      M.shutdown()
    end,
  })

  -- Auto-save every 5 minutes
  local timer = vim.loop.new_timer()
  timer:start(
    300000, -- 5 minutes
    300000,
    vim.schedule_wrap(function()
      if M.current_stats then
        stats_module.save(M.current_stats)
      end
    end)
  )
end

---Track characters typed (called on text change)
function M.on_text_changed()
  if not M.current_stats then
    return
  end

  -- Get change info (simplified - just increment)
  -- In a more sophisticated version, you could use nvim_buf_attach to track exact changes
  M.current_stats.chars_typed = M.current_stats.chars_typed + 1

  -- Award XP
  local leveled_up = stats_module.add_xp(M.current_stats, XP_REWARDS.char)

  if leveled_up then
    M.notify_level_up()
  end

  -- Check achievements
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

  if leveled_up then
    M.notify_level_up()
  end

  -- Save stats to disk
  stats_module.save(M.current_stats)
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
  stats_module.save(M.current_stats)
end

---Reset all stats (for testing)
function M.reset_stats()
  M.current_stats = vim.deepcopy(stats_module.default_stats)
  stats_module.save(M.current_stats)
  vim.notify('Stats reset!', vim.log.levels.INFO)
end

return M
