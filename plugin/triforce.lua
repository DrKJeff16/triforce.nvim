-- Minimal startup file - keep lightweight for fast loading
-- This file is loaded automatically when Neovim starts

-- Check Neovim version compatibility
if vim.fn.has('nvim-0.9') == 0 then
  vim.api.nvim_err_writeln('triforce.nvim requires Neovim >= 0.9.0')
  return
end

-- Prevent loading twice
if vim.g.loaded_triforce then
  return
end
vim.g.loaded_triforce = 1

-- Create user commands with subcommands
vim.api.nvim_create_user_command('Triforce', function(opts)
  local subcommand = opts.fargs[1]
  local subcommand2 = opts.fargs[2]

  if subcommand == 'profile' then
    require('triforce').show_profile()
  elseif subcommand == 'stats' then
    require('triforce').show_profile()
  elseif subcommand == 'reset' then
    require('triforce').reset_stats()
  elseif subcommand == 'debug' then
    if subcommand2 == 'xp' then
      require('triforce').debug_xp()
    elseif subcommand2 == 'achievement' then
      require('triforce').debug_achievement()
    elseif subcommand2 == 'languages' then
      require('triforce').debug_languages()
    elseif subcommand2 == 'fix' then
      require('triforce').debug_fix_level()
    else
      vim.notify('Usage: :Triforce debug xp | achievement | languages | fix', vim.log.levels.INFO)
    end
  else
    vim.notify('Usage: :Triforce profile | stats | reset | debug', vim.log.levels.INFO)
  end
end, {
  nargs = '*',
  desc = 'Triforce gamification commands',
  complete = function(_, line)
    local args = vim.split(line, '%s+', { trimempty = true })
    if #args == 1 then
      return { 'profile', 'stats', 'reset', 'debug' }
    end
    if #args == 2 and args[1] == 'debug' then
      return { 'xp', 'achievement', 'languages', 'fix' }
    end
    return {}
  end,
})

-- Create <Plug> mappings for users to map to their own keys
vim.keymap.set('n', '<Plug>(TriforceProfile)', require('triforce').show_profile, {
  silent = true,
  desc = 'Triforce: Show profile',
})
