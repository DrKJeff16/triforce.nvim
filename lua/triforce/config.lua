---@class LevelTier
---Starting level for this tier
---@field min_level integer
---Ending level for this tier (use math.huge for infinite)
---@field max_level integer
---XP required per level in this tier
---@field xp_per_level integer

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
---XP gained per character typed (default: `1`)
---@field char number
---XP gained per new line (default: `1`)
---@field line number
---XP gained per file save (default: `50`)
---@field save number

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
---@field TriforceHeat0? string
---@field TriforceHeat1? string
---@field TriforceHeat2? string
---@field TriforceHeat3? string
---@field TriforceHeat4? string

local util = require('triforce.util')

---Triforce setup configuration
---@class TriforceConfig
local defaults = {
  ---Enable the plugin
  enabled = true, ---@type boolean
  ---Enable gamification features (stats, XP, achievements)
  gamification_enabled = true, ---@type boolean
  ---Enable debugging messages
  debug = false, ---@type boolean
  ---List of user-defined achievements
  achievements = {}, ---@type Achievement[]
  ---Notification configuration
  notifications = { enabled = true, level_up = true, achievements = true }, ---@type TriforceConfig.Notifications
  ---Auto-save stats interval in seconds (default: `300`)
  auto_save_interval = 300, ---@type integer
  ---Keymap configuration
  keymap = { show_profile = '' }, ---@type TriforceConfig.Keymap
  ---Custom language definitions:
  ---
  ---```lua
  ----- Example
  ---{ rust = { icon = "", name = "Rust" } }
  ---```
  custom_languages = {}, ---@type table<string, TriforceLanguage>
  ---List of custom level titles
  levels = {}, ---@type LevelParams[]
  ---Custom level progression tiers
  level_progression = { ---@type LevelProgression
    tier_1 = { min_level = 1, max_level = 10, xp_per_level = 300 },
    tier_2 = { min_level = 11, max_level = 20, xp_per_level = 500 },
    tier_3 = { min_level = 21, max_level = math.huge, xp_per_level = 1000 },
  },
  ---List of ignored filetypes
  ignore_ft = {}, ---@type string[]
  ---Custom XP reward amounts for different actions
  xp_rewards = { char = 1, line = 1, save = 50 }, ---@type XPRewards
  ---Custom path for data file
  db_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'triforce_stats.json'), ---@type string
  ---Default highlight groups for the heats
  heat_highlights = { ---@type Triforce.Config.Heat
    TriforceHeat0 = '#f0f0f0',
    TriforceHeat1 = '#f0f0a0',
    TriforceHeat2 = '#f0a0a0',
    TriforceHeat3 = '#a0a0a0',
    TriforceHeat4 = '#707070',
  },
}

---@class Triforce.Config
---@field float? { bufnr: integer, win: integer }|nil
local Config = {}

Config.config = {} ---@type TriforceConfig

---@param silent boolean
---@return boolean gamified
---@overload fun(): gamified: boolean
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
  return defaults
end

---@param opts TriforceConfig
---@overload fun()
function Config.new_config(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Config.config = setmetatable(vim.tbl_deep_extend('keep', opts or {}, Config.defaults()), { __index = defaults })

  local keys = vim.tbl_keys(Config.defaults()) ---@type string[]
  for k, _ in pairs(Config.config) do
    if not vim.list_contains(keys, k) then
      Config.config[k] = nil
    end
  end
end

---Setup the plugin with user configuration
---@param opts TriforceConfig User configuration options
---@overload fun()
function Config.setup(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  Config.new_config(opts or {})

  if not Config.config.enabled then
    return
  end

  local stats_module = require('triforce.stats')
  local langs_module = require('triforce.languages')

  -- Apply custom level progression to stats module
  if Config.config.level_progression then
    stats_module.level_config = Config.config.level_progression
  end

  -- Register custom languages if provided
  if Config.config.custom_languages then
    langs_module.register_custom_languages(Config.config.custom_languages)
  end

  if Config.config.ignore_ft then
    langs_module.exclude_langs(Config.config.ignore_ft)
  end

  -- Setup custom path if provided
  stats_module.db_path = Config.config.db_path
end

function Config.close_window()
  if not Config.float then
    return
  end

  pcall(vim.api.nvim_win_close, Config.float.win, true)
  pcall(vim.api.nvim_buf_delete, Config.float.bufnr, { force = true })

  Config.float = nil
end

function Config.toggle_window()
  if Config.float then
    Config.close_window()
    return
  end

  Config.open_window()
end

function Config.open_window()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local data = vim.split(Config.get_config(), '\n', { plain = true, trimempty = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, data)

  local height = math.floor(vim.o.lines * 0.85)
  local width = math.floor(vim.o.columns * 0.85)
  local win = vim.api.nvim_open_win(bufnr, true, {
    focusable = true,
    border = 'single',
    col = math.floor((vim.o.columns - width) / 2) - 1,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    relative = 'editor',
    style = 'minimal',
    title = 'Triforce Config',
    title_pos = 'center',
    width = width,
    height = height,
    zindex = 50,
  })

  vim.wo[win].signcolumn = 'no'
  vim.wo[win].list = false
  vim.wo[win].number = false
  vim.wo[win].wrap = false
  vim.wo[win].colorcolumn = ''

  vim.bo[bufnr].filetype = ''
  vim.bo[bufnr].fileencoding = 'utf-8'
  vim.bo[bufnr].buftype = 'nowrite'
  vim.bo[bufnr].modifiable = false

  vim.keymap.set('n', 'q', Config.close_window, { buffer = bufnr })

  Config.float = { bufnr = bufnr, win = win }
end

---@return string config_str
function Config.get_config()
  local opts = {} ---@type TriforceConfig
  for k, v in pairs(Config.config) do
    opts[k] = v
  end
  return vim.inspect(opts)
end

return Config
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
