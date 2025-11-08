---@class TriforceConfig
---@field enabled boolean Enable the plugin
---@field gamification_enabled boolean Enable gamification features (stats, XP, achievements)
---@field notifications_enabled boolean Show level up and achievement notifications
---@field auto_save_interval number Auto-save stats interval in seconds (default: 300)

local M = {}

---Default configuration
---@type TriforceConfig
local defaults = {
  enabled = true,
  gamification_enabled = true,
  notifications_enabled = true,
  auto_save_interval = 300,
}

---@type TriforceConfig
M.config = vim.deepcopy(defaults)

---Setup the plugin with user configuration
---@param opts TriforceConfig|nil User configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})

  -- Initialize gamification if enabled
  if M.config.enabled and M.config.gamification_enabled then
    local tracker = require('triforce.tracker')
    tracker.setup()
  end
end

---Show profile UI
function M.show_profile()
  -- Check if gamification is enabled
  if not M.config.gamification_enabled then
    vim.notify('Gamification is not enabled in config', vim.log.levels.WARN)
    return
  end

  -- Lazy init tracker if not already done
  local tracker = require('triforce.tracker')
  if not tracker.current_stats then
    tracker.setup()
  end

  local profile = require('triforce.ui.profile')
  profile.show()
end

---Get current stats
---@return Stats|nil
function M.get_stats()
  local tracker = require('triforce.tracker')
  return tracker.get_stats()
end

---Reset all stats (useful for testing)
function M.reset_stats()
  if not M.config.gamification_enabled then
    vim.notify('Gamification is disabled', vim.log.levels.WARN)
    return
  end

  local tracker = require('triforce.tracker')
  tracker.reset_stats()
end

return M
