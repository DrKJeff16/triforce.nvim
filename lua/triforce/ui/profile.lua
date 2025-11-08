---Profile UI using nui.nvim
local Layout = require('nui.layout')
local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

local stats_module = require('triforce.stats')
local tracker = require('triforce.tracker')

local M = {}

---Format number with commas
---@param num number
---@return string
local function format_number(num)
  local formatted = tostring(num)
  local k
  while true do
    formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
    if k == 0 then
      break
    end
  end
  return formatted
end

---Format time duration
---@param seconds number
---@return string
local function format_time(seconds)
  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60

  if hours > 0 then
    return string.format('%dh %dm', hours, mins)
  elseif mins > 0 then
    return string.format('%dm %ds', mins, secs)
  else
    return string.format('%ds', secs)
  end
end

---Create progress bar
---@param current number
---@param max number
---@param width number
---@return string
local function progress_bar(current, max, width)
  local filled = math.floor((current / max) * width)
  local empty = width - filled

  return '[' .. string.rep('█', filled) .. string.rep('░', empty) .. ']'
end

---Get all achievements definition
---@return table[]
local function get_all_achievements()
  return {
    { id = 'first_100', name = '🎯 First Steps', desc = '100 characters' },
    { id = 'first_1000', name = '⭐ Getting Started', desc = '1,000 characters' },
    { id = 'first_10000', name = '💪 Dedicated Coder', desc = '10,000 characters' },
    { id = 'level_5', name = '🌟 Rising Star', desc = 'Reach level 5' },
    { id = 'level_10', name = '👑 Expert Coder', desc = 'Reach level 10' },
    { id = 'sessions_10', name = '📅 Regular Visitor', desc = '10 sessions' },
    { id = 'sessions_50', name = '🔥 Creature of Habit', desc = '50 sessions' },
  }
end

---Generate left column content (profile and stats)
---@param stats Stats
---@return string[]
local function generate_left_column(stats)
  local lines = {}

  -- Header
  table.insert(lines, '╔════════════════════════════════════╗')
  table.insert(lines, '║      ⚔️  TRIFORCE PROFILE  ⚔️      ║')
  table.insert(lines, '╚════════════════════════════════════╝')
  table.insert(lines, '')

  -- Level and XP
  local current_level_xp = stats.level > 1 and stats_module.xp_for_next_level(stats.level - 1) or 0
  local next_level_xp = stats_module.xp_for_next_level(stats.level)
  local xp_in_level = stats.xp - current_level_xp
  local xp_needed = next_level_xp - current_level_xp

  table.insert(lines, string.format(' Level: %d', stats.level))
  table.insert(lines, string.format(' XP: %d / %d', xp_in_level, xp_needed))
  table.insert(lines, ' ' .. progress_bar(xp_in_level, xp_needed, 32))
  table.insert(lines, '')

  -- Stats section
  table.insert(lines, ' ═══ Statistics ═══')
  table.insert(lines, string.format(' Total XP: %s', format_number(stats.xp)))
  table.insert(lines, string.format(' Characters: %s', format_number(stats.chars_typed)))
  table.insert(lines, string.format(' Lines: %s', format_number(stats.lines_typed)))
  table.insert(lines, string.format(' Sessions: %d', stats.sessions))
  table.insert(lines, string.format(' Time: %s', format_time(stats.time_coding)))
  table.insert(lines, '')
  table.insert(lines, ' Press q or <Esc> to close')

  return lines
end

