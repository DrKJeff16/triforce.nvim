local assert = require('luassert') --[[@as Luassert]]

describe('triforce', function()
  local triforce ---@type Triforce
  local config ---@type Triforce.Config

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
    config = require('triforce.config')
  end)

  describe('setup', function()
    it('should set default configuration', function()
      assert.is_true((pcall(triforce.setup)))
      assert.is_true(config.get().enabled)
    end)

    it('should merge user configuration with defaults', function()
      assert.is_true((pcall(triforce.setup, { enabled = false })))
      assert.is_false(config.get().enabled)
    end)

    it('should handle empty table parameter', function()
      assert.is_true((pcall(triforce.setup, {})))
      assert.is_true(config.get().enabled)
    end)

    it('should handle nil options', function()
      assert.is_true((pcall(triforce.setup, nil)))
      assert.is_true(config.get().enabled)
    end)

    it('should purge any invalid keys', function()
      assert.is_true((pcall(triforce.setup, { foo = 'bar' })))
      assert.are_same(config.get(), config.defaults())
    end)

    local params = { 1, false, '', function() end }
    for _, param in ipairs(params) do
      it(('should throw error when called with param of type %s'):format(type(param)), function()
        assert.is_false((pcall(triforce.setup, param)))
      end)
    end
  end)
end)
-- vim: set ts=2 sts=2 sw=2 et ai si sta:
