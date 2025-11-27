---@class LevelTier
---@field min_level integer Starting level for this tier
---@field max_level integer Ending level for this tier (use math.huge for infinite)
---@field xp_per_level integer XP required per level in this tier

---@class LevelTier3: LevelTier
---@field max_level number

---@class LevelProgression
---Default: Levels 1-10, 300 XP each
---@field tier_1 LevelTier
---Default: Levels 11-20, 500 XP each
---@field tier_2 LevelTier
---Default: Levels 21+, 1000 XP each
---@field tier_3 LevelTier3

---@class XPRewards
---@field char number XP gained per character typed (default: `1`)
---@field line number XP gained per new line (default: `1`)
---@field save number XP gained per file save (default: `50`)

---@class TriforceLanguage
---@field name string
---@field icon string

---@class TriforceConfig.Notifications
---@field enabled? boolean Show level up and achievement notifications
---@field level_up? boolean Show level up notifications
---@field achievements? boolean Show achievement unlock notifications

---@class TriforceConfig.Keymap
---Keymap for showing profile. A `nil` value sets no keymap
---
---Set to a keymap like `"<leader>tp"` to enable
---@field show_profile string|nil

---@class Triforce.Config.Heat
---@field TriforceHeat1 string
---@field TriforceHeat2 string
---@field TriforceHeat3 string
---@field TriforceHeat4 string

local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO
local util = require('triforce.util')

---@class Triforce
local M = {
  get_stats = require('triforce.tracker').get_stats,
  config = {}, ---@type TriforceConfig
  defaults = function() ---@return TriforceConfig default
    ---Triforce setup configuration
    ---@class TriforceConfig
    local defaults = {
      ---Enable the plugin
      enabled = true, ---@type boolean
      ---Enable gamification features (stats, XP, achievements)
      gamification_enabled = true, ---@type boolean
      ---Notification configuration
      notifications = { enabled = true, level_up = true, achievements = true }, ---@type TriforceConfig.Notifications
      ---Auto-save stats interval in seconds (default: `300`)
      auto_save_interval = 300, ---@type integer
      ---Keymap configuration
      keymap = { show_profile = nil }, ---@type TriforceConfig.Keymap|nil
      ---Custom language definitions:
      ---
      ---```lua
      ----- Example
      ---{ rust = { icon = "", name = "Rust" } }
      ---```
      custom_languages = nil, ---@type table<string, TriforceLanguage>|nil
      ---Custom level progression tiers
      level_progression = { ---@type LevelProgression|nil
        tier_1 = { min_level = 1, max_level = 10, xp_per_level = 300 },
        tier_2 = { min_level = 11, max_level = 20, xp_per_level = 500 },
        tier_3 = { min_level = 21, max_level = math.huge, xp_per_level = 1000 },
      },
      ---Custom XP reward amounts for different actions
      xp_rewards = { char = 1, line = 1, save = 50 }, ---@type XPRewards|nil
      ---Custom path for data file
      db_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'triforce_stats.json'), ---@type string
      ---Default highlight groups for the heats
      heat_highlights = { ---@type Triforce.Config.Heat
        TriforceHeat1 = '#f0f0a0',
        TriforceHeat2 = '#f0a0a0',
        TriforceHeat3 = '#a0a0a0',
        TriforceHeat4 = '#707070',
      },
    }

    return defaults
  end,
}

---@return boolean gamified
function M.has_gamification()
  if not M.config.gamification_enabled then
    vim.notify('Gamification is not enabled in config', WARN)
    return false
  end

  return true
end

---Setup the plugin with user configuration
---@param opts TriforceConfig|nil User configuration options
function M.setup(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  M.config = vim.tbl_deep_extend('force', M.defaults(), opts or {})

  if not M.config.enabled then
    return
  end

  local stats_module = require('triforce.stats')

  -- Apply custom level progression to stats module
  if M.config.level_progression then
    stats_module.level_config = M.config.level_progression
  end

  -- Register custom languages if provided
  if M.config.custom_languages then
    require('triforce.languages').register_custom_languages(M.config.custom_languages)
  end

  -- Setup custom path if provided
  stats_module.db_path = M.config.db_path

  -- Set up keymap if provided
  if M.config.keymap and M.config.keymap.show_profile and M.config.keymap.show_profile ~= '' then
    vim.keymap.set('n', M.config.keymap.show_profile, M.show_profile, {
      desc = 'Show Triforce Profile',
      silent = true,
      noremap = true,
    })
  end

  if M.config.gamification_enabled then
    require('triforce.tracker').setup()
  end
end

---Show profile UI
function M.show_profile()
  if not M.has_gamification() then
    return
  end

  local tracker = require('triforce.tracker')
  if not tracker.current_stats then
    tracker.setup()
  end

  require('triforce.ui.profile').open()
end

---Reset all stats (useful for testing)
function M.reset_stats()
  if not M.has_gamification() then
    return
  end

  require('triforce.tracker').reset_stats()
end

---Debug language tracking
function M.debug_languages()
  if not M.has_gamification() then
    return
  end

  require('triforce.tracker').debug_languages()
end

---Force save stats
function M.save_stats()
  if not M.has_gamification() then
    return
  end

  local tracker = require('triforce.tracker')
  if not tracker.current_stats then
    vim.notify('No stats to save', WARN)
    return
  end

  if tracker.current_stats then
    if require('triforce.stats').save(tracker.current_stats) then
      vim.notify('Stats saved successfully!', INFO)
      return
    end

    error('Failed to save stats!', ERROR)
  end
end

---Debug: Show current XP progress
function M.debug_xp()
  if not M.has_gamification() then
    return
  end

  require('triforce.tracker').debug_xp()
end

---Debug: Test achievement notification
function M.debug_achievement()
  if not M.has_gamification() then
    return
  end

  require('triforce.tracker').debug_achievement()
end

---Debug: Fix level/XP mismatch
function M.debug_fix_level()
  if not M.has_gamification() then
    return
  end

  require('triforce.tracker').debug_fix_level()
end

---Export stats to JSON
---@param file string
---@param indent? string|nil
function M.export_stats_to_json(file, indent)
  util.validate({
    file = { file, { 'string' } },
    indent = { indent, { 'string', 'nil' }, true },
  })

  require('triforce.stats').export_to_json(require('triforce.tracker').get_stats(), file, indent or nil)
end

---Export stats to Markdown
---@param file string
function M.export_stats_to_md(file)
  util.validate({ file = { file, { 'string' } } })

  require('triforce.stats').export_to_md(require('triforce.tracker').get_stats(), file)
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
