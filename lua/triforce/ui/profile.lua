---@class TriforceLangData
---@field lang string
---@field count integer

---@alias Months
---|1
---|2
---|3
---|4
---|5
---|6
---|7
---|8
---|9
---|10
---|11
---|12

---Profile UI using Volt
local volt = require('volt')
local voltui = require('volt.ui')
local voltstate = require('volt.state') ---@type table<integer, { h: integer }>

local stats_module = require('triforce.stats')
local achievement_module = require('triforce.achievement')
local tracker = require('triforce.tracker')
local languages = require('triforce.languages')
local random_stats = require('triforce.random_stats')
local levels_module = require('triforce.levels')
local util = require('triforce.util')

---@class Triforce.Ui.Profile
local Profile = {
  -- UI state
  buf = nil, ---@type integer|nil
  win = nil, ---@type integer|nil
  dim_win = nil, ---@type integer|nil
  dim_buf = nil, ---@type integer|nil
  ns = vim.api.nvim_create_namespace('TriforceProfile'), ---@type integer
  achievements_page = 1, ---@type integer
  levels_page = 1, ---@type integer
  achievements_per_page = 5, ---@type integer
  levels_per_page = 5, ---@type integer
  max_language_entries = 13, ---@type integer
  current_tab = 1, ---@type integer
  all_tabs = { '1   Stats', '2  󰌌 Achievements', '3   Languages', '4  󱡁 Levels' },

  -- Dimensions
  width = 80, ---@type integer
  height = 30, ---@type integer
  xpad = 2, ---@type integer
}

---Close up profile window
function Profile.close()
  pcall(vim.api.nvim_buf_delete, Profile.buf, { force = true })
  pcall(vim.api.nvim_buf_delete, Profile.dim_buf, { force = true })
  pcall(vim.api.nvim_win_close, Profile.win, true)
  pcall(vim.api.nvim_win_close, Profile.dim_win, true)
  Profile.buf = nil
  Profile.win = nil
  Profile.dim_win = nil
  Profile.dim_buf = nil
end

---Toggle profile window
function Profile.toggle()
  if Profile.buf == nil and Profile.win == nil and Profile.dim_win == nil and Profile.dim_buf == nil then
    Profile.open()
    return
  end

  Profile.close()
end

function Profile.pagination_fun(key)
  return function()
    if not vim.tbl_contains({ 2, 4 }, Profile.current_tab) then
      return
    end

    if Profile.current_tab == 2 then
      if vim.list_contains({ 'h', 'H', '<Left>' }, key) then
        if Profile.achievements_page > 1 then
          Profile.achievements_page = Profile.achievements_page - 1
          Profile.redraw()
        end
      elseif vim.list_contains({ 'l', 'L', '<Right>' }, key) then
        local stats = tracker.get_stats()
        if stats then
          local achievements = achievement_module.get_all_achievements(stats)
          if Profile.achievements_page < math.ceil(#achievements / Profile.achievements_per_page) then
            Profile.achievements_page = Profile.achievements_page + 1
            Profile.redraw()
          end
        end
      end

      return
    end

    if vim.list_contains({ 'h', 'H', '<Left>' }, key) then
      if Profile.levels_page > 1 then
        Profile.levels_page = Profile.levels_page - 1
        Profile.redraw()
      end
    elseif vim.list_contains({ 'l', 'L', '<Right>' }, key) then
      local stats = tracker.get_stats()
      if stats then
        local levels = levels_module.get_all_levels(stats)
        if Profile.levels_page < math.ceil(#levels / Profile.levels_per_page) then
          Profile.levels_page = Profile.levels_page + 1
          Profile.redraw()
        end
      end
    end
  end
end

---Helper function to redraw either the achievements or levels tabs
function Profile.redraw()
  if not Profile.buf then
    return
  end
  if not vim.list_contains({ 2, 4 }, Profile.current_tab) then
    return
  end

  vim.bo[Profile.buf].modifiable = true
  volt.gen_data({
    { buf = Profile.buf, layout = Profile.get_layout(), xpad = Profile.xpad, ns = Profile.ns },
  })

  local new_height = voltstate[Profile.buf].h
  local current_lines = vim.api.nvim_buf_line_count(Profile.buf)

  if current_lines < new_height then
    local empty_lines = {}
    for _ = 1, (new_height - current_lines) do
      table.insert(empty_lines, '')
    end
    vim.api.nvim_buf_set_lines(Profile.buf, current_lines, current_lines, false, empty_lines)
  elseif current_lines > new_height then
    vim.api.nvim_buf_set_lines(Profile.buf, new_height, current_lines, false, {})
  end

  volt.redraw(Profile.buf, 'all')
  vim.bo[Profile.buf].modifiable = false
end

---Get activity level highlight based on lines typed
---@param lines integer
---@return 'LineNr'|'TriforceHeat0'|'TriforceHeat1'|'TriforceHeat2'|'TriforceHeat3' hl
function Profile.get_activity_hl(lines)
  if lines == 0 then
    return 'LineNr'
  end
  if lines <= 50 then
    return 'TriforceHeat3' -- Lightest
  end
  if lines <= 150 then
    return 'TriforceHeat2' -- Light-medium
  end
  if lines <= 300 then
    return 'TriforceHeat1' -- Medium-bright
  end

  return 'TriforceHeat0' -- Brightest
end

---@param year integer
---@return boolean leap
local function is_leap_year(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

---@param month Months
---@param year integer
local function days_in_month(month, year)
  local days_in_months = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  if month ~= 2 then
    return days_in_months[month]
  end
  return is_leap_year(year) and 29 or 28
end

---Build activity heatmap (copied from typr structure)
---@param stats Stats
---@return string[][][]|string[][] lines
function Profile.build_activity_heatmap(stats)
  if not stats or not stats.daily_activity then
    return { { { '  No activity data yet', 'Comment' } } }
  end

  local year = os.date('%Y')
  local current_month = tonumber(os.date('%m'))

  local months = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
  local days = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }

  local months_to_show = 7
  local squares_len = months_to_show * 4

  -- Build an explicit wrapped sequence of the last 7 months ending at current month
  local current_year_num = tonumber(year)
  local month_seq = {}
  for offset = months_to_show - 1, 0, -1 do
    local m = current_month - offset
    local y = current_year_num
    while m < 1 do
      m = m + 12
      y = y - 1
    end
    table.insert(month_seq, { month = m, year = y })
  end

  -- Build lines structure (typr style)
  local lines = { ---@type string[][][]|string[][]
    { { '   ', 'TriforceGreen' }, { '  ' } },
    {},
  }

  -- Month headers
  for idx, my in ipairs(month_seq) do
    local month_idx = my.month
    table.insert(lines[1], { '  ' .. months[month_idx] .. '  ', 'TriforceRed' })
    table.insert(lines[1], { idx == #month_seq and '' or '  ' })
  end

  local hrline = voltui.separator('─', squares_len * 2 + (months_to_show - 1 + 5), 'Comment')
  table.insert(lines[2], hrline[1])

  -- Day labels
  for day = 1, 7 do
    local line = { { days[day], 'Comment' }, { ' │ ', 'Comment' } }
    table.insert(lines, line)
  end

  -- Fill in activity data
  for idx, my in ipairs(month_seq) do
    local month_idx = my.month
    local month_year = tostring(my.year)

    local start_day = util.getday_i(1, month_idx, my.year)

    -- Empty cells before month starts (only for first month)
    if idx == 1 and start_day ~= 1 then
      for n = 1, start_day - 1 do
        table.insert(lines[n + 2], { '  ' })
      end
    end

    -- Activity squares for each day
    for day_num = 1, days_in_month(month_idx, my.year) do
      local day_of_week = util.getday_i(day_num, month_idx, my.year)
      local date_key = ('%s-%s-%s'):format(month_year, util.double_digits(month_idx), util.double_digits(day_num))

      local activity = stats.daily_activity[date_key] or 0
      local hl = Profile.get_activity_hl(activity)

      table.insert(lines[day_of_week + 2], { '󱓻 ', hl })
    end
  end

  voltui.border(lines)

  -- Header with legend (typr style)
  local header = { ---@type string[][][]|string[][]
    { ' 󰃭 Activity' },
    { '_pad_' },
    { 'Less ' },
  }

  for _, hl in ipairs({ 'LineNr', 'TriforceHeat4', 'TriforceHeat3', 'TriforceHeat2', 'TriforceHeat1', 'TriforceHeat0' }) do
    table.insert(header, { '󱓻 ', hl })
  end

  table.insert(header, { ' More' })
  table.insert(lines, 1, voltui.hpad(header, Profile.width - (2 * Profile.xpad) - 4))

  return lines
end

---Get streak with proper calculation
---@param stats Stats
---@return integer current
function Profile.get_current_streak(stats)
  -- Recalculate to ensure accuracy
  local current = stats_module.calculate_streaks(stats)
  return current
end

---Build Stats tab content
---@return string[][][]|string[][]
function Profile.build_stats_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available', 'Comment' } } }
  end

  local streak = Profile.get_current_streak(stats)
  local xp_current = stats.xp
  local xp_next = stats_module.xp_for_next_level(stats.level)
  local xp_prev = stats.level > 1 and stats_module.xp_for_next_level(stats.level - 1) or 0
  local xp_progress = ((xp_current - xp_prev) / (xp_next - xp_prev)) * 100
  local fact_section = {
    { { ' ' .. random_stats.get_random_fact(stats) .. '.', 'TriforceRed' } },
    {},
  }

  local barlen = math.floor((Profile.width - Profile.xpad * 2) / 3) - 1
  local session_goal = math.ceil(stats.sessions / 100) * 100
  session_goal = session_goal == stats.sessions and (session_goal + 100) or session_goal
  local session_progress = (stats.sessions / session_goal) * 100

  local current_hours = stats.time_coding / 3600
  local time_goal_hours
  if current_hours < 10 then
    time_goal_hours = 10
  elseif current_hours < 25 then
    time_goal_hours = 25
  elseif current_hours < 50 then
    time_goal_hours = 50
  elseif current_hours < 100 then
    time_goal_hours = 100
  else
    time_goal_hours = math.ceil(current_hours / 100) * 100
    if time_goal_hours == current_hours then
      time_goal_hours = time_goal_hours + 100
    end
  end
  local time_goal = time_goal_hours * 3600
  local time_progress = (stats.time_coding / time_goal) * 100
  local level_stats = {
    { { ' 󰓏', 'TriforceYellow' }, { ' Level ~ ' }, { tostring(stats.level), 'TriforceYellow' } },
    {},
    voltui.progressbar({
      w = barlen,
      val = xp_progress > 100 and 100 or xp_progress,
      icon = { on = '┃', off = '┃' },
      hl = { on = 'TriforceYellow', off = 'Comment' },
    }),
  }
  local session_stats = {
    {
      { '󰪺', 'TriforceRed' },
      { ' Sessions ~ ' },
      { tostring(stats.sessions) .. ' / ' .. tostring(session_goal), 'TriforceRed' },
    },
    {},
    voltui.progressbar({
      w = barlen,
      val = session_progress > 100 and 100 or session_progress,
      icon = { on = '┃', off = '┃' },
      hl = { on = 'TriforceRed', off = 'Comment' },
    }),
  }
  local time_stats = {
    {
      { '󱑈', 'TriforceBlue' },
      { ' Time ~ ' },
      { ('%sh / %sh'):format(math.floor(current_hours), time_goal_hours), 'TriforceBlue' },
    },
    {},
    voltui.progressbar({
      w = barlen,
      val = time_progress > 100 and 100 or time_progress,
      icon = { on = '┃', off = '┃' },
      hl = { on = 'TriforceBlue', off = 'Comment' },
    }),
  }
  local progress_section = voltui.grid_col({
    { lines = level_stats, w = barlen, pad = 2 },
    { lines = session_stats, w = barlen, pad = 2 },
    { lines = time_stats, w = barlen },
  })

  -- Stats table
  local stats_table = {
    {
      ' Sessions',
      ' Characters',
      ' Lines',
      ' Time',
      ' Streak',
    },
    {
      tostring(stats.sessions),
      tostring(stats.chars_typed),
      tostring(stats.lines_typed),
      util.format_time(stats.time_coding),
      streak > 0 and (tostring(streak) .. ' day' .. (streak > 1 and 's' or '')) or '0',
    },
  }
  local table_ui = voltui.table(stats_table, Profile.width - Profile.xpad * 2, 'String')
  local heatmap_lines = Profile.build_activity_heatmap(stats)
  local heatmap_row = voltui.grid_col({
    { lines = {}, w = 1 },
    { lines = heatmap_lines, w = Profile.width - Profile.xpad * 2 },
  })
  local footer = {
    {},
    {},
    {
      { '  ', 'Comment' },
      { '<Tab>', 'TriforceGreen' },
      { ': Switch Tabs | ', 'Comment' },
      { '<S-Tab>', 'TriforceGreen' },
      { ': Switch Tabs Backwards | ', 'Comment' },
      { 'q', 'TriforceGreen' },
      { ': Close', 'Comment' },
    },
    {},
  }

  return voltui.grid_row({
    fact_section,
    progress_section,
    { {} },
    table_ui,
    { {} },
    heatmap_row,
    footer,
  })
end

---Build Achievements tab content
---@return string[][][]|string[][]
function Profile.build_achievements_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available!', 'PmenuSel' } } }
  end

  local achievements = achievement_module.get_all_achievements(stats)

  -- Sort: unlocked first
  table.sort(achievements, function(a, b)
    return a.check(stats) == b.check(stats) and (a.name < b.name) or (a.check(stats) and not b.check(stats))
  end)

  local total_achievements = #achievements
  local total_pages = math.ceil(total_achievements / Profile.achievements_per_page)
  if Profile.achievements_page > total_pages then
    Profile.achievements_page = total_pages
  end
  if Profile.achievements_page < 1 then
    Profile.achievements_page = 1
  end

  local start_idx = (Profile.achievements_page - 1) * Profile.achievements_per_page + 1
  local end_idx = math.min(start_idx + Profile.achievements_per_page - 1, total_achievements)
  local table_data = {
    { 'Status', 'Achievement', 'Description' }, -- Header (plain strings)
  }

  for i = start_idx, end_idx do
    local achievement = achievements[i]
    local status_icon = achievement.check(stats) and '✓' or '✗'
    local status_hl = achievement.check(stats) and 'String' or 'Comment'
    local text_hl = achievement.check(stats) and 'TriforceYellow' or 'Comment'
    local desc_hl = achievement.check(stats) and 'Normal' or 'Comment'

    -- Only show icon if unlocked
    local name_display = achievement.check(stats) and (achievement.icon .. ' ' .. achievement.name) or achievement.name

    table.insert(table_data, {
      { { status_icon, status_hl } }, -- Array of virt text chunks
      { { name_display, text_hl } },
      { { achievement.desc, desc_hl } },
    })
  end

  local achievement_table = voltui.table(table_data, Profile.width - Profile.xpad * 2, 'String')

  local unlocked_count = 0
  for _, a in ipairs(achievements) do
    if a.check(stats) then
      unlocked_count = unlocked_count + 1
    end
  end

  -- Compact achievement info
  local achievement_info = {
    {
      { ' Hey, listen!', 'Identifier' },
      { " You've unlocked " },
      { tostring(unlocked_count), 'String' },
      { ' out of ' },
      { tostring(#achievements), 'Number' },
      { ' achievements!' },
    },
    {},
  }
  local footer = {
    {},
    {},
    {
      { '  ', 'Comment' },
      { '<Tab>', 'TriforceGreen' },
      { ': Switch Tabs | ', 'Comment' },
      { '<S-Tab>', 'TriforceGreen' },
      { ': Switch Tabs Backwards | ', 'Comment' },
      { 'q', 'TriforceGreen' },
      { ': Close', 'Comment' },
    },
    {
      { '  ', 'Comment' },
      { 'H', 'TriforceGreen' },
      { '/', 'Comment' },
      { 'L', 'TriforceGreen' },
      { 'or ', 'Comment' },
      { '◀', 'TriforceGreen' },
      { '/', 'Comment' },
      { '▶', 'TriforceGreen' },
      { ': ', 'Comment' },
      { ('Page %s/%s'):format(Profile.achievements_page, total_pages), 'Number' },
    },
  }

  return voltui.grid_row({
    achievement_info,
    achievement_table,
    footer,
  })
end

---Build levels tab content
---@return string[][][]|string[][]
function Profile.build_levels_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available!', 'PmenuSel' } } }
  end

  local levels = levels_module.get_all_levels(stats)

  -- Sort: unlocked first
  table.sort(levels, function(a, b)
    return a.unlocked == b.unlocked and (a.level < b.level) or (a.unlocked and not b.unlocked)
  end)

  local total_levels = #levels
  local total_pages = math.ceil(total_levels / Profile.levels_per_page)

  -- Ensure current page is within bounds
  if Profile.levels_page > total_pages then
    Profile.levels_page = total_pages
  end
  if Profile.levels_page < 1 then
    Profile.levels_page = 1
  end

  -- Get levels for current page
  local start_idx = (Profile.levels_page - 1) * Profile.levels_per_page + 1
  local end_idx = math.min(start_idx + Profile.levels_per_page - 1, total_levels)

  -- Build table rows with virtual text for custom highlighting
  -- Each cell with custom hl must be an array of {text, hl} pairs
  local table_data = { ---@type string[][][]|string[][]
    { 'Unlocked', 'Level', 'Title' }, -- Header (plain strings)
  }

  for i = start_idx, end_idx do
    local level = levels[i]
    local unlocked_icon = level.unlocked and '✓' or '✗'
    local unlocked_hl = level.unlocked and 'String' or 'Comment'
    local text_hl = level.unlocked and 'TriforceYellow' or 'Comment'
    local desc_hl = level.unlocked and 'Normal' or 'Comment'
    local name_display = ('%s'):format(level.level)
    table.insert(table_data, {
      { { unlocked_icon, unlocked_hl } }, -- Array of virt text chunks
      { { name_display, text_hl } },
      { { level.title, desc_hl } },
    })
  end

  local levels_table = voltui.table(table_data, Profile.width - Profile.xpad * 2, 'String')
  local unlocked_count = 0
  for _, a in ipairs(levels) do
    if a.unlocked then
      unlocked_count = unlocked_count + 1
    end
  end

  local levels_info = { ---@type string[][][]|string[][]
    {
      { 'Current level: ' },
      { ('%d'):format(stats.level), 'Number' },
    },
    {},
  }
  local footer = { ---@type string[][][]|string[][]
    {},
    {
      { '  ' },
      { '<Tab>', 'TriforceGreen' },
      { ': Switch Tabs | ', 'Comment' },
      { '<S-Tab>', 'TriforceGreen' },
      { ': Switch Tabs Backwards | ', 'Comment' },
      { 'q', 'TriforceGreen' },
      { ': Close |', 'Comment' },
    },
    {
      { '  ' },
      { 'H', 'TriforceGreen' },
      { '/', 'Comment' },
      { 'L', 'TriforceGreen' },
      { ' or ', 'Comment' },
      { '◀', 'TriforceGreen' },
      { '/', 'Comment' },
      { '▶', 'TriforceGreen' },
      { ': ', 'Comment' },
      { ('Page %s/%s'):format(Profile.levels_page, total_pages), 'Number' },
    },
  }

  return voltui.grid_row({
    levels_info,
    levels_table,
    footer,
  })
end

---Build Languages tab content
---@return string[][][]|string[][]
function Profile.build_languages_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available', 'Comment' } } }
  end

  local lang_data = {} ---@type TriforceLangData[]
  for lang, count in pairs(stats.chars_by_language or {}) do
    if not languages.is_excluded(lang) then
      table.insert(lang_data, { lang = lang, count = count })
    end
  end

  table.sort(lang_data, function(a, b)
    return a.count > b.count
  end)

  local display_count = math.min(#lang_data, Profile.max_language_entries)
  local graph_values = {}
  local max_chars = 0
  for i = 1, display_count do
    if lang_data[i].count > max_chars then
      max_chars = lang_data[i].count
    end
  end

  for i = 1, Profile.max_language_entries do
    table.insert(
      graph_values,
      (i <= display_count and (max_chars > 0 and math.floor((lang_data[i].count / max_chars) * 100) or 0) or 0)
    )
  end

  -- -- Create labels with icons
  -- local labels = {}
  -- for i = 1, Profile.max_language_entries do
  --   if i <= display_count then
  --     local icon = languages.get_icon(lang_data[i].lang)
  --     labels[i] = icon ~= '' and icon or lang_data[i].lang:sub(1, 1)
  --   else
  --     labels[i] = '·' -- Empty slot
  --   end
  -- end

  -- Calculate graph width (narrower for centering)
  local graph_width = math.min(Profile.max_language_entries * 4, Profile.width - Profile.xpad * 2)
  local graph_data = {
    val = graph_values,
    footer_label = { ' Character count by language' },
    format_labels = function(x)
      return max_chars == 0 and '0' or tostring(math.floor((x * max_chars / 100)))
    end,
    baropts = {
      w = 3,
      gap = 2,
      hl = 'TriforceYellow',
    },
  }

  local graph_lines = voltui.graphs.bar(graph_data)
  local left_pad = 2
  local centered_graph = voltui.grid_col({
    { lines = { {} }, w = left_pad },
    { lines = graph_lines, w = graph_width },
  })
  local footer = {
    {},
    {},
    {
      { '  ', 'Comment' },
      { '<Tab>', 'TriforceGreen' },
      { ': Switch Tabs Forwards | ', 'Comment' },
      { '<S-Tab>', 'TriforceGreen' },
      { ': Switch Tabs Backwards | ', 'Comment' },
      { 'q', 'TriforceGreen' },
      { ': Close', 'Comment' },
    },
    {},
  }

  -- Calculate dynamic spacing based on max label width
  local max_label_length = tostring(max_chars):len()
  local x_axis_spacing = 6 + max_label_length
  local spacing_str = (' '):rep(x_axis_spacing)
  local graph_x_axis_parts = { { spacing_str } }
  for i = 1, math.min(Profile.max_language_entries, #lang_data) do
    local icon = languages.get_icon(lang_data[i].lang)
    if icon then
      local hl = icon ~= '' and 'TriforceHeat0' or 'Comment'
      table.insert(graph_x_axis_parts, { icon, hl })
      if i < math.min(Profile.max_language_entries, #lang_data) then
        table.insert(graph_x_axis_parts, { (' '):rep(4) }) -- 4 spaces between icons
      end
    end
  end

  local graph_x_axis = { graph_x_axis_parts }
  if display_count == 0 then
    graph_x_axis = {
      {},
      { { ('%sNo language data yet. Start coding!'):format((' '):rep(2)), 'Comment' } },
    }
  end

  local language_info, summary_parts = { {} }, {}
  local pre_msgs = { ' You code primarily in ', ', with ', ' and ' }
  local hls = { 'TriforceRed', 'TriforceBlue', 'TriforcePurple' }
  local i, added = 1, 1
  if display_count > 0 then
    while display_count >= i and added <= 3 do
      local display_name = languages.get_display_name(lang_data[i].lang)
      if display_name then
        if added <= #pre_msgs then
          table.insert(summary_parts, { pre_msgs[added] })
        end
        table.insert(summary_parts, { display_name, hls[added] })
        added = added + 1
      end

      i = i + 1
    end

    if display_count >= 2 then
      table.insert(summary_parts, { ' close behind', 'Normal' })
    end

    language_info = { summary_parts, {} }
  end

  return voltui.grid_row({ language_info, centered_graph, graph_x_axis, footer })
end

---Set up custom highlights
function Profile.setup_highlights()
  local config = require('triforce.config')
  local normal_bg = require('volt.utils').get_hl('Normal').bg
  if normal_bg then
    vim.api.nvim_set_hl(Profile.ns, 'TriforceNormal', { bg = normal_bg })
    vim.api.nvim_set_hl(Profile.ns, 'TriforceBorder', { link = 'String' })
  else
    normal_bg = '#000000' -- Fallback for transparent backgrounds
  end

  local hls = { ---@type table<string, vim.api.keyset.highlight>
    TriforceRed = { link = 'Keyword' },
    TriforceGreen = { link = 'String' },
    TriforceYellow = { link = 'Question' },
    TriforceBlue = { link = 'Identifier' },
    TriforcePurple = { link = 'Number' },
  }
  for group, hl in pairs(hls) do
    vim.api.nvim_set_hl(Profile.ns, group, hl)
  end

  -- Heat levels: index maps to highlight group number and mix percentage
  local heat_levels = {
    { name = 0, mix_pct = 0 },
    { name = 1, mix_pct = 20 },
    { name = 2, mix_pct = 50 },
    { name = 3, mix_pct = 65 },
    { name = 4, mix_pct = 80 },
  }

  local heat_hls = config.config.heat_highlights or config.defaults().heat_highlights
  for _, level in ipairs(heat_levels) do
    local hl = ('TriforceHeat%d'):format(level.name)
    local fg = heat_hls[hl]

    if fg then
      local key = (type(fg) == 'string' and fg:sub(1, 1) ~= '#') and 'link' or 'fg'
      vim.api.nvim_set_hl(Profile.ns, hl, { [key] = fg })
    end
  end
  vim.api.nvim_set_hl(Profile.ns, 'FloatBorder', { link = 'TriforceBorder' })
  vim.api.nvim_set_hl(Profile.ns, 'Normal', { link = 'TriforceNormal' })
end

---Get layout for tab system
---@return VoltData.Layout[]
function Profile.get_layout()
  local components = { ---@type table<string, fun(): (string[][][]|string[][])>
    Profile.build_stats_tab,
    Profile.build_achievements_tab,
    Profile.build_languages_tab,
    Profile.build_levels_tab,
  }

  return { ---@type VoltData.Layout[]
    {
      lines = function()
        return { {} }
      end,
      name = 'top-separator',
    },
    {
      lines = function()
        return voltui.tabs(
          Profile.all_tabs,
          Profile.width - Profile.xpad * 2,
          { active = Profile.all_tabs[Profile.current_tab], hlon = 'pmenusel', hloff = 'pmenu' }
        )
      end,
      name = 'tabs',
    },
    {
      lines = function()
        return { {} }
      end,
      name = 'separator',
    },
    {
      lines = function()
        return components[Profile.current_tab]()
      end,
      name = 'content',
    },
  }
end

---@param back? boolean
---@param num? integer
function Profile.cycle_tab(back, num)
  util.validate({
    back = { back, { 'boolean', 'nil' }, true },
    num = { num, { 'number', 'nil' }, true },
  })
  back = back ~= nil and back or false
  num = num or 0

  local old_tab = Profile.current_tab
  local positions = vim.tbl_keys(Profile.all_tabs) ---@type integer[]
  local pos = 1
  if not vim.list_contains(positions, num) then
    for i, _ in ipairs(Profile.all_tabs) do
      if i == Profile.current_tab then
        pos = i
        break
      end
    end

    pos = util.cycle_range(pos, 1, #Profile.all_tabs, back)
    Profile.current_tab = pos
  else
    Profile.current_tab = num
  end

  vim.bo[Profile.buf].modifiable = true
  volt.gen_data({
    { buf = Profile.buf, layout = Profile.get_layout(), xpad = Profile.xpad, ns = Profile.ns },
  })

  local new_height = voltstate[Profile.buf].h
  local current_lines = vim.api.nvim_buf_line_count(Profile.buf)

  -- Add more lines if needed
  if current_lines < new_height then
    local empty_lines = {}
    for _ = 1, (new_height - current_lines) do
      table.insert(empty_lines, '')
    end
    vim.api.nvim_buf_set_lines(Profile.buf, current_lines, current_lines, false, empty_lines)
  elseif current_lines > new_height then
    -- Remove extra lines if buffer is too big
    vim.api.nvim_buf_set_lines(Profile.buf, new_height, current_lines, false, {})
  end

  if new_height ~= Profile.height then
    Profile.height = new_height
    vim.api.nvim_win_set_config(Profile.win, {
      row = math.floor((vim.o.lines - Profile.height) / 2),
      col = math.floor((vim.o.columns - Profile.width) / 2),
      width = Profile.width,
      height = Profile.height,
      relative = 'editor',
      border = 'none',
    })
  end

  volt.redraw(Profile.buf, 'all')
  vim.bo[Profile.buf].modifiable = false
  vim.api.nvim_win_set_cursor(Profile.win, { 1, 0 })

  for _, key in ipairs({ 'h', 'H', '<Left>', 'l', 'L', '<Right>' }) do
    if vim.list_contains({ 2, 4 }, old_tab) and not vim.list_contains({ 2, 4 }, Profile.current_tab) then
      vim.keymap.del('n', key, { buffer = Profile.buf })
    elseif vim.list_contains({ 2, 4 }, Profile.current_tab) then
      vim.keymap.set('n', key, Profile.pagination_fun(key), { buffer = Profile.buf })
    end
  end
end

---Open profile window
function Profile.open()
  if Profile.buf and vim.api.nvim_buf_is_valid(Profile.buf) then
    return
  end

  -- Create buffer
  Profile.buf = vim.api.nvim_create_buf(false, true)

  -- Create dimmed background
  Profile.dim_buf = vim.api.nvim_create_buf(false, true)
  Profile.dim_win = vim.api.nvim_open_win(Profile.dim_buf, false, {
    focusable = false,
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - 2,
    relative = 'editor',
    style = 'minimal',
    border = 'none',
  })
  vim.wo[Profile.dim_win].winblend = 20

  -- Initialize Volt
  volt.gen_data({
    { buf = Profile.buf, layout = Profile.get_layout(), xpad = Profile.xpad, ns = Profile.ns },
  })

  Profile.height = voltstate[Profile.buf].h
  Profile.win = vim.api.nvim_open_win(Profile.buf, true, {
    row = math.floor((vim.o.lines - Profile.height) / 2),
    col = math.floor((vim.o.columns - Profile.width) / 2),
    width = Profile.width,
    height = Profile.height,
    relative = 'editor',
    style = 'minimal',
    border = 'none',
    zindex = 100,
  })

  -- Apply highlights
  Profile.setup_highlights()
  vim.api.nvim_win_set_hl_ns(Profile.win, Profile.ns)

  -- Run Volt to render content
  volt.run(Profile.buf, { h = Profile.height, w = Profile.width - Profile.xpad * 2 })

  -- Use Volt's built-in mapping system
  volt.mappings({
    bufs = { Profile.buf, Profile.dim_buf },
    winclosed_event = true,
    after_close = Profile.close,
  })

  vim.api.nvim_win_set_cursor(Profile.win, { 1, 0 })

  vim.keymap.set('n', '<Tab>', Profile.cycle_tab, { buffer = Profile.buf, noremap = true, silent = true })
  vim.keymap.set('n', '<S-Tab>', function()
    Profile.cycle_tab(true)
  end, { buffer = Profile.buf, noremap = true, silent = true })

  for i = 1, #Profile.all_tabs, 1 do
    vim.keymap.set('n', ('%s'):format(i), function()
      Profile.cycle_tab(nil, i)
    end, { buffer = Profile.buf, noremap = true, silent = true })
  end

  if vim.list_contains({ 2, 4 }, Profile.current_tab) then
    for _, key in ipairs({ 'h', 'H', '<Left>', 'l', 'L', '<Right>' }) do
      vim.keymap.set('n', key, Profile.pagination_fun(key), { buffer = Profile.buf })
    end
  end

  vim.bo[Profile.buf].filetype = 'triforce-profile'
end

return Profile
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
