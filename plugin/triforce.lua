if vim.g.triforce_loaded == 1 then
  return
end
vim.g.triforce_loaded = 1

require('triforce.commands').setup()
