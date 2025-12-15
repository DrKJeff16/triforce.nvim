-- Minimal startup file - keep lightweight for fast loading
-- This file is loaded automatically when Neovim starts

-- Check Neovim version compatibility
if vim.fn.has('nvim-0.9') ~= 1 then
  vim.api.nvim_err_writeln('triforce.nvim requires Neovim >= 0.9.0') ---@diagnostic disable-line:deprecated
  return
end

-- Prevent loading twice
if vim.g.loaded_triforce == 1 then
  return
end
vim.g.loaded_triforce = 1

-- Create user commands with subcommands
vim.api.nvim_create_user_command('Triforce', function(opts)
  local subcommand = opts.fargs[1]
  local subcommand2 = opts.fargs[2] or ''
  local subcommand3 = opts.fargs[3] or ''
  local subcommand4 = opts.fargs[4] or ''
  local triforce = require('triforce')

  if subcommand == 'config' then
    require('triforce.config').toggle_window()
    return
  end

  if subcommand == 'profile' then
    triforce.show_profile()
    return
  end
  if subcommand == 'reset' then
    triforce.reset_stats()
    return
  end

  if subcommand == 'stats' then
    if subcommand2 == '' then
      vim.notify(vim.inspect(triforce.get_stats()), vim.log.levels.INFO)
      return
    end

    if subcommand2 == 'save' then
      triforce.save_stats()
      return
    end

    if subcommand2 ~= 'export' then
      vim.notify(
        [[
Usage: :Triforce stats
        :Triforce stats export
        :Triforce stats export json </path/to/file>
        :Triforce stats export markdown </path/to/file>]],
        vim.log.levels.INFO
      )
      return
    end

    if subcommand3 == '' then
      triforce.export_stats()
      return
    end

    if not vim.list_contains({ 'json', 'markdown' }, subcommand3) then
      vim.notify(
        [[
Usage: :Triforce stats export json <path/to/file>
        :Triforce stats export markdown </path/to/file>]],
        vim.log.levels.INFO
      )
      return
    end

    if subcommand3 == 'markdown' then
      if subcommand4 == '' then
        vim.notify('Usage: :Triforce stats export markdown </path/to/file>', vim.log.levels.INFO)
        return
      end

      triforce.export_stats_to_md(subcommand4)
      return
    end

    if subcommand4 == '' then
      vim.notify('Usage: :Triforce stats export json </path/to/file>', vim.log.levels.INFO)
      return
    end

    triforce.export_stats_to_json(subcommand4)
    return
  end

  -- Plan B: If subcommand value is not valid then abort and print usage
  if subcommand ~= 'debug' then
    vim.notify(
      [[
Usage: :Triforce config
       :Triforce debug xp | achievement | languages | fix
       :Triforce profile
       :Triforce reset
       :Triforce stats
       :Triforce stats export
       :Triforce stats export json <path/to/file>
       :Triforce stats export markdown </path/to/file>
       :Triforce stats save]],
      vim.log.levels.INFO
    )
    return
  end

  local debug_ops = {
    xp = triforce.debug_xp,
    achievement = triforce.debug_achievement,
    languages = triforce.debug_languages,
    fix = triforce.debug_fix_level,
  }

  -- Plan B: If subcommand2 value is not valid then abort and print usage
  if not vim.list_contains(vim.tbl_keys(debug_ops), subcommand2) then
    vim.notify('Usage: :Triforce debug xp | achievement | languages | fix', vim.log.levels.INFO)
    return
  end

  local operation = debug_ops[subcommand2]
  operation()
end, {
  nargs = '*',
  desc = 'Triforce gamification commands',
  complete = function(_, line)
    local args = vim.split(line, '%s+', { trimempty = true })
    if #args == 1 then
      return { 'profile', 'stats', 'reset', 'debug', 'config' }
    end
    if #args == 2 and args[2] == 'debug' then
      return { 'xp', 'achievement', 'languages', 'fix' }
    end
    if #args == 2 and args[2] == 'stats' then
      return { 'export', 'save' }
    end
    if #args == 3 and args[2] == 'stats' and args[3] == 'export' then
      return { 'json', 'markdown' }
    end
    return {}
  end,
})

-- Create <Plug> mappings for users to map to their own keys
vim.keymap.set('n', '<Plug>(TriforceProfile)', require('triforce').show_profile, {
  noremap = true,
  silent = true,
  desc = 'Triforce: Show profile',
})
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
