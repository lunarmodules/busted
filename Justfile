git := require('git')
just := just_executable()
luarocks := require('luarocks')
stylua := require('stylua')
zsh := "zsh"
[private]
_zsh := require(zsh)

set script-interpreter := [zsh, '+o', 'nomatch', '-eu']
set shell := [zsh, '+o', 'nomatch', '-ecu']
set positional-arguments := true
set unstable := true

local_tree := "--tree lua_modules"

[default]
[private]
@list:
    {{ just }} --list --unsorted

[private]
_setup:
    {{ luarocks }} {{ local_tree }} make

[script]
check: _setup
    eval $({{ luarocks }} {{ local_tree }} path)
    busted -c -v .

restyle:
    {{ git }} ls-files '*.lua' '*.rockspec' .luacheckrc .luacov | xargs {{ stylua }} --respect-ignores
