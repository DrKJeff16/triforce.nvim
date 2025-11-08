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

  if subcommand == 'profile' then
    require('triforce').show_profile()
  elseif subcommand == 'stats' then
    require('triforce').show_profile()
  elseif subcommand == 'reset' then
    require('triforce').reset_stats()
  else
    vim.notify('Usage: :Triforce profile | stats | reset', vim.log.levels.INFO)
  end
end, {
  nargs = '*',
  desc = 'Triforce gamification commands',
  complete = function()
    return { 'profile', 'stats', 'reset' }
  end,
})

-- Create <Plug> mappings for users to map to their own keys
vim.keymap.set('n', '<Plug>(TriforceProfile)', function()
  require('triforce').show_profile()
end, {
  silent = true,
  desc = 'Triforce: Show profile',
})
