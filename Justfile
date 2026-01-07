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

# release
#    - pass tests
#    - edit action and core with version
#    - generate new rockspec, like old but with any diffs from scm
#    - export SEMVER=v2.x.y
#    - git commit -m "chore: Release v$SEMVER"
#    - git cliff --unreleased >> notes
#    - git tag v$SEMVER -a (edit in notes)
#    - g push upstream master --follow-tags
#    - luarocks make --pack-binary-rock rockspecs/busted-$SEMVER-1.rockspec
#    - luarocks pack !$
#    - gh release (from tag commit plus pings)
