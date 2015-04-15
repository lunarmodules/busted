package = 'busted'
version = 'scm-0'
source = {
  url = "git://github.com/Olivine-Labs/busted",
  branch = "master"
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
  'lua_cliargs >= 2.5-0',
  'luafilesystem >= 1.5.0',
  'dkjson >= 2.1.0',
  'say >= 1.3-0',
  'luassert >= 1.7.6-0',
  'lua-term >= 0.1-1',
  'penlight >= 1.3.2-2',
  'mediator_lua >= 1.1.1-0',
  'luasocket >= 2.0.1'
}
build = {
  type = 'builtin',
  modules = {
    ['busted.core']                           = 'busted/core.lua',
    ['busted.context']                        = 'busted/context.lua',
    ['busted.environment']                    = 'busted/environment.lua',
    ['busted.compatibility']                  = 'busted/compatibility.lua',
    ['busted.done']                           = 'busted/done.lua',
    ['busted.runner']                         = 'busted/runner.lua',
    ['busted.status']                         = 'busted/status.lua',
    ['busted.utils']                          = 'busted/utils.lua',
    ['busted.block']                          = 'busted/block.lua',
    ['busted.execute']                        = 'busted/execute.lua',
    ['busted.init']                           = 'busted/init.lua',

    ['busted.modules.configuration_loader']   = 'busted/modules/configuration_loader.lua',
    ['busted.modules.luacov']                 = 'busted/modules/luacov.lua',
    ['busted.modules.test_file_loader']       = 'busted/modules/test_file_loader.lua',
    ['busted.modules.output_handler_loader']  = 'busted/modules/output_handler_loader.lua',
    ['busted.modules.helper_loader']          = 'busted/modules/helper_loader.lua',
    ['busted.modules.filter_loader']          = 'busted/modules/filter_loader.lua',
    ['busted.modules.cli']                    = 'busted/modules/cli.lua',

    ['busted.modules.files.lua']              = 'busted/modules/files/lua.lua',
    ['busted.modules.files.moonscript']       = 'busted/modules/files/moonscript.lua',
    ['busted.modules.files.terra']            = 'busted/modules/files/terra.lua',

    ['busted.outputHandlers.base']            = 'busted/outputHandlers/base.lua',
    ['busted.outputHandlers.utfTerminal']     = 'busted/outputHandlers/utfTerminal.lua',
    ['busted.outputHandlers.plainTerminal']   = 'busted/outputHandlers/plainTerminal.lua',
    ['busted.outputHandlers.TAP']             = 'busted/outputHandlers/TAP.lua',
    ['busted.outputHandlers.json']            = 'busted/outputHandlers/json.lua',
    ['busted.outputHandlers.junit']           = 'busted/outputHandlers/junit.lua',
    ['busted.outputHandlers.gtest']           = 'busted/outputHandlers/gtest.lua',
    ['busted.outputHandlers.sound']           = 'busted/outputHandlers/sound.lua',

    ['busted.languages.en']                   = 'busted/languages/en.lua',
    ['busted.languages.ar']                   = 'busted/languages/ar.lua',
    ['busted.languages.de']                   = 'busted/languages/de.lua',
    ['busted.languages.es']                   = 'busted/languages/es.lua',
    ['busted.languages.fr']                   = 'busted/languages/fr.lua',
    ['busted.languages.ja']                   = 'busted/languages/ja.lua',
    ['busted.languages.nl']                   = 'busted/languages/nl.lua',
    ['busted.languages.ru']                   = 'busted/languages/ru.lua',
    ['busted.languages.th']                   = 'busted/languages/th.lua',
    ['busted.languages.ua']                   = 'busted/languages/ua.lua',
    ['busted.languages.zh']                   = 'busted/languages/zh.lua',
  },
  install = {
    bin = {
      ['busted'] = 'bin/busted'
    }
  }
}
