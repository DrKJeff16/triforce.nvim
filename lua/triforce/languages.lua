local util = require('triforce.util')

---Language configuration and icons
---@class Triforce.Languages
local Languages = {
  ---Language to icon mapping for popular programming languages
  language_icons = { ---@type table<string, string>
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
    arduino = '', -- nf-dev-arduino
    asm = '', -- nf-seti-asm
    makefile = '', -- nf-seti-makefile
    cmake = '', -- nf-dev-cmake

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
    lisp = '', -- nf-custom-common_lisp

    -- .NET
    cs = '󰌛', -- nf-md-language_csharp
    fsharp = '', -- nf-dev-fsharp

    -- Mobile
    swift = '', -- nf-dev-swift
    dart = '', -- nf-dev-dart

    -- Configuration
    conf = '', -- nf-seti-config
    config = '', -- nf-seti-config
    hyprlang = '', -- nf-linux-hyprland

    -- Shell
    sh = '', -- nf-dev-terminal
    bash = '', -- nf-dev-terminal
    zsh = '', -- nf-dev-terminal
    fish = '', -- nf-dev-terminal
    csh = '', -- nf-dev-terminal

    -- Data
    sql = '', -- nf-dev-database
    json = '', -- nf-seti-json
    yaml = '', -- nf-seti-yaml
    toml = '', -- nf-seti-toml
    xml = '󰗀', -- nf-md-xml

    -- Markup/Doc
    markdown = '', -- nf-dev-markdown
    tex = '', -- nf-seti-tex
    org = '', -- nf-custom-orgmode

    -- Other
    vim = '', -- nf-seti-vim
    r = '', -- nf-dev-r
    julia = '', -- nf-seti-julia
    nim = '', -- nf-seti-nim
    crystal = '', -- nf-seti-crystal
    PKGBUILD = '', -- nf-dev-terminal
  },

  ---Language filetype to display name mapping
  language_display_names = { ---@type table<string, string>
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
    arduino = 'Arduino',
    asm = 'Assembly',
    makefile = 'Makefile',
    cmake = 'CMake',

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
    lisp = 'Common Lisp',

    -- .NET
    cs = 'C#',
    fsharp = 'F#',

    -- Mobile
    swift = 'Swift',
    dart = 'Dart',

    -- Configuration
    conf = 'Conf',
    config = 'Config',
    hyprlang = 'Hyprlang',

    -- Shell
    sh = 'Shell',
    bash = 'Bash',
    zsh = 'Zsh',
    fish = 'Fish',
    csh = 'C Shell',

    -- Data
    sql = 'SQL',
    json = 'JSON',
    yaml = 'YAML',
    toml = 'TOML',
    xml = 'XML',

    -- Markup/Doc
    markdown = 'Markdown',
    tex = 'LaTeX',
    org = 'Org Mode',

    -- Other
    vim = 'Vim',
    r = 'R',
    julia = 'Julia',
    nim = 'Nim',
    crystal = 'Crystal',
    PKGBUILD = 'PKGBUILD',
  },
}

---Get icon for a filetype
---@param filetype string
---@return string icon
function Languages.get_icon(filetype)
  util.validate({ filetype = { filetype, { 'string' } } })

  return Languages.language_icons[filetype] or ''
end

---Check if language should be tracked
---@param filetype string
---@return boolean
function Languages.should_track(filetype)
  util.validate({ filetype = { filetype, { 'string' } } })

  -- Track only if we have an icon for it or if user adds custom mapping
  return Languages.language_icons[filetype] ~= nil
end

---Get display name for language
---@param filetype string
---@return string name
function Languages.get_display_name(filetype)
  util.validate({ filetype = { filetype, { 'string' } } })

  return Languages.language_display_names[filetype] or filetype
end

---Get full display with icon
---@param filetype string
function Languages.get_full_display(filetype)
  util.validate({ filetype = { filetype, { 'string' } } })

  local icon = Languages.get_icon(filetype)
  local name = Languages.get_display_name(filetype)
  return icon == '' and name or ('%s %s'):format(icon, name)
end

---Register custom languages
---@param custom_langs table<string, { icon: string, name: string }>
function Languages.register_custom_languages(custom_langs)
  util.validate({ custom_langs = { custom_langs, { 'table' } } })

  for filetype, config in pairs(custom_langs) do
    if config.icon then
      Languages.language_icons[filetype] = config.icon
    end
    if config.name then
      Languages.language_display_names[filetype] = config.name
    end
  end
end

return Languages
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
