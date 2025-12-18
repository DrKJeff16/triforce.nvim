-- Example test file for triforce.nvim
-- Run with: busted or luarocks test --local

describe('triforce', function()
  local triforce ---@type Triforce
  local config ---@type Triforce.Config

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded.triforce = nil
    triforce = require('triforce')
    config = require('triforce.config')
  end)

  describe('setup', function()
    it('should set default configuration', function()
      triforce.setup()
      assert.is_true(config.config.enabled)
    end)

    it('should merge user configuration with defaults', function()
      triforce.setup({
        enabled = false,
      })
      assert.is_false(config.config.enabled)
    end)

    it('should handle empty table parameter', function()
      local ok = pcall(triforce.setup, {})
      assert.is_true(ok)
      assert.is_true(config.config.enabled)
    end)

    it('should handle nil options', function()
      local ok = pcall(triforce.setup, nil)
      assert.is_true(ok)
      assert.is_true(config.config.enabled)
    end)

    it('should purge any invalid keys', function()
      local ok = pcall(triforce.setup, { foo = 'bar' })
      assert.is_true(ok)
      assert.are_same(config.config, config.defaults())
    end)

    local params = { 1, false, '', function() end }
    for _, param in ipairs(params) do
      it(('should throw error when called with param of type %s'):format(type(param)), function()
        local ok = pcall(triforce.setup, param)
        assert.is_false(ok)
      end)
    end

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

  describe('stats', function()
    describe('export to JSON', function()
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

    describe('export to Markdown', function()
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
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
