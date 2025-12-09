---Non-legacy validation spec (>=v0.11)
---@class ValidateSpec
---@field [1] any
---@field [2] vim.validate.Validator
---@field [3]? boolean
---@field [4]? string

---Various utilities to be used for Triforce
---@class Triforce.Util
local Util = {}

---Dynamic `vim.validate()` wrapper. Covers both legacy and newer implementations
---@param T table<string, vim.validate.Spec|ValidateSpec>
function Util.validate(T)
  if vim.fn.has('nvim-0.11') ~= 1 then
    ---Filter table to fit legacy standard
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

  ---Filter table to fit non-legacy standard
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

---@param x number
---@return boolean int
function Util.is_int(x)
  Util.validate({ x = { x, { 'number' } } })

  return (math.ceil(x) == x or math.floor(x) == x)
end

---@param T table
---@return boolean dict
function Util.is_dict(T)
  Util.validate({ T = { T, { 'table' } } })

  if vim.tbl_isempty(T) then
    return false
  end

  for k, _ in pairs(T) do
    if type(k) == 'string' or not Util.is_int(k) then
      return true
    end
  end

  return false
end

return Util
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
