local assert = require('luassert') --[[@as Luassert]]

describe('triforce', function()
  local triforce ---@type Triforce
  local achievement ---@type Triforce.Achievements

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
    achievement = require('triforce.achievement')
    triforce.setup()
  end)

  describe('achievement', function()
    local get_stats ---@type fun(): stats: Stats|nil|?

    before_each(function()
      get_stats = require('triforce.tracker').get_stats
    end)

    it('should accept new achievements', function()
      local achv = {
        check = function()
          return true
        end,
        desc = 'Test achievement #1',
        id = 'test_achv_1',
        name = 'Test Achievement #1',
      }
      local ok, stats = pcall(get_stats)
      assert.is_true(ok)
      assert.is_true((pcall(achievement.new_achievements, achv, stats)))

      local ok_achv, all_achv = pcall(achievement.get_all_achievements, stats)
      assert.is_true(ok_achv)
      assert.is_equal(achv, all_achv[#all_achv])
    end)

    it('should fail on incomplete new achievement', function()
      local ok, stats = pcall(get_stats)
      assert.is_true(ok)
      ---@diagnostic disable:missing-fields
      assert.is_false((pcall(achievement.new_achievements, {
        { desc = 'Test achievement #1', id = 'test_achv_1' },
        {
          check = function()
            return true
          end,
          desc = 'Test achievement #1',
        },
      }, stats)))
      ---@diagnostic enable:missing-fields
    end)

    it('should fail new achievements on bad parameter types', function()
      local ok, stats = pcall(get_stats)
      assert.is_true(ok)
      assert.is_false((pcall(achievement.new_achievements, true, stats)))
      assert.is_false((pcall(achievement.new_achievements, 1, stats)))
      assert.is_false((pcall(achievement.new_achievements, function() end, stats)))
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
