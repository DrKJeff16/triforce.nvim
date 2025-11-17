---Non-legacy validation spec (>=v0.11)
---@class ValidateSpec
---@field [1] any
---@field [2] vim.validate.Validator
---@field [3]? boolean
---@field [4]? string

---Various utilities to be used for Triforce
---@class Triforce.Util
local M = {}

---Dynamic `vim.validate()` wrapper. Covers both legacy and newer implementations
---@param T table<string, vim.validate.Spec|ValidateSpec>
function M.validate(T)
  if vim.fn.has('nvim-0.11') ~= 1 then
    -- Filter table to fit legacy standard
    ---@cast T table<string, vim.validate.Spec>
    for name, spec in pairs(T) do
      while #spec > 3 do
        spec[#spec] = nil
      end

      T[name] = spec
    end

    vim.validate(T)
    return
  end

  -- Filter table to fit non-legacy standard
  ---@cast T table<string, ValidateSpec>
  for name, spec in pairs(T) do
    while #spec > 4 do
      spec[#spec] = nil
    end

    T[name] = spec
  end

  for name, spec in pairs(T) do
    table.insert(spec, 1, name)
    vim.validate(unpack(spec))
  end
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
