---@class TriforceLanguage
---@field name string
---@field icon string

local util = require('triforce.util')

---Language configuration and icons
---@class Triforce.Languages
local Languages = {
  ---Mappings for popular programming languages, in `{ name, icon }` tuples
  langs = { ---@type table<string, TriforceLanguage>
    -- Web
    javascript = { name = 'JavaScript', icon = '' }, -- nf-dev-javascript
    typescript = { name = 'TypeScript', icon = '' }, -- nf-seti-typescript
    typescriptreact = { icon = '', name = 'TypeScript' }, -- nf-dev-react
    javascriptreact = { name = 'JavaScript', icon = '' }, -- nf-dev-react
    html = { name = 'HTML', icon = '' }, -- nf-dev-html5
    css = { name = 'CSS', icon = '' }, -- nf-dev-css3
    scss = { name = 'SCSS', icon = '' }, -- nf-dev-sass
    sass = { name = 'Sass', icon = '' }, -- nf-dev-sass
    less = { name = 'Less', icon = '' }, -- nf-dev-less
    vue = { name = 'Vue', icon = '' }, -- nf-seti-vue
    svelte = { name = 'Svelte', icon = '' }, -- nf-seti-svelte

    -- Systems
    c = { name = 'C', icon = '' }, -- nf-seti-c
    cpp = { name = 'C++', icon = '' }, -- nf-seti-cpp
    rust = { name = 'Rust', icon = '' }, -- nf-dev-rust
    go = { name = 'Go', icon = '' }, -- nf-seti-go
    zig = { name = 'Zig', icon = '' }, -- nf-seti-zig
    arduino = { name = 'Arduino', icon = '' }, -- nf-dev-arduino
    asm = { name = 'Assembly', icon = '' }, -- nf-seti-asm
    makefile = { name = 'Makefile', icon = '' }, -- nf-seti-makefile
    cmake = { name = 'CMake', icon = '' }, -- nf-dev-cmake

    -- Scripting
    python = { name = 'Python', icon = '' }, -- nf-dev-python
    ruby = { name = 'Ruby', icon = '' }, -- nf-dev-ruby
    php = { name = 'PHP', icon = '' }, -- nf-dev-php
    perl = { name = 'Perl', icon = '' }, -- nf-dev-perl
    lua = { name = 'Lua', icon = '' }, -- nf-seti-lua

    -- JVM
    java = { name = 'Java', icon = '' }, -- nf-dev-java
    kotlin = { name = 'Kotlin', icon = '' }, -- nf-seti-kotlin
    scala = { name = 'Scala', icon = '' }, -- nf-dev-scala

    -- Functional
    haskell = { name = 'Haskell', icon = '' }, -- nf-seti-haskell
    ocaml = { name = 'OCaml', icon = '' }, -- nf-seti-ocaml
    elixir = { name = 'Elixir', icon = '' }, -- nf-seti-elixir
    erlang = { name = 'Erlang', icon = '' }, -- nf-dev-erlang
    clojure = { name = 'Clojure', icon = '' }, -- nf-dev-clojure
    lisp = { name = 'Common Lisp', icon = '' }, -- nf-custom-common_lisp

    -- .NET
    cs = { name = 'C#', icon = '󰌛' }, -- nf-md-language_csharp
    fsharp = { name = 'F#', icon = '' }, -- nf-dev-fsharp

    -- Mobile
    swift = { name = 'Swift', icon = '' }, -- nf-dev-swift
    dart = { name = 'Dart', icon = '' }, -- nf-dev-dart

    -- Configuration
    conf = { name = 'Conf', icon = '' }, -- nf-seti-config
    config = { name = 'Config', icon = '' }, -- nf-seti-config
    hyprlang = { name = 'Hyprlang', icon = '' }, -- nf-linux-hyprland

    -- Shell
    sh = { name = 'Shell', icon = '' }, -- nf-dev-terminal
    bash = { name = 'Bash', icon = '' }, -- nf-dev-terminal
    zsh = { name = 'Zsh', icon = '' }, -- nf-dev-terminal
    fish = { name = 'Fish', icon = '' }, -- nf-dev-terminal
    csh = { name = 'C Shell', icon = '' }, -- nf-dev-terminal

    -- Data
    sql = { name = 'SQL', icon = '' }, -- nf-dev-database
    json = { name = 'JSON', icon = '' }, -- nf-seti-json
    yaml = { name = 'YAML', icon = '' }, -- nf-seti-yaml
    toml = { name = 'TOML', icon = '' }, -- nf-seti-toml
    xml = { name = 'XML', icon = '󰗀' }, -- nf-md-xml

    -- Markup/Doc
    markdown = { name = 'Markdown', icon = '' }, -- nf-dev-markdown
    tex = { name = 'LaTeX', icon = '' }, -- nf-seti-tex
    org = { name = 'Org Mode', icon = '' }, -- nf-custom-orgmode

    -- Other
    vim = { name = 'Vimscript', icon = '' }, -- nf-seti-vim
    r = { name = 'R', icon = '' }, -- nf-dev-r
    julia = { name = 'Julia', icon = '' }, -- nf-seti-julia
    nim = { name = 'Nim', icon = '' }, -- nf-seti-nim
    crystal = { name = 'Crystal', icon = '' }, -- nf-seti-crystal
    PKGBUILD = { name = 'PKGBUILD', icon = '' }, -- nf-dev-terminal
  },
}

---Get icon for a filetype
---@param ft string
---@return string icon
function Languages.get_icon(ft)
  util.validate({ ft = { ft, { 'string' } } })

  if not Languages.langs[ft] then
    return ''
  end

  return Languages.langs[ft].icon or ''
end

---Check if language should be tracked
---@param ft string
---@return boolean
function Languages.should_track(ft)
  util.validate({ ft = { ft, { 'string' } } })

  -- Track only if we have an icon for it or if user adds custom mapping
  return Languages.langs[ft] ~= nil and Languages.langs[ft].icon ~= nil
end

---Get display name for language
---@param ft string
---@return string name
function Languages.get_display_name(ft)
  util.validate({ ft = { ft, { 'string' } } })

  if not Languages.langs[ft] then
    return ''
  end

  return Languages.langs[ft].name or ft
end

---Get full display with icon
---@param ft string
function Languages.get_full_display(ft)
  util.validate({ ft = { ft, { 'string' } } })

  local icon = Languages.get_icon(ft)
  local name = Languages.get_display_name(ft)
  return icon == '' and name or ('%s %s'):format(icon, name)
end

---Register custom languages
---@param custom_langs table<string, TriforceLanguage>
function Languages.register_custom_languages(custom_langs)
  util.validate({ custom_langs = { custom_langs, { 'table' } } })

  if not custom_langs or vim.tbl_isempty(custom_langs) then
    return
  end

  for ft, config in pairs(custom_langs) do
    if not Languages.langs[ft] then
      Languages.langs[ft] = { icon = '', name = '' }
    end

    if config.icon then
      Languages.langs[ft].icon = config.icon
    end
    if config.name then
      Languages.langs[ft].name = config.name
    end
  end
end

return Languages
-- vim:ts=2:sts=2:sw=2:et:ai:si:sta:
