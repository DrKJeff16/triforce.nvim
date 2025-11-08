---Profile UI using Volt
local volt = require("volt")
local voltui = require("volt.ui")
local voltstate = require("volt.state")

local stats_module = require("triforce.stats")
local tracker = require("triforce.tracker")

local M = {}

-- UI state
M.buf = nil
M.win = nil
M.dim_win = nil
M.dim_buf = nil
M.ns = vim.api.nvim_create_namespace("TriforceProfile")
M.current_tab = " Stats"

-- Dimensions
M.width = 80
M.height = 30
M.xpad = 2

---Get Zelda-themed title based on level
---@param level number
---@return string
local function get_level_title(level)
    local titles = {
        { max = 10, title = "Deku Scrub", icon = "🌱" },
        { max = 20, title = "Kokiri", icon = "🌳" },
        { max = 30, title = "Hylian Soldier", icon = "🗡️" },
        { max = 40, title = "Knight", icon = "⚔️" },
        { max = 50, title = "Royal Guard", icon = "🛡️" },
        { max = 60, title = "Master Swordsman", icon = "⚡" },
        { max = 70, title = "Hero of Time", icon = "🔺" },
        { max = 80, title = "Sage", icon = "✨" },
        { max = 90, title = "Triforce Bearer", icon = "🔱" },
        { max = 100, title = "Champion", icon = "👑" },
        { max = 120, title = "Divine Beast Pilot", icon = "🦅" },
        { max = 150, title = "Ancient Hero", icon = "🏛️" },
        { max = 180, title = "Legendary Warrior", icon = "⚜️" },
        { max = 200, title = "Goddess Chosen", icon = "🌟" },
        { max = 250, title = "Demise Slayer", icon = "💀" },
        { max = 300, title = "Eternal Legend", icon = "💫" },
    }

    for _, tier in ipairs(titles) do
        if level <= tier.max then
            return tier.icon .. " " .. tier.title
        end
    end

    return "💫 Eternal Legend" -- Max title for level > 300
end

---Format seconds to readable time
---@param secs number
---@return string
local function format_time(secs)
    local hours = math.floor(secs / 3600)
    local minutes = math.floor((secs % 3600) / 60)
    return string.format("%dh %dm", hours, minutes)
end

---Calculate streak (placeholder - would need daily tracking)
---@param stats Stats
---@return number
local function calculate_streak(stats)
    -- TODO: Implement actual streak tracking based on daily sessions
    return math.min(stats.sessions, 7) -- Placeholder
end

---Build Stats tab content
---@return table
local function build_stats_tab()
    local stats = tracker.get_stats()
    if not stats then
        return { { { "No stats available", "Comment" } } }
    end

    local streak = calculate_streak(stats)
    local level_title = get_level_title(stats.level)
    local xp_current = stats.xp
    local xp_next = stats_module.xp_for_next_level(stats.level)
    local xp_prev = stats.level > 1 and stats_module.xp_for_next_level(stats.level - 1) or 0
    local xp_progress = ((xp_current - xp_prev) / (xp_next - xp_prev)) * 100

    -- Compact streak info
    local streak_section = {
        {
            { " You're on a " },
            { tostring(streak) .. " day streak", "String" },
            { " and have typed " },
            { tostring(stats.chars_typed),       "Number" },
            { " characters!" },
        },
        {},
    }

    -- Three progress bars section
    local barlen = (M.width - M.xpad * 2) / 3 - 1

    -- Dynamic session goal (increments by 100)
    local session_goal = math.ceil(stats.sessions / 100) * 100
    if session_goal == stats.sessions then
        session_goal = session_goal + 100
    end
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
        { { " 󰓏", "TriforceYellow" }, { "  Level ~ " }, { tostring(stats.level), "TriforceYellow" } },
        {},
        voltui.progressbar {
            w = barlen,
            val = xp_progress > 100 and 100 or xp_progress,
            icon = { on = "┃", off = "┃" },
            hl = { on = "TriforceYellow", off = "Comment" },
        },
    }

    -- 2. Session milestone progress
    local session_stats = {
        { { "󰪺", "TriforceRed" }, { "  Sessions ~ " }, { tostring(stats.sessions) .. " / " .. tostring(session_goal), "TriforceRed" } },
        {},
        voltui.progressbar {
            w = barlen,
            val = session_progress > 100 and 100 or session_progress,
            icon = { on = "┃", off = "┃" },
            hl = { on = "TriforceRed", off = "Comment" },
        },
    }

    -- 3. Time goal progress
    local time_stats = {
        { { "󱑈", "TriforceBlue" }, { "  Time ~ " }, { tostring(math.floor(current_hours)) .. "h / " .. tostring(time_goal_hours) .. "h", "TriforceBlue" } },
        {},
        voltui.progressbar {
            w = barlen,
            val = time_progress > 100 and 100 or time_progress,
            icon = { on = "┃", off = "┃" },
            hl = { on = "TriforceBlue", off = "Comment" },
        },
    }

    local progress_section = voltui.grid_col {
        { lines = level_stats,   w = barlen, pad = 2 },
        { lines = session_stats, w = barlen, pad = 2 },
        { lines = time_stats,    w = barlen },
    }

    -- Stats table
    local stats_table = {
        {
            " Sessions",
            " Characters",
            " Lines",
            " Time",
            " XP",
        },
        {
            tostring(stats.sessions),
            tostring(stats.chars_typed),
            tostring(stats.lines_typed),
            format_time(stats.time_coding),
            tostring(stats.xp),
        },
    }

    local table_ui = voltui.table(stats_table, M.width - M.xpad * 2, "String")

    -- Footer
    local footer = {
        {},
        {},
        { { "  Tab: Switch Tabs    q: Close", "Comment" } },
        {},
    }

    return voltui.grid_row({
        streak_section,
        progress_section,
        { {} },
        table_ui,
        footer,
    })
