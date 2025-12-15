local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO
local util = require('triforce.util')

---@class Triforce
local Triforce = {
  get_stats = require('triforce.tracker').get_stats,
}

---@param opts? TriforceConfig
function Triforce.setup(opts)
  util.validate({ opts = { opts, { 'table', 'nil' }, true } })

  local config_module = require('triforce.config')
  config_module.setup(opts or {})

  local config = config_module.config
  -- Set up keymap if provided
  if config.keymap and config.keymap.show_profile and config.keymap.show_profile ~= '' then
    vim.keymap.set('n', config.keymap.show_profile, Triforce.show_profile, {
      desc = 'Show Triforce Profile',
      silent = true,
      noremap = true,
    })
  end

  if not config_module.has_gamification(true) then
    return
  end

  require('triforce.tracker').setup()

  if config.achievements then
    Triforce.new_achievements(config.achievements)
  end
end

---Show profile UI
function Triforce.show_profile()
  if not require('triforce.config').has_gamification() then
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
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.tracker').reset_stats()
end

---Debug language tracking
function Triforce.debug_languages()
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.tracker').debug_languages()
end

---Force save stats
function Triforce.save_stats()
  if not require('triforce.config').has_gamification() then
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
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.tracker').debug_xp()
end

---Debug: Test achievement notification
function Triforce.debug_achievement()
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.tracker').debug_achievement()
end

---Debug: Fix level/XP mismatch
function Triforce.debug_fix_level()
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.tracker').debug_fix_level()
end

function Triforce.export_stats()
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.stats').export_stats(require('triforce.tracker').get_stats())
end

---Export stats to JSON
---@param file string
---@param indent? string
function Triforce.export_stats_to_json(file, indent)
  util.validate({
    file = { file, { 'string' } },
    indent = { indent, { 'string', 'nil' }, true },
  })
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.stats').export_to_json(require('triforce.tracker').get_stats(), file, indent or nil)
end

---Export stats to Markdown
---@param file string
function Triforce.export_stats_to_md(file)
  util.validate({ file = { file, { 'string' } } })
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.stats').export_to_md(require('triforce.tracker').get_stats(), file)
end

---@param achievements Achievement[]|Achievement
function Triforce.new_achievements(achievements)
  util.validate({ achievements = { achievements, { 'table' } } })
  if not require('triforce.config').has_gamification() then
    return
  end

  require('triforce.achievement').new_achievements(achievements, require('triforce.tracker').get_stats())
end

return Triforce
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
