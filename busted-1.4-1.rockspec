package = "busted"
version = "1.4-1"
source = {
  url = "https://github.com/downloads/Olivine-Labs/busted/busted-1.4.tar.gz",
  dir = "busted"
}
description = {
  summary = "Elegant Lua unit testing.",
  detailed = [[
    An elegant, extensible, testing framework.
    Ships with a large amount of useful asserts,
    plus the ability to write your own. Output
    in pretty or plain terminal format, JSON,
    or TAP for CI integration.
  ]],
  homepage = "http://olivinelabs.com/busted/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1",
  "lua_cliargs >= 2.0",
  "luafilesystem >= 1.5.0",
  "dkjson >= 2.1.0",
  "say >= 1.2-1",
  "luassert >= 1.4-1",
  "ansicolors >= 1.0-1"
}
build = {
  type = "builtin",
  modules = {
    ["busted.core"] = "src/core.lua",
    ["busted.output.utf_terminal"] = "src/output/utf_terminal.lua",
    ["busted.output.plain_terminal"] = "src/output/plain_terminal.lua",
    ["busted.output.TAP"] = "src/output/TAP.lua",
    ["busted.output.json"] = "src/output/json.lua",
    ["busted.init"] = "src/init.lua",
    ["busted.languages.en"] = "src/languages/en.lua",
    ["busted.languages.ar"] = "src/languages/ar.lua",
    ["busted.languages.fr"] = "src/languages/fr.lua",
    ["busted.languages.nl"] = "src/languages/nl.lua",
    ["busted.languages.ru"] = "src/languages/ru.lua",
    ["busted.languages.ua"] = "src/languages/ua.lua",
  },
  install = {
    bin = {
      ["busted"] = "bin/busted",
      ["busted.bat"] = "bin/busted.bat",
      ["busted_bootstrap"] = "bin/busted_bootstrap"
    }
  }
}
