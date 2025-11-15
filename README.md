# 🕹️ triforce.nvim

**Hey, listen!** Triforce adds a bit of RPG flavor to your coding — XP, levels, and achievements while you work.

<img
width="1920"
height="1080"
alt="image"
src="https://github.com/user-attachments/assets/8e3258bf-b052-449f-9ddb-37c9729c12ac"
/>

## 📑 Table of Contents

- [Why I Made This](#-why-i-made-this)
- [Features](#-features)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Lualine Integration](#-lualine-integration)
- [Usage](#-usage)
- [Achievements](#-achievements)
- [Customization](#-customization)
- [Data Storage](#-data-storage)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Support](#-support)

---

## 💭 Why I Made This

I have ADHD, and coding can sometimes feel like a grind — it’s hard to stay consistent or even get started some days. That’s part of why I fell in love with Neovim: it’s customizable, expressive, and makes the act of writing code feel *fun* again.

**Triforce** is actually my **first-ever Neovim plugin** (and the first plugin I’ve ever built in general). I’d always wanted to make something of my own, but I never really knew where to start. Once I got into Neovim’s Lua ecosystem, I got completely hooked. I started experimenting, tinkering, breaking things, and slowly, Triforce came to life.

I made it to **gamify my coding workflow** — to turn those long, sometimes frustrating coding sessions into something that feels rewarding. Watching the XP bar fill up, unlocking achievements, and seeing my progress in real time gives me that little *dopamine boost* that helps me stay focused and motivated.

I named it **Triforce** just because I love **The Legend of Zelda** — no deep reason beyond that.

The UI is **heavily inspired by [siduck](https://github.com/siduck)’s gorgeous designs** and **[nvzone/typr](https://github.com/nvzone/typr)** — their aesthetic sense and clean interface ideas played a huge role in how this turned out. Building it with **Volt.nvim** made the process so much smoother and helped me focus on bringing those ideas to life.

---

## ✨ Features

- **📊 Detailed Statistics**: Track lines typed, characters, sessions, coding time, and more
- **🎮 Gamification**: Earn XP and level up based on your coding activity
- **🏆 Achievements**: Unlock achievements for milestones (first 1000 chars, 10 sessions, polyglot badges, etc.)
- **📈 Activity Heatmap**: GitHub-style contribution graph showing your coding consistency
- **🌍 Language Tracking**: See which programming languages you use most
- **🎨 Beautiful UI**: Clean, themed interface powered by [Volt.nvim](https://github.com/NvChad/volt.nvim)
- **📊 Lualine Integration**: Optional modular statusline components (level, achievements, streak, session time)
- **⚙️ Highly Configurable**: Customize notifications, keymaps, and add custom languages
- **💾 Auto-Save**: Your progress is automatically saved every 5 minutes

---

## 📦 Installation

### Requirements

- **Neovim** >= 0.9.0
- [**nui.nvim**](https://github.com/MunifTanjim/nui.nvim) (UI component library)
- [**Volt.nvim**](https://github.com/NvChad/volt.nvim) (UI framework dependency)
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "gisketch/triforce.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvzone/volt",
  },
  config = function()
    require("triforce").setup({
      -- Optional: Add your configuration here
      keymap = {
        show_profile = "<leader>tp", -- Open profile with <leader>tp
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "gisketch/triforce.nvim",
  requires = { "nvzone/volt", "MunifTanjim/nui.nvim" },
  config = function()
    require("triforce").setup({
      keymap = {
        show_profile = "<leader>tp",
      },
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'MunifTanjim/nui.nvim'
Plug 'nvzone/volt'
Plug 'gisketch/triforce.nvim'

lua << EOF
require("triforce").setup({
  keymap = {
    show_profile = "<leader>tp",
  },
})
EOF
```

---

## ⚙️ Configuration

Triforce comes with sensible defaults, but you can customize everything:

```lua
require("triforce").setup({
  enabled = true,              -- Enable/disable the entire plugin
  gamification_enabled = true, -- Enable XP, levels, achievements

  -- Notification settings
  notifications = {
    enabled = true,       -- Master toggle for all notifications
    level_up = true,      -- Show level up notifications
    achievements = true,  -- Show achievement unlock notifications
  },

  -- Keymap configuration
  keymap = {
    show_profile = "<leader>tp", -- Set to nil to disable default keymap
  },

  -- Auto-save interval (in seconds)
  auto_save_interval = 300, -- Save stats every 5 minutes

  -- Add custom language support
  custom_languages = {
    gleam = { icon = "✨", name = "Gleam" },
    odin = { icon = "🔷", name = "Odin" },
    -- Add more languages...
  },

  -- Customize level progression (optional)
  level_progression = {
    tier_1 = { min_level = 1, max_level = 10, xp_per_level = 300 },   -- Levels 1-10
    tier_2 = { min_level = 11, max_level = 20, xp_per_level = 500 },  -- Levels 11-20
    tier_3 = { min_level = 21, max_level = math.huge, xp_per_level = 1000 }, -- Levels 21+
  },

  -- Customize XP rewards (optional)
  xp_rewards = {
    char = 1,   -- XP per character typed
    line = 1,   -- XP per new line
    save = 50,  -- XP per file save
  },
})
```

### Configuration Options

| Option                       | Type            | Default   | Description                           |
|------------------------------|-----------------|-----------|---------------------------------------|
| `enabled`                    | `boolean`       | `true`    | Enable/disable the plugin             |
| `gamification_enabled`       | `boolean`       | `true`    | Enable gamification features          |
| `notifications.enabled`      | `boolean`       | `true`    | Master toggle for notifications       |
| `notifications.level_up`     | `boolean`       | `true`    | Show level up notifications           |
| `notifications.achievements` | `boolean`       | `true`    | Show achievement notifications        |
| `auto_save_interval`         | `number`        | `300`     | Auto-save interval in seconds         |
| `keymap.show_profile`        | `string \| nil` | `nil`     | Keymap for opening profile            |
| `custom_languages`           | `table \| nil`  | `nil`     | Custom language definitions           |
| `level_progression`          | `table \| nil`  | See below | Custom XP requirements per level tier |
| `xp_rewards`                 | `table \| nil`  | See below | Custom XP rewards for actions         |

### Level Progression

By default, Triforce uses a **simple, easy-to-reach** leveling system:

- **Levels 1-10**: 300 XP per level
- **Levels 11-20**: 500 XP per level
- **Levels 21+**: 1,000 XP per level

**Example progression:**
- Level 5: 1,500 XP (5 × 300)
- Level 10: 3,000 XP (10 × 300)
- Level 15: 5,500 XP (3,000 + 5 × 500)
- Level 20: 8,000 XP (3,000 + 10 × 500)
- Level 30: 18,000 XP (8,000 + 10 × 1,000)

You can customize this by overriding `level_progression` in your setup. For example, to make it even easier:

```lua
require("triforce").setup({
  level_progression = {
    tier_1 = { min_level = 1, max_level = 15, xp_per_level = 200 },   -- Super easy early levels
    tier_2 = { min_level = 16, max_level = 30, xp_per_level = 400 },
    tier_3 = { min_level = 31, max_level = math.huge, xp_per_level = 800 },
  },
})
```

### XP Rewards

By default, Triforce awards XP for different coding activities:

- **Character typed**: 1 XP
- **New line**: 1 XP
- **File save**: 50 XP

You can customize these values to match your preferences. For example, if you want to emphasize quality over quantity and reward saves more:

```lua
require("triforce").setup({
  xp_rewards = {
    char = 0.5,  -- Less XP for characters
    line = 2,    -- More XP for new lines
    save = 100,  -- Reward file saves heavily
  },
})
```

Or if you prefer to focus on typing volume:

```lua
require("triforce").setup({
  xp_rewards = {
    char = 2,    -- More XP per character
    line = 5,    -- Moderate XP for lines
    save = 25,   -- Less emphasis on saves
  },
})
```

---

## 📊 Lualine Integration

Triforce provides **modular statusline components** for [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim), letting you display your coding stats right in your statusline.

<img
width="378"
height="74"
alt="image"
src="https://github.com/user-attachments/assets/7b81a71b-2f66-414b-abed-4c42e09c463f"
/>


### Available Components

| Component         | Default Display (uses NerdFont) | Description                  |
|-------------------|---------------------------------|------------------------------|
| `level`           | `Lv.27 ████░░`                  | Level + XP progress bar      |
| `achievements`    | `🏆 12/18`                      | Unlocked/total achievements  |
| `streak`          | `🔥 5`                          | Current coding streak (days) |
| `session_time`    | `⏰ 2h 34m`                     | Current session duration     |

### Basic Setup

Add Triforce components to your lualine configuration:

```lua
require('lualine').setup({
  sections = {
    lualine_x = {
      -- Add one or more components
      require('triforce.lualine').level,
      require('triforce.lualine').achievements,
      'encoding', 'fileformat', 'filetype'
    },
  }
})
```

### Quick Setup (All Components)

Use the `components()` helper to get all components at once:

```lua
local triforce = require('triforce.lualine').components()

require('lualine').setup({
  sections = {
    lualine_x = {
      triforce.level,
      triforce.achievements,
      triforce.streak,
      triforce.session_time,
      'encoding', 'fileformat', 'filetype'
    },
  }
})
```

### Component Configuration

Each component can be customized independently:

#### Level Component

```lua
-- Default: prefix + level + bar
function()
  return require('triforce.lualine').level()
end
-- Result: Lv.27 ████░░

-- Show percentage instead of bar
function()
  return require('triforce.lualine').level({
    show_bar = false,
    show_percent = true,
  })
end
-- Result: Lv.27 90%

-- Show everything (XP numbers + percentage)
function()
  return require('triforce.lualine').level({
    show_bar = true,
    show_percent = true,
    show_xp = true,
    bar_length = 8,
  })
end
-- Result: Lv.27 ████████ 90% 450/500

-- Customize bar style
function()
  return require('triforce.lualine').level({
    bar_chars = { filled = '●', empty = '○' },
    bar_length = 10,
  })
end
-- Result: Lv.27 ●●●●●●●●●○

-- Custom prefix or no prefix
function()
  return require('triforce.lualine').level({
    prefix = 'Level ',  -- or set to '' for no prefix
  })
end
-- Result: Level 27 ████░░
```

**Options:**
- `prefix` (string): Text prefix before level number (default: `'Lv.'`)
- `show_level` (boolean): Show level number (default: `true`)
- `show_bar` (boolean): Show progress bar (default: `true`)
- `show_percent` (boolean): Show percentage (default: `false`)
- `show_xp` (boolean): Show XP numbers like `450/500` (default: `false`)
- `bar_length` (number): Progress bar length (default: `6`)
- `bar_chars` (table): `{ filled = '█', empty = '░' }` (default)

#### Achievements Component

```lua
-- Default
function()
  return require('triforce.lualine').achievements()
end
-- Result:  12/18

-- Custom icon or no icon
function()
  return require('triforce.lualine').achievements({
    icon = '',  -- or '' for no icon
  })
end
-- Result:  12/18
```

**Options:**
- `icon` (string): Icon to display (default: `''` - trophy)
- `show_count` (boolean): Show unlocked/total count (default: `true`)

#### Streak Component

```lua
-- Default
function()
  return require('triforce.lualine').streak()
end
-- Result:  5

-- Different icon
function()
  return require('triforce.lualine').streak({
    icon = '',
  })
end
-- Result:  5
```

**Options:**
- `icon` (string): Icon to display (default: `''` - flame)
- `show_days` (boolean): Show day count (default: `true`)

> [!NOTE]
> The streak component returns an empty string when streak is 0, so it won't clutter your statusline.

#### Session Time Component

```lua
-- Default (short format)
function()
  return require('triforce.lualine').session_time()
end
-- Result:  2h 34m

-- Long format (2:34:12 instead of 2h 34m)
function()
  return require('triforce.lualine').session_time({
    format = 'long',
  })
end
-- Result:  2:34:12

-- Different icon
function()
  return require('triforce.lualine').session_time({
    icon = '',  -- watch icon
  })
end
-- Result:  2h 34m
```

**Options:**
- `icon` (string): Icon to display (default: `''` - clock)
- `show_duration` (boolean): Show time duration (default: `true`)
- `format` (string): `'short'` (2h 34m) or `'long'` (2:34:12) (default: `'short'`)

### Global Component Configuration

Set defaults for all components:

```lua
-- Configure defaults
require('triforce.lualine').setup({
  level = {
    prefix = 'Level ',
    bar_length = 8,
    show_percent = true,
  },
  achievements = {
    icon = '',
  },
  streak = {
    icon = '',
  },
  session_time = {
    icon = '',
    format = 'long',
  },
})

-- Then use components normally
local triforce = require('triforce.lualine').components()
```

### Example Configurations

#### Minimalist Setup

```lua
require('lualine').setup({
  sections = {
    lualine_x = {
      require('triforce.lualine').level,
    },
  }
})
-- Result: Lv.27 ████░░
```

#### Full Stats Dashboard

```lua
local triforce = require('triforce.lualine').components()

require('lualine').setup({
  sections = {
    lualine_c = { 'filename' },
    lualine_x = {
      triforce.session_time,
      triforce.streak,
      triforce.achievements,
      triforce.level,
      'encoding', 'filetype'
    },
  }
})
-- Result:  2h 34m  5  12/18 Lv.27 ████░░ ...
```

#### Custom Styled

```lua
require('triforce.lualine').setup({
  level = {
    prefix = '',  -- No prefix, just number
    bar_chars = { filled = '●', empty = '○' },
    bar_length = 10,
    show_percent = true,
  },
  achievements = {
    icon = '',  -- medal icon
  },
  streak = {
    icon = '',  -- bolt icon
  },
})

local triforce = require('triforce.lualine').components()
-- Now all components use your custom config
-- Result:  2h 34m  5  12/18 27 ●●●●●●●●●○ 90%
```

---

## 🎮 Usage

### Commands

| Command                                      | Description                          |
|----------------------------------------------|--------------------------------------|
| `:lua require("triforce").show_profile()`    | Open the Triforce profile UI         |
| `:lua require("triforce").get_stats()`       | Get current stats programmatically   |
| `:lua require("triforce").reset_stats()`     | Reset all stats (useful for testing) |
| `:lua require("triforce").save_stats()`      | Force save stats immediately         |
| `:lua require("triforce").debug_languages()` | Debug language tracking              |

### Profile UI

The profile has **3 tabs**:

1. **📊 Stats Tab**
   - Level progress bar
   - Session/time milestone progress
   - Activity heatmap (7 months)
   - Quick stats overview

<img
width="1224"
height="970"
alt="image"
src="https://github.com/user-attachments/assets/38bef3f2-9534-45c6-a0f6-8d34a166a42e"
/>

2. **🏆 Achievements Tab**
   - View all unlocked achievements
   - See locked achievements with unlock requirements
   - Paginate through achievements (H/L or arrow keys)

<img
width="1219"
height="774"
alt="image"
src="https://github.com/user-attachments/assets/53913333-214e-47de-af99-1da58c40fd77"
/>

3. **💻 Languages Tab**
   - Bar graph showing your most-used languages
   - See character count breakdown by language

<img
width="1210"
height="784"
alt="image"
src="https://github.com/user-attachments/assets/a8d3c98c-16d5-4e15-8c39-538e3bb7ce81"
/>

**Keybindings in Profile:**
- `Tab`: Cycle between tabs
- `H` / `L` or `←` / `→`: Navigate achievement pages
- `q` / `Esc`: Close profile

---

## 🏆 Achievements

Triforce includes **18 built-in achievements** across 5 categories:

### 📝 Typing Milestones

- 🌱 **First Steps**: Type 100 characters
- ⚔️ **Getting Started**: Type 1,000 characters
- 🛡️ **Dedicated Coder**: Type 10,000 characters
- 📜 **Master Scribe**: Type 100,000 characters

### 📈 Level Achievements

- ⭐ **Rising Star**: Reach level 5
- 💎 **Expert Coder**: Reach level 10
- 👑 **Champion**: Reach level 25
- 🔱 **Legend**: Reach level 50

### 🔄 Session Achievements

- 🔄 **Regular Visitor**: Complete 10 sessions
- 📅 **Creature of Habit**: Complete 50 sessions
- 🏆 **Dedicated Hero**: Complete 100 sessions

### ⏰ Time Achievements

- ⏰ **First Hour**: Code for 1 hour total
- ⌛ **Committed**: Code for 10 hours total
- 🕐 **Veteran**: Code for 100 hours total

### 🌍 Polyglot Achievements

- 🌍 **Polyglot Beginner**: Code in 3 languages
- 🌎 **Polyglot**: Code in 5 languages
- 🌏 **Master Polyglot**: Code in 10 languages
- 🗺️ **Language Virtuoso**: Code in 15 languages

---

## 🎨 Customization

### Adding Custom Languages

Triforce supports 50+ programming languages out of the box, but you can add more:

```lua
require("triforce").setup({
  custom_languages = {
    gleam = {
      icon = "✨",
      name = "Gleam"
    },
    zig = {
      icon = "⚡",
      name = "Zig"
    },
  },
})
```

### Disabling Notifications

Turn off all notifications or specific types:

```lua
require("triforce").setup({
  notifications = {
    enabled = true,       -- Keep enabled
    level_up = false,     -- Disable level up notifications
    achievements = true,  -- Keep achievement notifications
  },
})
```

### Disable Auto-Keymap

If you prefer to set your own keymap:

```lua
require("triforce").setup({
  keymap = {
    show_profile = nil, -- Don't create default keymap
  },
})

-- Set your own keymap
vim.keymap.set("n", "<C-s>", function()
  require("triforce").show_profile()
end, { desc = "Show Triforce Stats" })
```

---

## 📊 Data Storage

Stats are saved to `~/.local/share/nvim/triforce_stats.json`.

The file is automatically backed up before each save to `~/.local/share/nvim/triforce_stats.json.bak`.

### Data Format

```json
{
  "xp": 15420,
  "level": 12,
  "chars_typed": 45230,
  "lines_typed": 1240,
  "sessions": 42,
  "time_coding": 14580,
  "achievements": {
    "first_100": true,
    "level_10": true
  },
  "chars_by_language": {
    "lua": 12000,
    "python": 8500
  },
  "daily_activity": {
    "2025-11-07": 145,
    "2025-11-08": 203
  },
  "current_streak": 5,
  "longest_streak": 12
}
```

---

## 🗺️ Roadmap

### Future Features

- [ ] **Sounds for Achievements and Level up**: Add sfx feedback for leveling up or completing achievements for dopamine!
- [ ] **Cloud Sync**: Sync stats across multiple devices (Firebase, GitHub Gist, or custom server)
- [ ] **Leaderboards**: Compete with friends or the community
- [ ] **Custom Achievements**: Define your own achievement criteria
- [ ] **Export Stats**: Export to CSV, JSON, or markdown reports
- [ ] **Weekly/Monthly Reports**: Automated summaries via notifications
- [ ] **Themes**: Customizable color schemes for the profile UI
- [ ] **Plugin API**: Expose hooks for other plugins to integrate

**Have a feature idea?** Open an issue on GitHub!

---

## 🤝 Contributing

Contributions are welcome! Here's how to help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development

```bash
# Clone the repo
git clone https://github.com/gisketch/triforce.nvim.git
cd triforce.nvim

# Symlink to Neovim config for testing
ln -s $(pwd) ~/.local/share/nvim/site/pack/plugins/start/triforce.nvim
```

---

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **[nvzone/volt](https://github.com/nvzone/volt)**: Beautiful UI framework
- **[Typr](https://github.com/nvzone/typr)**: Beautiful Grid Design Component Inspiration
- **[Gamify](https://github.com/GrzegorzSzczepanek/gamify.nvim)**: Another cool gamify plugin, good inspiration for achievements

---

## 📮 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/gisketch/triforce.nvim/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/gisketch/triforce.nvim/discussions)

---

## Star History

<div align="center">

**Made with ❤️ for the Neovim community**

⭐ Star this repo if you find it useful!

[![Star History Chart](https://api.star-history.com/svg?repos=gisketch/triforce.nvim&type=date&legend=top-left)](https://www.star-history.com/#gisketch/triforce.nvim&type=date&legend=top-left)

</div>
