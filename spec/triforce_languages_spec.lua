local assert = require('luassert') --[[@as Luassert]]

describe('triforce', function()
  local triforce ---@type Triforce
  local languages ---@type Triforce.Languages

  before_each(function() -- Clear module cache to get fresh instance
    package.loaded['triforce'] = nil
    package.loaded['triforce.achievement'] = nil
    package.loaded['triforce.config'] = nil
    package.loaded['triforce.health'] = nil
    package.loaded['triforce.items'] = nil
    package.loaded['triforce.languages'] = nil
    package.loaded['triforce.levels'] = nil
    package.loaded['triforce.lualine'] = nil
    package.loaded['triforce.random_stats'] = nil
    package.loaded['triforce.stats'] = nil
    package.loaded['triforce.tracker'] = nil
    package.loaded['triforce.ui'] = nil
    package.loaded['triforce.ui.profile'] = nil
    package.loaded['triforce.util'] = nil

    triforce = require('triforce')
    languages = require('triforce.languages')
  end)

  describe('languages', function()
    it('should handle new languages gracefully', function()
      local custom_langs = {
        gleam = { icon = '', name = 'Gleam' },
        odin = { icon = '', name = 'Odin' },
      }
      assert.is_true((pcall(triforce.setup, { custom_languages = custom_langs })))
      assert.is_same(require('triforce.config').get().custom_languages, custom_langs)
    end)

    it('should process ignored languages', function()
      local ignore = { 'json', 'markdown', 'yaml' }
      local ok = pcall(triforce.setup, { ignore_ft = ignore })

      assert.is_true(ok)
      assert.is_same(languages.get_ignored_langs(), ignore)
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
