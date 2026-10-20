local assert = require('luassert') --[[@as Luassert]]

describe('triforce', function()
  local triforce ---@type Triforce
  local levels ---@type Triforce.Levels

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
    levels = require('triforce.levels')
  end)

  describe('levels', function()
    it('should parse custom levels', function()
      local lvls = { ---@type LevelParams[]
        { level = 3, title = 'Test 1' },
        { level = 5, title = 'Test 2' },
        { level = 8, title = 'Test 3' },
      }

      assert.is_true((pcall(triforce.setup, { levels = lvls })))

      for _, lvl in ipairs(lvls) do
        assert.is_same(lvl.title, levels.get_level_title(lvl.level, false))
      end
    end)

    it('should fail on missing custom level field', function()
      ---@diagnostic disable:missing-fields
      assert.is_false(
        (pcall(triforce.setup, { levels = { { title = 'Test 1' }, { level = 600 }, { title = 'Test 3' } } }))
      )
      ---@diagnostic enable:missing-fields
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
