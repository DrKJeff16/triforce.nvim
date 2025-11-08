-- Luacheck configuration for static analysis
-- Run with: luacheck .

-- Set standard to maximum (includes Lua 5.1-5.4 features)
std = "luajit"

-- Allow global variables from Neovim API
globals = {
  "vim",
}

-- Read-only global variables
read_globals = {
  "vim",
}

-- Ignore specific warnings
ignore = {
  "212", -- Unused argument (common in Neovim callbacks)
  "631", -- Line is too long (we have formatters for this)
}

-- Exclude directories
exclude_files = {
  ".luarocks/",
  "lua_modules/",
}
