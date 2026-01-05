local assert = require('luassert') ---@type Luassert

describe('triforce', function()
  local triforce ---@type Triforce

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded.triforce = nil
    triforce = require('triforce')
    triforce.setup()
  end)

  describe('achievement', function()
    it('should accept new achievements', function()
      local achievement = require('triforce.achievement')
      local get_stats = require('triforce.tracker').get_stats
      local achv = {
        id = 'test_achv_1',
        name = 'Test Achievement #1',
        check = function()
          return true
        end,
        desc = 'Test achievement #1',
      }
      local ok, stats
      ok, stats = pcall(get_stats)
      assert.is_true(ok)

      ok = pcall(achievement.new_achievements, { achv }, stats)
      assert.is_true(ok)

      local all_achv = achievement.get_all_achievements(stats)
      assert.is_equal(achv, all_achv[#all_achv])
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