end

---Get all achievements with their unlock status
---@param stats Stats
---@return table
local function get_all_achievements(stats)
    return {
        { id = "first_100", name = "First Steps", desc = "Type 100 characters", icon = "🌱", check = stats.chars_typed >= 100 },
        { id = "first_1000", name = "Getting Started", desc = "Type 1,000 characters", icon = "⚔️", check = stats.chars_typed >= 1000 },
        { id = "first_10000", name = "Dedicated Coder", desc = "Type 10,000 characters", icon = "🛡️", check = stats.chars_typed >= 10000 },
        { id = "first_100000", name = "Master Scribe", desc = "Type 100,000 characters", icon = "📜", check = stats.chars_typed >= 100000 },
        { id = "level_5", name = "Rising Star", desc = "Reach level 5", icon = "⭐", check = stats.level >= 5 },
        { id = "level_10", name = "Expert Coder", desc = "Reach level 10", icon = "💎", check = stats.level >= 10 },
        { id = "level_25", name = "Champion", desc = "Reach level 25", icon = "👑", check = stats.level >= 25 },
        { id = "level_50", name = "Legend", desc = "Reach level 50", icon = "🔱", check = stats.level >= 50 },
        { id = "sessions_10", name = "Regular Visitor", desc = "Complete 10 sessions", icon = "🔄", check = stats.sessions >= 10 },
        { id = "sessions_50", name = "Creature of Habit", desc = "Complete 50 sessions", icon = "📅", check = stats.sessions >= 50 },
        { id = "sessions_100", name = "Dedicated Hero", desc = "Complete 100 sessions", icon = "🏆", check = stats.sessions >= 100 },
        { id = "time_1h", name = "First Hour", desc = "Code for 1 hour total", icon = "⏰", check = stats.time_coding >= 3600 },
        { id = "time_10h", name = "Committed", desc = "Code for 10 hours total", icon = "⌛", check = stats.time_coding >= 36000 },
        { id = "time_100h", name = "Veteran", desc = "Code for 100 hours total", icon = "🕐", check = stats.time_coding >= 360000 },
    }
end

