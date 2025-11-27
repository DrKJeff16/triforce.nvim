---@class Achievement
---@field id string
---@field name string
---@field check boolean
---@field desc? string
---@field icon? string

local util = require('triforce.util')

---@class Triforce.Achievements
local Achievement = {}

---Get all achievements with their unlock status
---@param stats Stats
---@return Achievement[] achievements
function Achievement.get_all_achievements(stats)
  util.validate({ stats = { stats, { 'table' } } })

  -- Count unique languages
  local unique_languages = 0
  for _ in pairs(stats.chars_by_language or {}) do
    unique_languages = unique_languages + 1
  end

  return { ---@type Achievement[]
    {
      id = 'first_100',
      name = 'First Steps',
      desc = 'Type 100 characters',
      icon = '🌱',
      check = stats.chars_typed >= 100,
    },
    {
      id = 'first_1000',
      name = 'Getting Started',
      desc = 'Type 1,000 characters',
      icon = '⚔️',
      check = stats.chars_typed >= 1000,
    },
    {
      id = 'first_10000',
      name = 'Dedicated Coder',
      desc = 'Type 10,000 characters',
      icon = '🛡️',
      check = stats.chars_typed >= 10000,
    },
    {
      id = 'first_100000',
      name = 'Master Scribe',
      desc = 'Type 100,000 characters',
      icon = '📜',
      check = stats.chars_typed >= 100000,
    },
    { id = 'level_5', name = 'Rising Star', desc = 'Reach level 5', icon = '⭐', check = stats.level >= 5 },
    { id = 'level_10', name = 'Expert Coder', desc = 'Reach level 10', icon = '💎', check = stats.level >= 10 },
    { id = 'level_25', name = 'Champion', desc = 'Reach level 25', icon = '👑', check = stats.level >= 25 },
    { id = 'level_50', name = 'Legend', desc = 'Reach level 50', icon = '🔱', check = stats.level >= 50 },
    {
      id = 'sessions_10',
      name = 'Regular Visitor',
      desc = 'Complete 10 sessions',
      icon = '🔄',
      check = stats.sessions >= 10,
    },
    {
      id = 'sessions_50',
      name = 'Creature of Habit',
      desc = 'Complete 50 sessions',
      icon = '📅',
      check = stats.sessions >= 50,
    },
    {
      id = 'sessions_100',
      name = 'Dedicated Hero',
      desc = 'Complete 100 sessions',
      icon = '🏆',
      check = stats.sessions >= 100,
    },
    {
      id = 'time_1h',
      name = 'First Hour',
      desc = 'Code for 1 hour total',
      icon = '⏰',
      check = stats.time_coding >= 3600,
    },
    {
      id = 'time_10h',
      name = 'Committed',
      desc = 'Code for 10 hours total',
      icon = '⌛',
      check = stats.time_coding >= 36000,
    },
    {
      id = 'time_100h',
      name = 'Veteran',
      desc = 'Code for 100 hours total',
      icon = '🕐',
      check = stats.time_coding >= 360000,
    },
    {
      id = 'polyglot_3',
      name = 'Polyglot Beginner',
      desc = 'Code in 3 different languages',
      icon = '🌍',
      check = unique_languages >= 3,
    },
    {
      id = 'polyglot_5',
      name = 'Polyglot',
      desc = 'Code in 5 different languages',
      icon = '🌎',
      check = unique_languages >= 5,
    },
    {
      id = 'polyglot_10',
      name = 'Master Polyglot',
      desc = 'Code in 10 different languages',
      icon = '🌏',
      check = unique_languages >= 10,
    },
    {
      id = 'polyglot_15',
      name = 'Language Virtuoso',
      desc = 'Code in 15 different languages',
      icon = '🗺️',
      check = unique_languages >= 15,
    },
  }
end

---Check and unlock achievements
---@param stats Stats
---@return Achievement[] newly_unlocked List of achievement objects
function Achievement.check_achievements(stats)
  util.validate({ stats = { stats, { 'table' } } })

  ---@type Achievement[]
  local newly_unlocked = {}
  local achievements = Achievement.get_all_achievements(stats)

  for _, achievement in ipairs(achievements) do
    if achievement.check and not stats.achievements[achievement.id] then
      stats.achievements[achievement.id] = true
      table.insert(newly_unlocked, {
        id = achievement.id,
        check = achievement.check,
        name = achievement.name,
        desc = achievement.desc,
        icon = achievement.icon,
      })
    end
  end

  return newly_unlocked
end

return Achievement
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
