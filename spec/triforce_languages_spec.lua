local assert = require('luassert')

describe('triforce', function()
  local triforce ---@type Triforce

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded.triforce = nil
    triforce = require('triforce')
    triforce.setup()
  end)

  describe('languages', function()
    it('should handle new languages gracefully', function()
      local ok = pcall(triforce.setup, {
        custom_languages = {
          gleam = { icon = '', name = 'Gleam' },
          odin = { icon = '', name = 'Odin' },
        },
      })
      assert.is_true(ok)
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
