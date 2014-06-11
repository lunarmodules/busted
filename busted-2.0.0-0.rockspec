package = 'busted'
version = '2.0.0-0'
source = {
  url = 'https://github.com/Olivine-Labs/busted/archive/v2.0.0.tar.gz',
  dir = 'busted-2.0.0'
}
description = {
  summary = 'Elegant Lua unit testing.',
  detailed = [[
    An elegant, extensible, testing framework.
    Ships with a large amount of useful asserts,
    plus the ability to write your own. Output
    in pretty or plain terminal format, JSON,
    or TAP for CI integration. Great for TDD
    and unit, integration, and functional tests.
  ]],
  homepage = 'http://olivinelabs.com/busted/',
  license = 'MIT <http://opensource.org/licenses/MIT>'
}
dependencies = {
  'lua >= 5.1',
  'lua_cliargs >= 2.0',
  'luafilesystem >= 1.5.0',
  'dkjson >= 2.1.0',
  'say >= 1.2-1',
  'luassert >= 1.7.0-0',
  'ansicolors >= 1.0-1',
  'penlight >= 1.0.0-1',
  'mediator_lua >= 1.1-3',
}
build = {
  type = 'builtin',
  modules = {
    ['busted.core']                           = 'src/core.lua',
    ['busted.context']                        = 'src/context.lua',
    ['busted.environment']                    = 'src/environment.lua',
    ['busted.compatibility']                  = 'src/compatibility.lua',
    ['busted.done']                           = 'src/done.lua',
    ['busted.init']                           = 'src/init.lua',

    ['busted.modules.configuration_loader']   = 'src/modules/configuration_loader.lua',
    ['busted.modules.luacov']                 = 'src/modules/luacov.lua',
    ['busted.modules.test_file_loader']       = 'src/modules/test_file_loader.lua',
    ['busted.modules.output_handler_loader']  = 'src/modules/output_handler_loader.lua',

    ['busted.modules.files.lua']              = 'src/modules/files/lua.lua',
    ['busted.modules.files.moonscript']       = 'src/modules/files/moonscript.lua',
    ['busted.modules.files.terra']            = 'src/modules/files/terra.lua',

    ['busted.outputHandlers.utfTerminal']    = 'src/outputHandlers/utfTerminal.lua',
    ['busted.outputHandlers.plainTerminal']  = 'src/outputHandlers/plainTerminal.lua',
    ['busted.outputHandlers.TAP']            = 'src/outputHandlers/TAP.lua',
    ['busted.outputHandlers.json']           = 'src/outputHandlers/json.lua',

    ['busted.languages.en']                   = 'src/languages/en.lua',
    ['busted.languages.ar']                   = 'src/languages/ar.lua',
    ['busted.languages.de']                   = 'src/languages/de.lua',
    ['busted.languages.fr']                   = 'src/languages/fr.lua',
    ['busted.languages.ja']                   = 'src/languages/ja.lua',
    ['busted.languages.nl']                   = 'src/languages/nl.lua',
    ['busted.languages.ru']                   = 'src/languages/ru.lua',
    ['busted.languages.th']                   = 'src/languages/th.lua',
    ['busted.languages.ua']                   = 'src/languages/ua.lua',
    ['busted.languages.zh']                   = 'src/languages/zh.lua',
  },
  install = {
    bin = {
      ['busted'] = 'bin/busted'
    }
  }
}
