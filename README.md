# 🕹️ triforce.nvim

## 💭 Why I Made This

I have ADHD, and coding can sometimes feel boring and hard to stay consistent with, especially when you're struggling with task initiation and motivation. That's why I love Neovim—it's highly customizable and makes the development experience actually *fun*. I made Triforce to gamify my coding workflow, turning those grinding sessions into something rewarding. Seeing that XP bar fill up, unlocking achievements, and tracking my progress in real-time? That's the dopamine hit that keeps me coding!

**Huge inspiration to [nvzone/typr](https://github.com/nvzone/typr) and most of siduck's creations**—his design work is absolutely gorgeous, and I shamelessly drew heavy inspiration from the beautiful aesthetics and thoughtful UI patterns he's created. The Volt.nvim framework is a game-changer for building clean, polished interfaces.

---

**Gamify your Neovim coding experience!** Track your progress, unlock achievements, and level up as you code.

Triforce transforms your coding sessions into an RPG-like adventure with XP, levels, achievements, and detailed statistics—all while you focus on what matters: writing great code.

---

## ✨ Features

- **📊 Detailed Statistics**: Track lines typed, characters, sessions, coding time, and more
- **🎮 Gamification**: Earn XP and level up based on your coding activity
- **🏆 Achievements**: Unlock achievements for milestones (first 1000 chars, 10 sessions, polyglot badges, etc.)
- **📈 Activity Heatmap**: GitHub-style contribution graph showing your coding consistency
- **🌍 Language Tracking**: See which programming languages you use most
- **🎨 Beautiful UI**: Clean, themed interface powered by [Volt.nvim](https://github.com/NvChad/volt.nvim)
- **⚙️ Highly Configurable**: Customize notifications, keymaps, and add custom languages
- **💾 Auto-Save**: Your progress is automatically saved every 5 minutes

---

## 📦 Installation

### Requirements

- **Neovim** >= 0.9.0
- **[Volt.nvim](https://github.com/NvChad/volt.nvim)** (UI framework dependency)
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "gisketch/triforce.nvim",
  dependencies = {
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
  requires = { "nvzone/volt" },
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
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `true` | Enable/disable the plugin |
| `gamification_enabled` | `boolean` | `true` | Enable gamification features |
| `notifications.enabled` | `boolean` | `true` | Master toggle for notifications |
| `notifications.level_up` | `boolean` | `true` | Show level up notifications |
| `notifications.achievements` | `boolean` | `true` | Show achievement notifications |
| `auto_save_interval` | `number` | `300` | Auto-save interval in seconds |
| `keymap.show_profile` | `string \| nil` | `nil` | Keymap for opening profile |
| `custom_languages` | `table \| nil` | `nil` | Custom language definitions |
| `level_progression` | `table \| nil` | See below | Custom XP requirements per level tier |

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

---

## 🎮 Usage

### Commands

| Command | Description |
|---------|-------------|
| `:lua require("triforce").show_profile()` | Open the Triforce profile UI |
| `:lua require("triforce").get_stats()` | Get current stats programmatically |
| `:lua require("triforce").reset_stats()` | Reset all stats (useful for testing) |
| `:lua require("triforce").save_stats()` | Force save stats immediately |
| `:lua require("triforce").debug_languages()` | Debug language tracking |

### Profile UI

The profile has **3 tabs**:

1. **📊 Stats Tab**
   - Level progress bar
   - Session/time milestone progress
   - Activity heatmap (7 months)
   - Quick stats overview

2. **🏆 Achievements Tab**
   - View all unlocked achievements
   - See locked achievements with unlock requirements
   - Paginate through achievements (H/L or arrow keys)

3. **💻 Languages Tab**
   - Bar graph showing your most-used languages
   - See character count breakdown by language

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

Stats are saved to:
```
~/.local/share/nvim/triforce_stats.json
```

The file is automatically backed up before each save to:
```
~/.local/share/nvim/triforce_stats.json.bak
```

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

<div align="center">

**Made with ❤️ for the Neovim community**

⭐ Star this repo if you find it useful!

</div>
