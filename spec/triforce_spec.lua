-- Example test file for triforce.nvim
-- Run with: busted or luarocks test --local

local assert = require('luassert')

describe('triforce', function()
  local triforce --- @type Triforce

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded.triforce = nil
    triforce = require('triforce')
  end)

  describe('setup', function()
    it('should set default configuration', function()
      triforce.setup()
      assert.is_true(triforce.config.enabled)
      -- assert.equals('Triforce activated!', triforce.config.message)
    end)

    it('should merge user configuration with defaults', function()
      triforce.setup({
        enabled = false,
        -- message = 'Custom message',
      })
      assert.is_false(triforce.config.enabled)
      -- assert.equals('Custom message', triforce.config.message)
    end)

    it('should handle nil options', function()
      triforce.setup(nil)
      assert.is_true(triforce.config.enabled)
    end)
  end)

  describe('stats', function()
    it('should export to stats a JSON file', function()
      local ok = pcall(triforce.export_stats_to_json, 'spec/.stats.json')
      assert.is_true(ok)
    end)

    it('should throw error when exporting to empty JSON file', function()
      local ok = pcall(triforce.export_stats_to_json, nil)
      assert.is_false(ok)
    end)

    it('should export to stats a Markdown file', function()
      local ok = pcall(triforce.export_stats_to_md, 'spec/.stats.md')
      assert.is_true(ok)
    end)

    it('should throw error when exporting to empty Markdown file', function()
      local ok = pcall(triforce.export_stats_to_md, nil)
      assert.is_false(ok)
    end)
  end)
end)
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
