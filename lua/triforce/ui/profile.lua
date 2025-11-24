---Profile UI using Volt
local volt = require('volt')
local voltui = require('volt.ui')
local voltstate = require('volt.state')

local stats_module = require('triforce.stats')
local achievement_module = require('triforce.achievement')
local tracker = require('triforce.tracker')
local languages = require('triforce.languages')
local random_stats = require('triforce.random_stats')
local util = require('triforce.util')

-- Helper functions (copied from typr)
local function getday_i(day, month, year)
  return tonumber(os.date('%w', os.time({ year = tostring(year), month = month, day = day }))) + 1
end

local function double_digits(day)
  return day >= 10 and day or '0' .. day
end

local M = {}

-- UI state
M.buf = nil
M.win = nil
M.dim_win = nil
M.dim_buf = nil
M.ns = vim.api.nvim_create_namespace('TriforceProfile')
M.achievements_page = 1
M.achievements_per_page = 5
M.max_language_entries = 13
M.current_tab = ' Stats'

-- Dimensions
M.width = 80
M.height = 30
M.xpad = 2

---Get Zelda-themed title based on level
---@param level integer
---@return string
local function get_level_title(level)
  util.validate({ level = { level, { 'number' } } })

  local titles = {
    { max = 10, title = 'Deku Scrub', icon = '🌱' },
    { max = 20, title = 'Kokiri', icon = '🌳' },
    { max = 30, title = 'Hylian Soldier', icon = '🗡️' },
    { max = 40, title = 'Knight', icon = '⚔️' },
    { max = 50, title = 'Royal Guard', icon = '🛡️' },
    { max = 60, title = 'Master Swordsman', icon = '⚡' },
    { max = 70, title = 'Hero of Time', icon = '🔺' },
    { max = 80, title = 'Sage', icon = '✨' },
    { max = 90, title = 'Triforce Bearer', icon = '🔱' },
    { max = 100, title = 'Champion', icon = '👑' },
    { max = 120, title = 'Divine Beast Pilot', icon = '🦅' },
    { max = 150, title = 'Ancient Hero', icon = '🏛️' },
    { max = 180, title = 'Legendary Warrior', icon = '⚜️' },
    { max = 200, title = 'Goddess Chosen', icon = '🌟' },
    { max = 250, title = 'Demise Slayer', icon = '💀' },
    { max = 300, title = 'Eternal Legend', icon = '💫' },
  }

  for _, tier in ipairs(titles) do
    if level <= tier.max then
      return ('%s %s'):format(tier.icon, tier.title)
    end
  end

  return '💫 Eternal Legend' -- Max title for level > 300
end

---Format seconds to readable time
---@param secs number
---@return string
local function format_time(secs)
  local hours = math.floor(secs / 3600)
  local minutes = math.floor((secs % 3600) / 60)
  return ('%dh %dm'):format(hours, minutes)
end

---Get activity level highlight based on lines typed
---@param lines integer
---@return string
local function get_activity_hl(lines)
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

