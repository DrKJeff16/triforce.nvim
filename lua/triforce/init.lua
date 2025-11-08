---@class LevelTier
---@field min_level number Starting level for this tier
---@field max_level number Ending level for this tier (use math.huge for infinite)
---@field xp_per_level number XP required per level in this tier

---@class LevelProgression
---@field tier_1 LevelTier Levels 1-10
---@field tier_2 LevelTier Levels 11-20
---@field tier_3 LevelTier Levels 21+

---@class TriforceConfig
---@field enabled boolean Enable the plugin
---@field gamification_enabled boolean Enable gamification features (stats, XP, achievements)
---@field notifications table Notification configuration
---@field notifications.enabled boolean Show level up and achievement notifications
---@field notifications.level_up boolean Show level up notifications
---@field notifications.achievements boolean Show achievement unlock notifications
---@field auto_save_interval number Auto-save stats interval in seconds (default: 300)
---@field keymap table|nil Keymap configuration
---@field keymap.show_profile string|nil Keymap for showing profile (default: nil = no keymap)
---@field custom_languages table<string, table>|nil Custom language definitions { filetype = { icon = "", name = "" } }
---@field level_progression LevelProgression|nil Custom level progression tiers

local M = {}

---Default configuration
---@type TriforceConfig
local defaults = {
  enabled = true,
  gamification_enabled = true,
  notifications = {
    enabled = true,
    level_up = true,
    achievements = true,
  },
  auto_save_interval = 300,
  keymap = {
    show_profile = nil, -- Set to a keymap like "<leader>tp" to enable
  },
  custom_languages = nil, -- { rust = { icon = "", name = "Rust" } }
  level_progression = {
    tier_1 = { min_level = 1, max_level = 10, xp_per_level = 300 },   -- Levels 1-10: 300 XP each
    tier_2 = { min_level = 11, max_level = 20, xp_per_level = 500 },  -- Levels 11-20: 500 XP each
    tier_3 = { min_level = 21, max_level = math.huge, xp_per_level = 1000 }, -- Levels 21+: 1000 XP each
  },
}

---@type TriforceConfig
M.config = vim.deepcopy(defaults)

---Setup the plugin with user configuration
---@param opts TriforceConfig|nil User configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})

  -- Apply custom level progression to stats module
  if M.config.level_progression then
    local stats_module = require('triforce.stats')
    stats_module.level_config = M.config.level_progression
  end

  -- Register custom languages if provided
  if M.config.custom_languages then
    local languages = require('triforce.languages')
    languages.register_custom_languages(M.config.custom_languages)
  end

  -- Set up keymap if provided
  if M.config.keymap and M.config.keymap.show_profile then
    vim.keymap.set('n', M.config.keymap.show_profile, function()
      M.show_profile()
    end, { desc = 'Show Triforce Profile', silent = true })
  end

  if M.config.enabled and M.config.gamification_enabled then
    local tracker = require('triforce.tracker')
    tracker.setup()
  end
end

---Show profile UI
function M.show_profile()
  if not M.config.gamification_enabled then
    vim.notify('Gamification is not enabled in config', vim.log.levels.WARN)
    return
  end
  local tracker = require('triforce.tracker')
  if not tracker.current_stats then
    tracker.setup()
  end

  local profile = require('triforce.ui.profile')
  profile.open()
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

---Debug language tracking
function M.debug_languages()
  if not M.config.gamification_enabled then
    vim.notify('Gamification is disabled', vim.log.levels.WARN)
    return
  end

  local tracker = require('triforce.tracker')
  tracker.debug_languages()
end

---Force save stats
function M.save_stats()
  if not M.config.gamification_enabled then
    vim.notify('Gamification is disabled', vim.log.levels.WARN)
    return
  end

  local tracker = require('triforce.tracker')
  local stats_module = require('triforce.stats')

  if tracker.current_stats then
    local ok = stats_module.save(tracker.current_stats)
    if ok then
      vim.notify('Stats saved successfully!', vim.log.levels.INFO)
    else
      vim.notify('Failed to save stats!', vim.log.levels.ERROR)
    end
  else
    vim.notify('No stats to save', vim.log.levels.WARN)
  end
end

return M
