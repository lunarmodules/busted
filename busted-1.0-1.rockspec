package = "busted"
version = "1.0-1"
source = {
  url = "https://github.com/Olivine-Labs/busted"
}
description = {
  summary = "A command line testing suite for lua",
  detailed = [[
    An elegant, extensible, testing framework.
  ]],
  homepage = "http://olivinelabs.com/busted/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1",
  "lua_cliargs >= 1.1",
  "luafilesystem >= 1.5.0",
  "dkjson >= 2.1.0"
}
build = {
  type = "builtin",
   modules = {
    busted = "busted.lua"
  }
}
