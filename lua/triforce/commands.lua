---@module 'triforce._meta'

---@class Triforce.Commands
local M = {}

-- Create user commands with subcommands
function M.setup()
  vim.api.nvim_create_user_command('Triforce', function(opts)
    local sub_2 = opts.fargs[2] or ''
    local sub_3 = opts.fargs[3] or ''
    local sub_4 = opts.fargs[4] or ''
    local sub_5 = opts.fargs[5] or ''
    local n_args = #opts.fargs
    local T = require('triforce')
    local options = vim.tbl_keys(T.ui.profile.get_tabs_map()) --[[@as string[]\]]
    local debug_ops = {
      achievement = T.debug_achievement,
      fix = T.debug_fix_level,
      languages = T.debug_languages,
      xp = T.debug_xp,
    }
    if n_args == 1 and opts.fargs[1] == 'config' then
      T.config.open_window()
    elseif n_args == 2 and opts.args[1] == 'profile' then
      T.show_profile()
    elseif n_args == 3 and opts.fargs[1] == 'profile' and not vim.list_contains(options, sub_2) then
      local msg = 'Usage:\n  :Triforce profile'
      for _, option in ipairs(options) do
        msg = ('%s\n  :Triforce profile %s'):format(msg, option)
      end
      vim.notify(msg, vim.log.levels.INFO)
    elseif opts.fargs[1] == 'profile' then
      T.show_profile(sub_2)
    elseif opts.fargs[1] == 'reset' then
      T.reset()
    elseif n_args == 1 and opts.fargs[1] == 'items' then
      vim.notify(
        [[Usage:
  :Triforce items buy <item>
  :Triforce items currency
  :Triforce items list]],
        vim.log.levels.INFO
      )
    elseif n_args == 2 and opts.fargs[1] == 'items' and sub_2 == 'currency' then
      vim.notify(tostring(T.tracker.get_stats().currency), vim.log.levels.INFO)
    elseif n_args == 2 and opts.fargs[1] == 'items' and sub_2 == 'list' then
      local msg = ''
      for name, item in pairs(T.items.get_items()) do
        msg = (msg .. (msg == '' and '' or '\n') .. '%s    %d'):format(name, item:price(T.tracker.get_stats()))
      end
      vim.notify(msg, vim.log.levels.INFO)
    elseif n_args == 2 and opts.fargs[1] == 'items' and sub_2 == 'buy' then
      if not vim.list_contains(T.items.get_items_by_name(), sub_3) then
        vim.notify('Usage:\n  :Triforce items buy <item>', vim.log.levels.INFO)
      else
        T.items.buy_item(sub_3)
      end
    elseif n_args == 1 and opts.fargs[1] == 'stats' then
      vim.notify(vim.inspect(T.get_stats(), { indent = '  ' }), vim.log.levels.INFO)
    elseif n_args == 2 and opts.fargs[1] == 'stats' and sub_2 == 'save' then
      T.save_stats()
    elseif opts.fargs[1] == 'stats' and not vim.list_contains({ 'export', 'save' }, sub_2) then
      vim.notify(
        [[Usage:
  :Triforce stats
  :Triforce stats export
  :Triforce stats export json [</path/to/file>] [INDENT_LEVEL]
  :Triforce stats export lua [</path/to/file>]
  :Triforce stats export markdown [</path/to/file>]
  :Triforce stats save]],
        vim.log.levels.INFO
      )
    elseif
      opts.fargs[1] == 'stats'
      and sub_2 == 'export'
      and (not vim.list_contains({ 'json', 'markdown', 'lua', '' }, sub_3) or n_args > 5)
    then
      vim.notify(
        [[Usage:
  :Triforce stats export
  :Triforce stats export json [<path/to/file>] [INDENT_LEVEL]
  :Triforce stats export lua [</path/to/file>]
  :Triforce stats export markdown [</path/to/file>]\]],
        vim.log.levels.INFO
      )
    elseif (n_args >= 2 and n_args <= 3) and opts.fargs[1] == 'stats' and sub_2 == 'export' then
      T.export_stats(sub_3 ~= '' and sub_3 or nil)
    elseif n_args == 4 and opts.fargs[1] == 'stats' and sub_2 == 'export' and sub_3 == 'markdown' then
      T.export_stats_to_md(sub_4)
    elseif n_args == 4 and opts.fargs[1] == 'stats' and sub_2 == 'export' and sub_3 == 'lua' then
      T.export_stats_to_lua(sub_4)
    elseif (n_args >= 4 and n_args <= 5) and opts.fargs[1] == 'stats' and sub_2 == 'export' and sub_3 == 'json' then
      T.export_stats_to_json(
        sub_4,
        (function()
          local indent_str = nil ---@type string|nil|?
          if sub_5 ~= '' then
            local _, indent = pcall(tonumber, sub_5, 10) ---@type boolean, integer|nil|?
            if indent and T.util.is_int(indent, indent > 0) then
              indent_str = (' '):rep(indent)
            end
          end
          return indent_str
        end)()
      )
    elseif n_args == 1 and opts.fargs[1] == 'debug' then -- If only first subcommand exists then execute all debug operations but 'fix'
      for k, cb in pairs(debug_ops) do
        if k ~= 'fix' then
          pcall(cb)
        end
      end
    elseif n_args == 2 and opts.fargs[1] == 'debug' and debug_ops[sub_2] then
      pcall(debug_ops[sub_2])
    else
      vim.notify(
        [[Usage:
  :Triforce config
  :Triforce debug achievement
  :Triforce debug fix
  :Triforce debug languages
  :Triforce debug xp
  :Triforce items buy <item>
  :Triforce items currency
  :Triforce items list
  :Triforce profile
  :Triforce reset
  :Triforce stats
  :Triforce stats export
  :Triforce stats export json [<path/to/file>] [INDENT_LEVEL]
  :Triforce stats export lua [</path/to/file>]
  :Triforce stats export markdown [</path/to/file>]
  :Triforce stats save]],
        vim.log.levels.INFO
      )
    end
  end, {
    nargs = '*',
    desc = 'Triforce gamification commands',
    complete = function(_, line)
      local Util = require('triforce.util')
      local res = {} ---@type string[]
      local third_pos = {
        debug = { 'xp', 'achievement', 'languages', 'fix' },
        items = { 'buy', 'currency', 'list' },
        profile = vim.tbl_keys(require('triforce.ui.profile').get_tabs_map()),
        stats = { 'export', 'save' },
      }
      local args = vim.split(line, '%s+', { trimempty = false })
      if args[1]:sub(-1) == '!' then
        res = {}
      elseif #args == 2 then
        for _, comp in ipairs({ 'profile', 'stats', 'reset', 'debug', 'config', 'items' }) do
          if args[2] == '' or (args[2] ~= '' and vim.startswith(comp, args[2])) then
            table.insert(res, comp)
          end
        end
      elseif #args == 3 and third_pos[args[2]] then
        for _, comp in ipairs(third_pos[args[2]]) do
          if args[3] == '' or (args[3] ~= '' and vim.startswith(comp, args[3])) then
            table.insert(res, comp)
          end
        end
      elseif #args == 4 and args[2] == 'stats' and args[3] == 'export' then
        for _, comp in ipairs({ 'json', 'markdown', 'lua' }) do
          if args[4] == '' or (args[4] ~= '' and vim.startswith(comp, args[4])) then
            table.insert(res, comp)
          end
        end
      elseif #args >= 4 and args[2] == 'items' and args[3] == 'buy' then
        local items = require('triforce.items').get_items_by_name()
        local used, valid = {}, true ---@type string[], boolean
        for i = 4, #args - 1 do
          if not vim.list_contains(items, args[i]) then
            valid = false
            break
          end
          table.insert(used, args[i])
        end
        if valid then
          for _, item in ipairs(items) do
            if vim.startswith(item, args[#args]) and not vim.list_contains(used, item) then
              table.insert(res, item)
            end
          end
        end
      elseif
        #args == 5
        and args[2] == 'stats'
        and args[3] == 'export'
        and vim.list_contains({ 'json', 'markdown', 'lua' }, args[4])
      then
        res = vim.fn.getcompletion(args[5], 'file', true)
      elseif #args == 6 and args[2] == 'stats' and args[3] == 'export' and args[4] == 'json' and args[5] ~= '' then
        for _, v in ipairs(Util.range(1, 32)) do
          if vim.startswith(tostring(v), args[#args]) then
            table.insert(res, tostring(v))
          end
        end
      end
      return res
    end,
  })
end

return M
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
