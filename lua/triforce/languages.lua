---Language configuration and icons
---@class Triforce.Languages
local M = {}

---Language to icon mapping for popular programming languages
---@type table<string, string>
M.language_icons = {
  -- Web
  javascript = '', -- nf-dev-javascript
  typescript = '', -- nf-seti-typescript
  typescriptreact = '', -- nf-dev-react
  javascriptreact = '', -- nf-dev-react
  html = '', -- nf-dev-html5
  css = '', -- nf-dev-css3
  scss = '', -- nf-dev-sass
  sass = '', -- nf-dev-sass
  less = '', -- nf-dev-less
  vue = '', -- nf-seti-vue
  svelte = '', -- nf-seti-svelte

  -- Systems
  c = '', -- nf-seti-c
  cpp = '', -- nf-seti-cpp
  rust = '', -- nf-dev-rust
  go = '', -- nf-seti-go
  zig = '', -- nf-seti-zig

  -- Scripting
  python = '', -- nf-dev-python
  ruby = '', -- nf-dev-ruby
  php = '', -- nf-dev-php
  perl = '', -- nf-dev-perl
  lua = '', -- nf-seti-lua

  -- JVM
  java = '', -- nf-dev-java
  kotlin = '', -- nf-seti-kotlin
  scala = '', -- nf-dev-scala

  -- Functional
  haskell = '', -- nf-seti-haskell
  ocaml = '', -- nf-seti-ocaml
  elixir = '', -- nf-seti-elixir
  erlang = '', -- nf-dev-erlang
  clojure = '', -- nf-dev-clojure

  -- .NET
  cs = '󰌛', -- nf-md-language_csharp
  fsharp = '', -- nf-dev-fsharp

  -- Mobile
  swift = '', -- nf-dev-swift
  dart = '', -- nf-dev-dart

  -- Shell
  sh = '', -- nf-dev-terminal
  bash = '', -- nf-dev-terminal
  zsh = '', -- nf-dev-terminal
  fish = '', -- nf-dev-terminal

  -- Data
  sql = '', -- nf-dev-database
  json = '', -- nf-seti-json
  yaml = '', -- nf-seti-yaml
  toml = '', -- nf-seti-toml
  xml = '󰗀', -- nf-md-xml

  -- Markup/Doc
  markdown = '', -- nf-dev-markdown
  tex = '', -- nf-seti-tex

  -- Other
  vim = '', -- nf-seti-vim
  r = '󰟔', -- nf-md-language_r
  julia = '', -- nf-seti-julia
  nim = '', -- nf-seti-nim
  crystal = '', -- nf-seti-crystal
}

---Get icon for a filetype
---@param filetype string
---@return string icon
function M.get_icon(filetype)
  return M.language_icons[filetype] or ''
end

---Check if language should be tracked
---@param filetype string
---@return boolean
function M.should_track(filetype)
  -- Track only if we have an icon for it or if user adds custom mapping
  return M.language_icons[filetype] ~= nil
end

---Language filetype to display name mapping
---@type table<string, string>
M.language_display_names = {
  -- Web
  javascript = 'JavaScript',
  typescript = 'TypeScript',
  typescriptreact = 'TypeScript',
  javascriptreact = 'JavaScript',
  html = 'HTML',
  css = 'CSS',
  scss = 'SCSS',
  sass = 'Sass',
  less = 'Less',
  vue = 'Vue',
  svelte = 'Svelte',

  -- Systems
  c = 'C',
  cpp = 'C++',
  rust = 'Rust',
  go = 'Go',
  zig = 'Zig',

  -- Scripting
  python = 'Python',
  ruby = 'Ruby',
  php = 'PHP',
  perl = 'Perl',
  lua = 'Lua',

  -- JVM
  java = 'Java',
  kotlin = 'Kotlin',
  scala = 'Scala',

  -- Functional
  haskell = 'Haskell',
  ocaml = 'OCaml',
  elixir = 'Elixir',
  erlang = 'Erlang',
  clojure = 'Clojure',

  -- .NET
  cs = 'C#',
  fsharp = 'F#',

  -- Mobile
  swift = 'Swift',
  dart = 'Dart',

  -- Shell
  sh = 'Shell',
  bash = 'Bash',
  zsh = 'Zsh',
  fish = 'Fish',

  -- Data
  sql = 'SQL',
  json = 'JSON',
  yaml = 'YAML',
  toml = 'TOML',
  xml = 'XML',

  -- Markup/Doc
  markdown = 'Markdown',
  tex = 'LaTeX',

  -- Other
  vim = 'Vim',
  r = 'R',
  julia = 'Julia',
  nim = 'Nim',
  crystal = 'Crystal',
}

---Get display name for language
---@param filetype string
function M.get_display_name(filetype)
  return M.language_display_names[filetype] or filetype
end

---Get full display with icon
---@param filetype string
function M.get_full_display(filetype)
  local icon = M.get_icon(filetype)
  local name = M.get_display_name(filetype)
  if icon ~= '' then
    return icon .. ' ' .. name
  end
  return name
end

---Register custom languages
---@param custom_langs table<string, { icon: string, name: string }>
function M.register_custom_languages(custom_langs)
  for filetype, config in pairs(custom_langs) do
    if config.icon then
      M.language_icons[filetype] = config.icon
    end
    if config.name then
      M.language_display_names[filetype] = config.name
    end
  end
end

return M
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
