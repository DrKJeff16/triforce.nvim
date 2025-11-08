---Health check for triforce.nvim
---Run with :checkhealth triforce

local M = {}

---Perform health checks
function M.check()
  vim.health.start('triforce.nvim')

  -- Check Neovim version
  local nvim_version = vim.version()
  if nvim_version.major == 0 and nvim_version.minor >= 9 then
    vim.health.ok(string.format('Neovim version: %s.%s.%s', nvim_version.major, nvim_version.minor, nvim_version.patch))
  else
    vim.health.error('Neovim >= 0.9.0 is required')
  end

  -- Check if nui.nvim is installed
  local nui_ok = pcall(require, 'nui.popup')
  if nui_ok then
    vim.health.ok('nui.nvim is installed')
  else
    vim.health.error('nui.nvim is not installed (required dependency)')
  end

  -- Check if plugin is loaded
  local ok, triforce = pcall(require, 'triforce')
  if ok then
    vim.health.ok('triforce module loaded successfully')

    -- Check configuration
    if triforce.config.enabled then
      vim.health.ok('Plugin is enabled')
    else
      vim.health.warn('Plugin is disabled in configuration')
    end

    -- Check gamification status
    if triforce.config.gamification_enabled then
      vim.health.ok('Gamification is enabled')

      -- Check if stats file exists
      local stats_path = vim.fn.stdpath('data') .. '/triforce_stats.json'
      if vim.fn.filereadable(stats_path) == 1 then
        vim.health.ok('Stats file found: ' .. stats_path)
      else
        vim.health.info('Stats file not yet created (will be created on first use)')
      end
    else
      vim.health.warn('Gamification is disabled')
    end
  else
    vim.health.error('Failed to load triforce module: ' .. tostring(triforce))
  end
end

return M
