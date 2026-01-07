local assert = require('luassert') ---@type Luassert

describe('triforce', function()
  local triforce ---@type Triforce
  local stats ---@type Triforce.Stats

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded.triforce = nil
    triforce = require('triforce')
    triforce.setup()
  end)

  describe('stats', function()
    before_each(function()
      stats = require('triforce.stats')
    end)

    describe('saving', function()
      for _, param in ipairs({ 1, function() end, true }) do
        it(('should fail if path is a %s'):format(type(param)), function()
          local ok
          ok = pcall(stats.save, nil, param)
          assert.is_false(ok)
        end)
      end
    end)

    describe('export', function()
      describe('to JSON', function()
        local fpath = 'spec/.stats.json'
        it('should export to stats with a given path', function()
          local ok = pcall(triforce.export_stats_to_json, fpath)
          assert.is_true(ok)
          os.remove(fpath)
        end)

        it('should throw error when path is not valid', function()
          local ok = pcall(triforce.export_stats_to_json, '.anyarbitrarydirectory/specs.json')
          assert.is_false(ok)
        end)

        it('should throw error when nil path is passed', function()
          local ok = pcall(triforce.export_stats_to_json, nil)
          assert.is_false(ok)
        end)
      end)

      describe('to Markdown', function()
        local fpath = 'spec/.stats.md'
        it('should export to stats with a given path', function()
          local ok = pcall(triforce.export_stats_to_md, fpath)
          assert.is_true(ok)
          os.remove(fpath)
        end)

        it('should throw error when path is not valid', function()
          local ok = pcall(triforce.export_stats_to_md, '.anyarbitrarydirectory/specs.md')
          assert.is_false(ok)
        end)

        it('should throw error when nil path is passed', function()
          local ok = pcall(triforce.export_stats_to_md, nil)
          assert.is_false(ok)
        end)
      end)
    end)
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
