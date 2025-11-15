---@class Triforce.Util
local M = {}

---@param T table<string, vim.validate.Spec>
function M.validate(T)
  if vim.fn.has('nvim-0.11') ~= 1 then
    vim.validate(T)
    return
  end

  for name, spec in pairs(T) do
    table.insert(spec, 1, name)
    vim.validate(unpack(spec))
  end
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
