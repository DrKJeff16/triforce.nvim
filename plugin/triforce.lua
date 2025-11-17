-- Minimal startup file - keep lightweight for fast loading
-- This file is loaded automatically when Neovim starts

-- Check Neovim version compatibility
if vim.fn.has('nvim-0.9') == 0 then
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
  local subcommand2 = opts.fargs[2]
  local triforce = require('triforce')

  if vim.list_contains({ 'profile', 'stats' }, subcommand) then
    triforce.show_profile()
    return
  end
  if subcommand == 'reset' then
    triforce.reset_stats()
    return
  end

  -- Plan B: If subcommand value is not valid then abort and print usage
  if subcommand ~= 'debug' then
    vim.notify('Usage: :Triforce profile | stats | reset | debug', vim.log.levels.INFO)
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
      return { 'profile', 'stats', 'reset', 'debug' }
    end
    if #args == 2 and args[2] == 'debug' then
      return { 'xp', 'achievement', 'languages', 'fix' }
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
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
