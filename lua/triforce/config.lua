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
---List of user-defined achievements
---@field achievements? Achievement[]

local util = require('triforce.util')

---@class Triforce.Config
local Config = {
  config = {}, ---@type TriforceConfig
}

---@param silent? boolean
---@return boolean gamified
function Config.has_gamification(silent)
  util.validate({ silent = { silent, { 'boolean', 'nil' }, true } })

  silent = silent ~= nil and silent or false

  if Config.config.gamification_enabled ~= nil and Config.config.gamification_enabled then
    return true
  end

  if not silent then
    vim.notify('Gamification is not enabled in config', vim.log.levels.WARN)
  end
  return false
end

---@return TriforceConfig defaults
function Config.defaults()
  local defaults = { ---@type TriforceConfig
    enabled = true,
    gamification_enabled = true,
    debug = false,
    achievements = {},
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
end

---Setup the plugin with user configuration
---@param opts? TriforceConfig User configuration options
function Config.setup(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Config.config = vim.tbl_deep_extend('force', Config.defaults(), opts or {})

  if not Config.config.enabled then
    return
  end

  local stats_module = require('triforce.stats')

  -- Apply custom level progression to stats module
  if Config.config.level_progression then
    stats_module.level_config = Config.config.level_progression
  end

  -- Register custom languages if provided
  if Config.config.custom_languages then
    require('triforce.languages').register_custom_languages(Config.config.custom_languages)
  end

  -- Setup custom path if provided
  stats_module.db_path = Config.config.db_path
end

return Config
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
