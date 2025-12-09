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

---@class TriforceConfig.Keymap
---Keymap for showing profile. A `nil` value sets no keymap
---
---Set to a keymap like `"<leader>tp"` to enable
---@field show_profile? string

---Notification configuration
---@class TriforceConfig.Notifications
---Show level up and achievement notifications
---@field enabled? boolean
---Show level up notifications
---@field level_up? boolean
---Show achievement unlock notifications
---@field achievements? boolean

---Default highlight groups for the heats
---@class Triforce.Config.Heat
---@field TriforceHeat1? string
---@field TriforceHeat2? string
---@field TriforceHeat3? string
---@field TriforceHeat4? string

---Triforce setup configuration
---@class TriforceConfig
---Enable the plugin
---@field enabled? boolean
---Enable gamification features (stats, XP, achievements)
---@field gamification_enabled? boolean
---Notification configuration
---@field notifications? TriforceConfig.Notifications
---Auto-save stats interval in seconds (default: `300`)
---@field auto_save_interval? integer
---Keymap configuration
---@field keymap? TriforceConfig.Keymap
---Custom language definitions:
---
---```lua
----- Example
---{ rust = { icon = "", name = "Rust" } }
---```
---@field custom_languages? table<string, TriforceLanguage>
---Custom level progression tiers
---@field level_progression? LevelProgression
---Custom XP reward amounts for different actions
---@field xp_rewards? XPRewards
---Custom path for data file
---@field db_path? string
---Default highlight groups for the heats
---@field heat_highlights? Triforce.Config.Heat
---Enable debugging messages
---@field debug? boolean

local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO
local util = require('triforce.util')

---@class Triforce
local Triforce = {
  get_stats = require('triforce.tracker').get_stats,
  config = {}, ---@type TriforceConfig
  defaults = function() ---@return TriforceConfig default
    local defaults = { ---@type TriforceConfig
      enabled = true,
      gamification_enabled = true,
      debug = false,
      notifications = { enabled = true, level_up = true, achievements = true },
      auto_save_interval = 300,
      keymap = { show_profile = nil },
      custom_languages = nil,
      level_progression = {
        tier_1 = { min_level = 1, max_level = 10, xp_per_level = 300 },
        tier_2 = { min_level = 11, max_level = 20, xp_per_level = 500 },
        tier_3 = { min_level = 21, max_level = math.huge, xp_per_level = 1000 },
      },
      xp_rewards = { char = 1, line = 1, save = 50 },
      db_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'triforce_stats.json'),
      heat_highlights = {
        TriforceHeat1 = '#f0f0a0',
        TriforceHeat2 = '#f0a0a0',
        TriforceHeat3 = '#a0a0a0',
        TriforceHeat4 = '#707070',
      },
    }

    return defaults
  end,
}

---@param silent? boolean
---@return boolean gamified
function Triforce.has_gamification(silent)
  util.validate({ silent = { silent, { 'boolean', 'nil' }, true } })

  silent = silent ~= nil and silent or false

  if not Triforce.config.gamification_enabled then
    if not silent then
      vim.notify('Gamification is not enabled in config', WARN)
    end
    return false
  end

  return true
end

---Setup the plugin with user configuration
---@param opts? TriforceConfig User configuration options
function Triforce.setup(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Triforce.config = vim.tbl_deep_extend('force', Triforce.defaults(), opts or {})

  if not Triforce.config.enabled then
    return
  end

  local stats_module = require('triforce.stats')

  -- Apply custom level progression to stats module
  if Triforce.config.level_progression then
    stats_module.level_config = Triforce.config.level_progression
  end

  -- Register custom languages if provided
  if Triforce.config.custom_languages then
    require('triforce.languages').register_custom_languages(Triforce.config.custom_languages)
  end

  -- Setup custom path if provided
  stats_module.db_path = Triforce.config.db_path

  -- Set up keymap if provided
  if Triforce.config.keymap and Triforce.config.keymap.show_profile and Triforce.config.keymap.show_profile ~= '' then
    vim.keymap.set('n', Triforce.config.keymap.show_profile, Triforce.show_profile, {
      desc = 'Show Triforce Profile',
      silent = true,
      noremap = true,
    })
  end

  if Triforce.has_gamification(true) then
    require('triforce.tracker').setup()
  end
end

---Show profile UI
function Triforce.show_profile()
  if not Triforce.has_gamification() then
    return
  end

  local tracker = require('triforce.tracker')
  if not tracker.current_stats then
    tracker.setup()
  end

  require('triforce.ui.profile').open()
end

---Reset all stats (useful for testing)
function Triforce.reset_stats()
  if not Triforce.has_gamification() then
    return
  end

  require('triforce.tracker').reset_stats()
end

---Debug language tracking
function Triforce.debug_languages()
  if not Triforce.has_gamification() then
    return
  end

  require('triforce.tracker').debug_languages()
end

---Force save stats
function Triforce.save_stats()
  if not Triforce.has_gamification() then
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
function Triforce.debug_xp()
  if not Triforce.has_gamification() then
    return
  end

  require('triforce.tracker').debug_xp()
end

---Debug: Test achievement notification
function Triforce.debug_achievement()
  if not Triforce.has_gamification() then
    return
  end

  require('triforce.tracker').debug_achievement()
end

---Debug: Fix level/XP mismatch
function Triforce.debug_fix_level()
  if not Triforce.has_gamification() then
    return
  end

  require('triforce.tracker').debug_fix_level()
end

---Export stats to JSON
---@param file string
---@param indent? string
function Triforce.export_stats_to_json(file, indent)
  util.validate({
    file = { file, { 'string' } },
    indent = { indent, { 'string', 'nil' }, true },
  })

  require('triforce.stats').export_to_json(require('triforce.tracker').get_stats(), file, indent or nil)
end

---Export stats to Markdown
---@param file string
function Triforce.export_stats_to_md(file)
  util.validate({ file = { file, { 'string' } } })

  require('triforce.stats').export_to_md(require('triforce.tracker').get_stats(), file)
end

---@param achievements Achievement[]|Achievement
function Triforce.new_achievements(achievements)
  util.validate({ achievements = { achievements, { 'table' } } })

  require('triforce.achievement').new_achievements(achievements, require('triforce.tracker').get_stats())
end

return Triforce
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