---Generate right column content (achievements)
---@param stats Stats
---@return string[]
local function generate_right_column(stats)
  local lines = {}

  -- Header
  table.insert(lines, '╔════════════════════════════════════╗')
  table.insert(lines, '║        🏆 ACHIEVEMENTS 🏆          ║')
  table.insert(lines, '╚════════════════════════════════════╝')
  table.insert(lines, '')

  local all_achievements = get_all_achievements()
  local unlocked_count = 0

  for _, achievement in ipairs(all_achievements) do
    if stats.achievements[achievement.id] then
      table.insert(lines, string.format(' ✓ %s', achievement.name))
      table.insert(lines, string.format('   %s', achievement.desc))
      unlocked_count = unlocked_count + 1
    else
      table.insert(lines, string.format(' ✗ %s', achievement.name))
      table.insert(lines, string.format('   %s', achievement.desc))
    end
    table.insert(lines, '')
  end

  table.insert(lines, ' ─────────────────────────────────')
  table.insert(lines, string.format(' Unlocked: %d / %d', unlocked_count, #all_achievements))

  return lines
end

---Show the profile popup
function M.show()
  local stats = tracker.get_stats()

  if not stats then
    vim.notify('Stats not loaded yet', vim.log.levels.WARN)
    return
  end

  local left_content = generate_left_column(stats)
  local right_content = generate_right_column(stats)

  -- Create two popup components
  local left_popup = Popup({
    border = {
      style = 'rounded',
    },
    win_options = {
      winblend = 0,
      winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
    },
  })

  local right_popup = Popup({
    border = {
      style = 'rounded',
    },
    win_options = {
      winblend = 0,
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    },
  })

  -- Create layout with two columns
  local layout = Layout(
    {
      position = '50%',
      size = {
        width = '80%',
        height = '80%',
      },
    },
    Layout.Box({
      Layout.Box(left_popup, { size = '50%' }),
      Layout.Box(right_popup, { size = '50%' }),
    }, { dir = 'row' })
  )

  -- Mount the layout
  layout:mount()

  -- Set content for left popup
  vim.api.nvim_buf_set_lines(left_popup.bufnr, 0, -1, false, left_content)

  -- Add highlights to left popup
  local ns_id = vim.api.nvim_create_namespace('triforce_profile')

  -- Highlight XP and level lines (lines 4-6, 0-indexed: 3-5)
  vim.api.nvim_buf_add_highlight(left_popup.bufnr, ns_id, 'String', 3, 0, -1) -- Level line
  vim.api.nvim_buf_add_highlight(left_popup.bufnr, ns_id, 'String', 4, 0, -1) -- XP line
  vim.api.nvim_buf_add_highlight(left_popup.bufnr, ns_id, 'String', 5, 0, -1) -- Progress bar

  -- Highlight Total XP line (line 8, 0-indexed: 7)
  vim.api.nvim_buf_add_highlight(left_popup.bufnr, ns_id, 'String', 7, 0, -1)

  vim.bo[left_popup.bufnr].modifiable = false
  vim.bo[left_popup.bufnr].readonly = true

  -- Set content for right popup
  vim.api.nvim_buf_set_lines(right_popup.bufnr, 0, -1, false, right_content)

  -- Add highlights to right popup - mute locked achievements
  local line_idx = 4 -- Start after header (0-indexed)
  local all_achievements = get_all_achievements()

  for _, achievement in ipairs(all_achievements) do
    if stats.achievements[achievement.id] then
      -- Unlocked - highlight with success color
      vim.api.nvim_buf_add_highlight(right_popup.bufnr, ns_id, 'String', line_idx, 0, -1)
      vim.api.nvim_buf_add_highlight(right_popup.bufnr, ns_id, 'Comment', line_idx + 1, 0, -1)
    else
      -- Locked - mute with comment color
      vim.api.nvim_buf_add_highlight(right_popup.bufnr, ns_id, 'Comment', line_idx, 0, -1)
      vim.api.nvim_buf_add_highlight(right_popup.bufnr, ns_id, 'Comment', line_idx + 1, 0, -1)
    end
    line_idx = line_idx + 3 -- Each achievement takes 3 lines (name, desc, empty)
  end

  vim.bo[right_popup.bufnr].modifiable = false
  vim.bo[right_popup.bufnr].readonly = true

  -- Close on q or Esc from either popup
  local function close_layout()
    layout:unmount()
  end

  left_popup:map('n', { 'q', '<Esc>' }, close_layout, { noremap = true })
  right_popup:map('n', { 'q', '<Esc>' }, close_layout, { noremap = true })

  -- Auto-close on leaving buffer
  left_popup:on(event.BufLeave, function()
    vim.defer_fn(function()
      if layout._.mounted then
        layout:unmount()
      end
    end, 0)
  end)
end

return M
