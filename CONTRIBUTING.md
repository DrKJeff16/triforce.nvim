# Contributing

Contributions are welcome! You will find here a set of guidelines for you.

## Guidelines

> [!IMPORTANT]
> For step No.3 please format your plugins following the [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/)!

1. Fork the repository
2. Create a feature branch:
  ```bash
  git checkout -b feature/amazing-feature
  ```
3. Commit your changes:
  ```bash
  git commit -m 'feat(scope): add amazing feature'
  ```
4. Push to the branch:
  ```bash
  git push origin feature/amazing-feature
  ```
5. Open a Pull Request

---

## Development

### lazy.nvim

If you're using `lazy.nvim` you can clone your fork in a selected directory,
then set the `dev = true` option in your installation:

```lua
require('lazy').setup({
  spec = {
    -- ...
    {
      'gisketch/triforce.nvim',
      dev = true, --- Flag needed!
      dependencies = { 'nvzone/volt' },
      config = function()
        require('triforce').setup()
      end,
    },
  },

  -- ...

  dev = { path = '/path/to/directory' },
})
```

### With Symlinks

```bash
# Clone the repo
git clone https://github.com/gisketch/triforce.nvim.git
cd triforce.nvim

# Symlink to Neovim config for testing
ln -s "$(pwd)" ~/.local/share/nvim/site/pack/plugins/start/triforce.nvim
```

<!-- vim: set ts=2 sts=2 sw=2 et ai si sta: -->
