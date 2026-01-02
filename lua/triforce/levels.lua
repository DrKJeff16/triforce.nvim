---@class LevelTitle
---@field title string
---@field icon string

---@alias LevelTitles table<integer, LevelTitle>

local util = require('triforce.util')

---@class Triforce.Levels
local Levels = {}

---@return LevelTitles titles
function Levels.get_default_titles()
  local titles = { ---@type LevelTitle[]
    [10] = { title = 'Deku Scrub', icon = '🌱' },
    [20] = { title = 'Kokiri', icon = '🌳' },
    [30] = { title = 'Hylian Soldier', icon = '🗡️' },
    [40] = { title = 'Knight', icon = '⚔️' },
    [50] = { title = 'Royal Guard', icon = '🛡️' },
    [60] = { title = 'Master Swordsman', icon = '⚡' },
    [70] = { title = 'Hero of Time', icon = '🔺' },
    [80] = { title = 'Sage', icon = '✨' },
    [90] = { title = 'Triforce Bearer', icon = '🔱' },
    [100] = { title = 'Champion', icon = '👑' },
    [120] = { title = 'Divine Beast Pilot', icon = '🦅' },
    [150] = { title = 'Ancient Hero', icon = '🏛️' },
    [180] = { title = 'Legendary Warrior', icon = '⚜️' },
    [200] = { title = 'Goddess Chosen', icon = '🌟' },
    [250] = { title = 'Demise Slayer', icon = '💀' },
    [300] = { title = 'Eternal Legend', icon = '💫' },
  }

  return titles
end

---Get Zelda-themed title based on level
---@param level integer
---@return string title
function Levels.get_level_title(level)
  util.validate({ level = { level, { 'number' } } })

  local titles = Levels.get_default_titles()

  for max, tier in pairs(titles) do
    if level <= max then
      return ('%s %s'):format(tier.icon, tier.title)
    end
  end

  return '💫 Eternal Legend' -- Max title for level > 300
end

return Levels
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