---Build Achievements tab content
---@return table
local function build_achievements_tab()
    local stats = tracker.get_stats()
    if not stats then
        return { { { "No stats available", "Comment" } } }
    end

    local achievements = get_all_achievements(stats)

    -- Sort: unlocked first
    table.sort(achievements, function(a, b)
        if a.check == b.check then
            return a.name < b.name
        end
        return a.check and not b.check
    end)

    -- Build table rows with virtual text for custom highlighting
    -- Each cell with custom hl must be an array of {text, hl} pairs
    local table_data = {
        { "Status", "Achievement", "Description" }, -- Header (plain strings)
    }

    for _, achievement in ipairs(achievements) do
        local unlocked = achievement.check
        local status_icon = unlocked and "✓" or "✗"
        local status_hl = unlocked and "String" or "Comment"
        local text_hl = unlocked and "Normal" or "Comment"

        -- Only show icon if unlocked
        local name_display = unlocked and (achievement.icon .. " " .. achievement.name) or achievement.name

        table.insert(table_data, {
            { { status_icon, status_hl } }, -- Array of virt text chunks
            { { name_display, text_hl } },
            { { achievement.desc, text_hl } },
        })
    end

    local achievement_table = voltui.table(table_data, M.width - M.xpad * 2, "String")

    local unlocked_count = 0
    for _, a in ipairs(achievements) do
            if a.check then unlocked_count = unlocked_count + 1 end
        end

    -- Compact achievement info
    local achievement_info = {
        {
            { " Hey, listen!", "Identifier" },
            { " You've unlocked " },
            { tostring(unlocked_count),                          "String" },
            { " out of " },
            { tostring(#achievements), "Number" },
            { " achievements!" },
        },
        {},
    }

    -- Footer
    local footer = {
        {},
        {},
        { { "  Tab: Switch Tabs    q: Close", "Comment" } },
        {},
    }

    return voltui.grid_row({
        achievement_info,
        achievement_table,
        footer,
    })
end

---Set up custom highlights
local function setup_highlights()
    local api = vim.api
    local get_hl = require("volt.utils").get_hl

    -- Get base colors
    local normal_bg = get_hl("Normal").bg

    -- Set custom highlights for Triforce (linked to standard highlights)
    if normal_bg then
        api.nvim_set_hl(M.ns, "TriforceNormal", { bg = normal_bg })
        api.nvim_set_hl(M.ns, "TriforceBorder", { link = "String" })
    end

    -- Create Triforce highlight groups - change these to customize colors
    api.nvim_set_hl(M.ns, "TriforceGreen", { link = "String" })
    api.nvim_set_hl(M.ns, "TriforceYellow", { link = "Question" })
    api.nvim_set_hl(M.ns, "TriforceRed", { link = "Keyword" })
    api.nvim_set_hl(M.ns, "TriforceBlue", { link = "Identifier" })
    api.nvim_set_hl(M.ns, "TriforcePurple", { link = "Number" })

    -- Link to standard highlights
    api.nvim_set_hl(M.ns, "FloatBorder", { link = "TriforceBorder" })
    api.nvim_set_hl(M.ns, "Normal", { link = "TriforceNormal" })
end

---Get layout for tab system
---@return table
local function get_layout()
    local components = {
        [" Stats"] = build_stats_tab,
        ["󰌌 Achievements"] = build_achievements_tab,
    }

    return {
        {
            lines = function()
                return { {} }
            end,
            name = "top-separator",
        },
        {
            lines = function()
                local tabs = { " Stats", "󰌌 Achievements" }
                return voltui.tabs(tabs, M.width - M.xpad * 2, { active = M.current_tab })
            end,
            name = "tabs",
        },
        {
            lines = function()
                return { {} }
            end,
            name = "separator",
        },
        {
            lines = function()
                return components[M.current_tab]()
            end,
            name = "content",
        },
    }
end

---Open profile window
function M.open()
    if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
        return
    end

    local api = vim.api

    -- Create buffer
    M.buf = api.nvim_create_buf(false, true)

    -- Create dimmed background
    M.dim_buf = api.nvim_create_buf(false, true)
    M.dim_win = api.nvim_open_win(M.dim_buf, false, {
        focusable = false,
        row = 0,
        col = 0,
        width = vim.o.columns,
        height = vim.o.lines - 2,
        relative = "editor",
        style = "minimal",
        border = "none",
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

    M.win = api.nvim_open_win(M.buf, true, {
        row = row,
        col = col,
        width = M.width,
        height = M.height,
        relative = "editor",
        style = "minimal",
        border = "none",
        zindex = 100,
    })

    -- Apply highlights
    setup_highlights()
    api.nvim_win_set_hl_ns(M.win, M.ns)

    -- Run Volt to render content
    volt.run(M.buf, { h = M.height, w = M.width - M.xpad * 2 })

    -- Set up keybindings
    local function close()
        if M.win and api.nvim_win_is_valid(M.win) then
            api.nvim_win_close(M.win, true)
        end
        if M.dim_win and api.nvim_win_is_valid(M.dim_win) then
            api.nvim_win_close(M.dim_win, true)
        end
        if M.buf and api.nvim_buf_is_valid(M.buf) then
            api.nvim_buf_delete(M.buf, { force = true })
        end
        if M.dim_buf and api.nvim_buf_is_valid(M.dim_buf) then
            api.nvim_buf_delete(M.dim_buf, { force = true })
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
    vim.keymap.set("n", "<Tab>", function()
        M.current_tab = M.current_tab == " Stats" and "󰌌 Achievements" or " Stats"

        -- Make buffer modifiable
        vim.bo[M.buf].modifiable = true

        -- Reinitialize layout with new content
        volt.gen_data({
            { buf = M.buf, layout = get_layout(), xpad = M.xpad, ns = M.ns },
        })

        -- Get new height and ensure buffer has enough lines
        local new_height = voltstate[M.buf].h
        local current_lines = api.nvim_buf_line_count(M.buf)

        -- Add more lines if needed
        if current_lines < new_height then
            local empty_lines = {}
            for _ = 1, (new_height - current_lines) do
                table.insert(empty_lines, "")
            end
            api.nvim_buf_set_lines(M.buf, current_lines, current_lines, false, empty_lines)
        elseif current_lines > new_height then
            -- Remove extra lines if buffer is too big
            api.nvim_buf_set_lines(M.buf, new_height, current_lines, false, {})
        end

        -- Update window height if needed
        if new_height ~= M.height then
            M.height = new_height
            local row = math.floor((vim.o.lines - M.height) / 2)
            local col = math.floor((vim.o.columns - M.width) / 2)
            api.nvim_win_set_config(M.win, {
                row = row,
                col = col,
                width = M.width,
                height = M.height,
                relative = "editor",
            })
        end

        -- Redraw content
        volt.redraw(M.buf, "all")
        vim.bo[M.buf].modifiable = false
    end, { buffer = M.buf })

    -- Set filetype
    vim.bo[M.buf].filetype = "triforce-profile"
end

return M
