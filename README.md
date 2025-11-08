# triforce.nvim

⚔️ Gamify your Neovim coding experience! Track your typing stats, earn XP, level up, and unlock achievements.

## Features

- 📊 **Real-time Stats Tracking** - Monitor characters typed, lines written, and coding time
- ⭐ **XP & Leveling System** - Earn experience points and level up as you code
- 🏆 **Achievements** - Unlock achievements for reaching milestones
- 📈 **Beautiful Profile UI** - View your stats in a clean, visual interface powered by nui.nvim
- 💾 **Persistent Progress** - Stats are automatically saved and persist across sessions

## Requirements

- Neovim >= 0.9.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) - UI component library

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'gisketch/triforce.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('triforce').setup({
      -- your configuration here
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'gisketch/triforce.nvim',
  requires = { 'MunifTanjim/nui.nvim' },
  config = function()
    require('triforce').setup()
  end,
}
```

## Configuration

Default configuration:

```lua
require('triforce').setup({
  enabled = true,
  gamification_enabled = true,      -- Enable stats tracking and XP system
  notifications_enabled = true,     -- Show level up and achievement notifications
  auto_save_interval = 300,         -- Auto-save stats every 5 minutes
})
```

## Usage

### Commands

- `:Triforce profile` - Show your coding profile with stats and achievements
- `:Triforce stats` - Alias for profile
- `:Triforce reset` - Reset all stats (useful for testing)

### Keymaps

The plugin provides `<Plug>` mappings. Map them to your preferred keys:

```lua
-- Show profile
vim.keymap.set('n', '<leader>tp', '<Plug>(TriforceProfile)')
```

### Lua API

```lua
local triforce = require('triforce')

-- Show profile UI
triforce.show_profile()

-- Get current stats
local stats = triforce.get_stats()
print('Level:', stats.level)
print('XP:', stats.xp)
print('Characters typed:', stats.chars_typed)

-- Reset stats
triforce.reset_stats()
```

## How It Works

### XP System

Earn XP by coding:
- **1 XP** per character typed
- **10 XP** per new line
- **50 XP** per file save

Level progression uses the formula: `level = floor(sqrt(xp / 100)) + 1`
- Level 2: 100 XP
- Level 3: 400 XP
- Level 4: 900 XP
- Level 5: 1,600 XP
- And so on...

### Achievements

Unlock achievements by reaching milestones:
- 🎯 **First Steps** - Type 100 characters
- ⭐ **Getting Started** - Type 1,000 characters
- 💪 **Dedicated Coder** - Type 10,000 characters
- 🌟 **Rising Star** - Reach level 5
- 👑 **Expert Coder** - Reach level 10
- 📅 **Regular Visitor** - Complete 10 sessions
- 🔥 **Creature of Habit** - Complete 50 sessions

### Stats Persistence

Stats are automatically saved to `~/.local/share/nvim/triforce_stats.json` and persist across sessions.

## Health Check

Run `:checkhealth triforce` to verify the plugin is working correctly.

## Development

### Testing

```bash
# Install dependencies
luarocks install --local busted
luarocks install --local nlua

# Run tests
busted
```

### Linting

```bash
# Install luacheck
luarocks install --local luacheck

# Run linter
luacheck .
```

### Formatting

```bash
# Install stylua
cargo install stylua

# Format code
stylua .
```

## License

MIT