---Build activity heatmap (copied from typr structure)
---@param stats Stats
---@return table
local function build_activity_heatmap(stats)
  if not stats or not stats.daily_activity then
    return { { { '  No activity data yet', 'Comment' } } }
  end

  local year = os.date('%Y')
  local current_month = tonumber(os.date('%m'))

  local months = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
  local days_in_months = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  local days = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }

  -- Leap year check
  local is_leap = (tonumber(year) % 4 == 0 and tonumber(year) % 100 ~= 0) or (tonumber(year) % 400 == 0)
  if is_leap then
    days_in_months[2] = 29
  end

  local months_i = current_month - 6
  if months_i < 1 then
    months_i = months_i + 12
  end
  local months_end = current_month
  local months_to_show = 7
  local squares_len = months_to_show * 4

  -- Build lines structure (typr style)
  local lines = {
    { { '   ', 'TriforceGreen' }, { '  ' } },
    {},
  }

  -- Month headers
  for i = months_i, months_end do
    local month_idx = i > 12 and (i - 12) or i
    table.insert(lines[1], { '  ' .. months[month_idx] .. '  ', 'TriforceRed' })
    table.insert(lines[1], { i == months_end and '' or '  ' })
  end

  -- Separator line
  local hrline = voltui.separator('─', squares_len * 2 + (months_to_show - 1 + 5), 'Comment')
  table.insert(lines[2], hrline[1])

  -- Day labels
  for day = 1, 7 do
    local line = { { days[day], 'Comment' }, { ' │ ', 'Comment' } }
    table.insert(lines, line)
  end

  -- Fill in activity data
  for i = months_i, months_end do
    local month_idx = i > 12 and (i - 12) or i
    local month_year = year

    -- Handle year boundary
    if months_i > months_end and i < months_end then
      if i < months_end then
        month_year = tostring(tonumber(year) + 1)
      elseif i > current_month then
        month_year = tostring(tonumber(year) - 1)
      end
    end

    local start_day = getday_i(1, month_idx, year)

    -- Empty cells before month starts (only for first month)
    if i == months_i and start_day ~= 1 then
      for n = 1, start_day - 1 do
        table.insert(lines[n + 2], { '  ' })
      end
    end

    -- Activity squares for each day
    for day_num = 1, days_in_months[month_idx] do
      local day_of_week = getday_i(day_num, month_idx, year)
      local date_key = ('%s-%s-%s'):format(month_year, double_digits(month_idx), double_digits(day_num))

      local activity = stats.daily_activity[date_key] or 0
      local hl = get_activity_hl(activity)

      table.insert(lines[day_of_week + 2], { '󱓻 ', hl })
    end
  end

  -- Add border (typr style)
  voltui.border(lines)

  -- Header with legend (typr style)
  local header = {
    { ' 󰃭 Activity' },
    { '_pad_' },
    { '    Less ' },
  }

  local hlgroups = { 'LineNr', 'TriforceHeat4', 'TriforceHeat3', 'TriforceHeat2', 'TriforceHeat1' }

  for _, hl in ipairs(hlgroups) do
    table.insert(header, { '󱓻 ', hl })
  end

  table.insert(header, { ' More' })
  table.insert(lines, 1, voltui.hpad(header, M.width - (2 * M.xpad) - 4))

  return lines
end

---Get streak with proper calculation
---@param stats Stats
---@return integer current
local function get_current_streak(stats)
  -- Recalculate to ensure accuracy
  local current, _ = stats_module.calculate_streaks(stats)
  return current
end

---Build Stats tab content
---@return table
local function build_stats_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available', 'Comment' } } }
  end

  local streak = get_current_streak(stats)
  local level_title = get_level_title(stats.level)
  local xp_current = stats.xp
  local xp_next = stats_module.xp_for_next_level(stats.level)
  local xp_prev = stats.level > 1 and stats_module.xp_for_next_level(stats.level - 1) or 0
  local xp_progress = ((xp_current - xp_prev) / (xp_next - xp_prev)) * 100

  -- Get random fact
  local random_fact = random_stats.get_random_fact(stats)

  -- Compact fact display with streak integration
  local fact_section = {
    {
      { ' ' .. random_fact .. '.', 'Normal' },
    },
    {},
  }

  -- Three progress bars section
  local barlen = (M.width - M.xpad * 2) / 3 - 1

  -- Dynamic session goal (increments by 100)
  local session_goal = math.ceil(stats.sessions / 100) * 100
  session_goal = session_goal == stats.sessions and (session_goal + 100) or session_goal
  local session_progress = (stats.sessions / session_goal) * 100

  -- Dynamic time goal (10h -> 25h -> 50h -> 100h -> 200h -> 300h...)
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

  -- 1. Level progress
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

  -- 2. Session milestone progress
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

  -- 3. Time goal progress
  local time_stats = {
    {
      { '󱑈', 'TriforceBlue' },
      { ' Time ~ ' },
      { tostring(math.floor(current_hours)) .. 'h / ' .. tostring(time_goal_hours) .. 'h', 'TriforceBlue' },
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
      format_time(stats.time_coding),
      streak > 0 and (tostring(streak) .. ' day' .. (streak > 1 and 's' or '')) or '0',
    },
  }

  local table_ui = voltui.table(stats_table, M.width - M.xpad * 2, 'String')

  -- Activity heatmap
  local heatmap_lines = build_activity_heatmap(stats)
  local heatmap_row = voltui.grid_col({
    { lines = {}, w = 1 },
    { lines = heatmap_lines, w = M.width - M.xpad * 2 },
  })

  -- Footer
  local footer = {
    {},
    {},
    { { '  Tab: Switch Tabs    q: Close', 'Comment' } },
    {},
  }

  return voltui.grid_row({
    fact_section,
    progress_section,
    { {} },
    table_ui,
    { {} },
    heatmap_row,
    -- heatmap_lines,
    footer,
  })
end

---Build Achievements tab content
---@return table
local function build_achievements_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available', 'Comment' } } }
  end

  local achievements = achievement_module.get_all_achievements(stats)

  -- Sort: unlocked first
  table.sort(achievements, function(a, b)
    return a.check == b.check and (a.name < b.name) or (a.check and not b.check)
  end)

  -- Calculate pagination
  local total_achievements = #achievements
  local total_pages = math.ceil(total_achievements / M.achievements_per_page)

  -- Ensure current page is within bounds
  if M.achievements_page > total_pages then
    M.achievements_page = total_pages
  end
  if M.achievements_page < 1 then
    M.achievements_page = 1
  end

  -- Get achievements for current page
  local start_idx = (M.achievements_page - 1) * M.achievements_per_page + 1
  local end_idx = math.min(start_idx + M.achievements_per_page - 1, total_achievements)

  -- Build table rows with virtual text for custom highlighting
  -- Each cell with custom hl must be an array of {text, hl} pairs
  local table_data = {
    { 'Status', 'Achievement', 'Description' }, -- Header (plain strings)
  }

  for i = start_idx, end_idx do
    local achievement = achievements[i]
    local unlocked = achievement.check
    local status_icon = unlocked and '✓' or '✗'
    local status_hl = unlocked and 'String' or 'Comment'
    local text_hl = unlocked and 'TriforceYellow' or 'Comment'
    local desc_hl = unlocked and 'Normal' or 'Comment'

    -- Only show icon if unlocked
    local name_display = unlocked and (achievement.icon .. ' ' .. achievement.name) or achievement.name

    table.insert(table_data, {
      { { status_icon, status_hl } }, -- Array of virt text chunks
      { { name_display, text_hl } },
      { { achievement.desc, desc_hl } },
    })
  end

  local achievement_table = voltui.table(table_data, M.width - M.xpad * 2, 'String')

  local unlocked_count = 0
  for _, a in ipairs(achievements) do
    if a.check then
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

  -- Footer with pagination info
  local footer = {
    {},
    {},
    {
      { '  Tab: Switch Tabs    ', 'Comment' },
      { 'H/L or ◀/▶: ', 'Comment' },
      { 'Page ' .. tostring(M.achievements_page) .. '/' .. tostring(total_pages), 'String' },
      { '    q: Close', 'Comment' },
    },
    {},
  }

  return voltui.grid_row({
    achievement_info,
    achievement_table,
    footer,
  })
end

