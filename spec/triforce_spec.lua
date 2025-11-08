-- Example test file for triforce.nvim
-- Run with: busted or luarocks test --local

describe('triforce', function()
  local triforce

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded['triforce'] = nil
    triforce = require('triforce')
  end)

  describe('setup', function()
    it('should set default configuration', function()
      triforce.setup()
      assert.is_true(triforce.config.enabled)
      assert.equals('Triforce activated!', triforce.config.message)
    end)

    it('should merge user configuration with defaults', function()
      triforce.setup({
        enabled = false,
        message = 'Custom message',
      })
      assert.is_false(triforce.config.enabled)
      assert.equals('Custom message', triforce.config.message)
    end)

    it('should handle nil options', function()
      triforce.setup(nil)
      assert.is_true(triforce.config.enabled)
    end)
  end)

  describe('hello', function()
    it('should exist as a function', function()
      assert.is_function(triforce.hello)
    end)

    -- Add more specific tests for hello() behavior
  end)
end)
