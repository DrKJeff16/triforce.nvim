local assert = require('luassert')

describe('triforce', function()
  local triforce ---@type Triforce

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded.triforce = nil
    triforce = require('triforce')
  end)

  describe('languages', function()
    it('should handle new languages gracefully', function()
      local custom_langs = {
        gleam = { icon = '', name = 'Gleam' },
        odin = { icon = '', name = 'Odin' },
      }
      local ok = pcall(triforce.setup, { custom_languages = custom_langs })
      assert.is_true(ok)

      local config = require('triforce.config')
      assert.is_same(config.config.custom_languages, custom_langs)
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