---Build Languages tab content
---@return table
local function build_languages_tab()
  local stats = tracker.get_stats()
  if not stats then
    return { { { 'No stats available', 'Comment' } } }
  end

  -- Get language data and sort by character count
  local lang_data = {}
  for lang, count in pairs(stats.chars_by_language or {}) do
    table.insert(lang_data, { lang = lang, count = count })
  end

  table.sort(lang_data, function(a, b)
    return a.count > b.count
  end)

  -- Limit to max entries
  local display_count = math.min(#lang_data, M.max_language_entries)

  -- Prepare data for bar graph
  local graph_values = {}
  local max_chars = 0

  -- Get max for scaling
  for i = 1, display_count do
    if lang_data[i].count > max_chars then
      max_chars = lang_data[i].count
    end
  end

  -- Fill graph values (scale to 100)
  for i = 1, M.max_language_entries do
    if i <= display_count then
      local percentage = max_chars > 0 and math.floor((lang_data[i].count / max_chars) * 100) or 0
      table.insert(graph_values, percentage)
    else
      table.insert(graph_values, 0) -- Empty entries
    end
  end

  -- -- Create labels with icons
  -- local labels = {}
  -- for i = 1, M.max_language_entries do
  --   if i <= display_count then
  --     local icon = languages.get_icon(lang_data[i].lang)
  --     labels[i] = icon ~= '' and icon or lang_data[i].lang:sub(1, 1)
  --   else
  --     labels[i] = '·' -- Empty slot
  --   end
  -- end

  -- Calculate graph width (narrower for centering)
  local graph_width = math.min(M.max_language_entries * 4, M.width - M.xpad * 2)

  local graph_data = {
    val = graph_values,
    -- footer_label = { " Character count by language" },
    format_labels = function(x)
      if max_chars == 0 then
        return '0'
      end
      return tostring(math.floor((x / 100) * max_chars))
    end,
    baropts = {
      w = 3,
      gap = 2,
      hl = 'TriforceYellow',
    },
  }

  local graph_lines = voltui.graphs.bar(graph_data)

  -- Center the graph by calculating left padding
  local left_pad = 2

  -- Centered graph section
  local centered_graph = voltui.grid_col({
    { lines = { {} }, w = left_pad }, -- Left spacing
    { lines = graph_lines, w = graph_width },
  })

  -- Footer
  local footer = {
    {},
    {},
    { { '  Tab: Switch Tabs    q: Close', 'Comment' } },
    {},
  }

  -- Calculate dynamic spacing based on max label width
  local max_label_length = tostring(max_chars):len()
  local x_axis_spacing = 6 + max_label_length
  local spacing_str = (' '):rep(x_axis_spacing)
  local graph_x_axis_parts = { { spacing_str } }
  for i = 1, math.min(M.max_language_entries, #lang_data) do
    local icon = languages.get_icon(lang_data[i].lang)
    local hl = 'Comment'
    table.insert(graph_x_axis_parts, { icon ~= '' and icon or '', icon ~= '' and hl or 'Comment' })
    if i < math.min(M.max_language_entries, #lang_data) then
      table.insert(graph_x_axis_parts, { '    ' }) -- 4 spaces between icons
    end
  end

  local graph_x_axis = { graph_x_axis_parts }

  if display_count == 0 then
    graph_x_axis = {
      {},
      { { '  No language data yet. Start coding!', 'Comment' } },
    }
  end

  -- Language summary info
  local language_info = {}
  if display_count > 0 then
    local summary_parts = {
      { ' You code primarily in ' },
      { languages.get_display_name(lang_data[1].lang), 'TriforceRed' },
    }

    if display_count >= 2 then
      table.insert(summary_parts, { ', with ' })
      table.insert(summary_parts, { languages.get_display_name(lang_data[2].lang), 'TriforceBlue' })
    end

    if display_count >= 3 then
      table.insert(summary_parts, { ' and ' })
      table.insert(summary_parts, { languages.get_display_name(lang_data[3].lang), 'TriforcePurple' })
    end

    if display_count >= 2 then
      table.insert(summary_parts, { ' close behind', 'Normal' })
    end

    language_info = { summary_parts, {} }
  else
    language_info = {
      {},
    }
  end

  return voltui.grid_row({
    language_info,
    centered_graph,
    graph_x_axis,
    footer,
  })
end

---Set up custom highlights
local function setup_highlights()
  local get_hl = require('volt.utils').get_hl
  local mix = require('volt.color').mix
  local triforce = require('triforce')
  local function set_hl(name, opts)
    vim.api.nvim_set_hl(M.ns, name, opts)
  end

  -- Get base colors
  local normal_bg = get_hl('Normal').bg

  -- Set custom highlights for Triforce (linked to standard highlights)
  if normal_bg then
    set_hl('TriforceNormal', { bg = normal_bg })
    set_hl('TriforceBorder', { link = 'String' })
  else
    normal_bg = '#000000' -- Fallback for transparent backgrounds
  end

  -- Create Triforce highlight groups - change these to customize colors
  set_hl('TriforceGreen', { link = 'String' })
  set_hl('TriforceYellow', { link = 'Question' })
  set_hl('TriforceRed', { link = 'Keyword' })
  set_hl('TriforceBlue', { link = 'Identifier' })
  set_hl('TriforcePurple', { link = 'Number' })

  -- Heat levels: index maps to highlight group number and mix percentage
  local heat_levels = {
    { name = 0, mix_pct = 0 },
    { name = 1, mix_pct = 20 },
    { name = 2, mix_pct = 50 },
    { name = 3, mix_pct = 65 },
    { name = 4, mix_pct = 80 },
  }


  local heat_hls = (triforce.config and triforce.config.heat_highlights)
    or (triforce.defaults and triforce.defaults.heat_highlights)
    or {}
  for _, level in ipairs(heat_levels) do
    local hl = ('TriforceHeat%d'):format(level.name)
    local fg = heat_hls[hl]
    if fg then
      if type(fg) == 'string' and fg:sub(1, 1) ~= '#' then
        -- Allow linking to another hl group if user set a group name instead of a hex color
        set_hl(hl, { link = fg })
      else
        set_hl(hl, { fg = fg })
      end
    end
  end

  -- Link to standard highlights
  set_hl('FloatBorder', { link = 'TriforceBorder' })
  set_hl('Normal', { link = 'TriforceNormal' })
end

---Get layout for tab system
---@return table
local function get_layout()
  local components = {
    [' Stats'] = build_stats_tab,
    ['󰌌 Achievements'] = build_achievements_tab,
    ['0 Languages'] = build_languages_tab,
  }

  return {
    {
      lines = function()
        return { {} }
      end,
      name = 'top-separator',
    },
    {
      lines = function()
        local tabs = { ' Stats', '󰌌 Achievements', '0 Languages' }
        return voltui.tabs(tabs, M.width - M.xpad * 2, { active = M.current_tab })
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
        return components[M.current_tab]()
      end,
      name = 'content',
    },
  }
end

---Open profile window
function M.open()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    return
  end

  -- Create buffer
  M.buf = vim.api.nvim_create_buf(false, true)

  -- Create dimmed background
  M.dim_buf = vim.api.nvim_create_buf(false, true)
  M.dim_win = vim.api.nvim_open_win(M.dim_buf, false, {
    focusable = false,
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - 2,
    relative = 'editor',
    style = 'minimal',
    border = 'none',
  })
  vim.wo[M.dim_win].winblend = 20

  -- Initialize Volt
  volt.gen_data({
    { buf = M.buf, layout = get_layout(), xpad = M.xpad, ns = M.ns },
  })

  M.height = voltstate[M.buf].h

  -- Window config
  local row = math.floor((vim.o.lines - M.height) / 2)
  local col = math.floor((vim.o.columns - M.width) / 2)

  M.win = vim.api.nvim_open_win(M.buf, true, {
    row = row,
    col = col,
    width = M.width,
    height = M.height,
    relative = 'editor',
    style = 'minimal',
    border = 'none',
    zindex = 100,
  })

  -- Apply highlights
  setup_highlights()
  vim.api.nvim_win_set_hl_ns(M.win, M.ns)

  -- Run Volt to render content
  volt.run(M.buf, { h = M.height, w = M.width - M.xpad * 2 })

  -- Set up keybindings
  local function close()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
      vim.api.nvim_win_close(M.win, true)
    end
    if M.dim_win and vim.api.nvim_win_is_valid(M.dim_win) then
      vim.api.nvim_win_close(M.dim_win, true)
    end
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
      vim.api.nvim_buf_delete(M.buf, { force = true })
    end
    if M.dim_buf and vim.api.nvim_buf_is_valid(M.dim_buf) then
      vim.api.nvim_buf_delete(M.dim_buf, { force = true })
    end
    M.buf = nil
    M.win = nil
    M.dim_win = nil
    M.dim_buf = nil
  end

  -- Use Volt's built-in mapping system
  volt.mappings({
    bufs = { M.buf, M.dim_buf },
    winclosed_event = true,
    after_close = close,
  })

  -- Tab switching
  vim.keymap.set('n', '<Tab>', function()
    -- Cycle through tabs
    if M.current_tab == ' Stats' then
      M.current_tab = '󰌌 Achievements'
    elseif M.current_tab == '󰌌 Achievements' then
      M.current_tab = '0 Languages'
    else
      M.current_tab = ' Stats'
    end

    -- Make buffer modifiable
    vim.bo[M.buf].modifiable = true

    -- Reinitialize layout with new content
    volt.gen_data({
      { buf = M.buf, layout = get_layout(), xpad = M.xpad, ns = M.ns },
    })

    -- Get new height and ensure buffer has enough lines
    local new_height = voltstate[M.buf].h
    local current_lines = vim.api.nvim_buf_line_count(M.buf)

    -- Add more lines if needed
    if current_lines < new_height then
      local empty_lines = {}
      for _ = 1, (new_height - current_lines) do
        table.insert(empty_lines, '')
      end
      vim.api.nvim_buf_set_lines(M.buf, current_lines, current_lines, false, empty_lines)
    elseif current_lines > new_height then
      -- Remove extra lines if buffer is too big
      vim.api.nvim_buf_set_lines(M.buf, new_height, current_lines, false, {})
    end

    -- Update window height if needed
    if new_height ~= M.height then
      M.height = new_height
      row = math.floor((vim.o.lines - M.height) / 2)
      col = math.floor((vim.o.columns - M.width) / 2)
      vim.api.nvim_win_set_config(M.win, {
        row = row,
        col = col,
        width = M.width,
        height = M.height,
        relative = 'editor',
      })
    end

    -- Redraw content
    volt.redraw(M.buf, 'all')
    vim.bo[M.buf].modifiable = false
  end, { buffer = M.buf })

  -- Helper function to redraw achievements tab
  local function redraw_achievements()
    if M.current_tab ~= '󰌌 Achievements' then
      return
    end

    vim.bo[M.buf].modifiable = true
    volt.gen_data({
      { buf = M.buf, layout = get_layout(), xpad = M.xpad, ns = M.ns },
    })

    local new_height = voltstate[M.buf].h
    local current_lines = vim.api.nvim_buf_line_count(M.buf)

    if current_lines < new_height then
      local empty_lines = {}
      for _ = 1, (new_height - current_lines) do
        table.insert(empty_lines, '')
      end
      vim.api.nvim_buf_set_lines(M.buf, current_lines, current_lines, false, empty_lines)
    elseif current_lines > new_height then
      vim.api.nvim_buf_set_lines(M.buf, new_height, current_lines, false, {})
    end

    volt.redraw(M.buf, 'all')
    vim.bo[M.buf].modifiable = false
  end

  -- Pagination keymaps for achievements
  local pagination_keys = { 'h', 'H', '<Left>', 'l', 'L', '<Right>' }
  for _, key in ipairs(pagination_keys) do
    vim.keymap.set('n', key, function()
      if M.current_tab ~= '󰌌 Achievements' then
        return
      end

      if vim.list_contains({ 'h', 'H', '<Left>' }, key) then
        if M.achievements_page > 1 then
          M.achievements_page = M.achievements_page - 1
          redraw_achievements()
        end
      elseif vim.list_contains({ 'l', 'L', '<Right>' }, key) then
        local stats = tracker.get_stats()
        if stats then
          local achievements = achievement_module.get_all_achievements(stats)
          local total_pages = math.ceil(#achievements / M.achievements_per_page)
          if M.achievements_page < total_pages then
            M.achievements_page = M.achievements_page + 1
            redraw_achievements()
          end
        end
      end
    end, { buffer = M.buf })
  end

  -- Set filetype
  vim.bo[M.buf].filetype = 'triforce-profile'
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
