git := require('git')
just := just_executable()
stylua := require('stylua')

set script-interpreter := ['zsh', '+o', 'nomatch', '-eu']
set shell := ['zsh', '+o', 'nomatch', '-ecu']
set positional-arguments := true
set unstable := true

[default]
[private]
@list:
    {{ just }} --list --unsorted

restyle:
    {{ git }} ls-files '*.lua' '*.rockspec' .luacheckrc .luacov | xargs {{ stylua }} --respect-ignores
