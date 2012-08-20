package = "busted"
version = "1.0-1"
source = {
  url = "https://github.com/downloads/Olivine-Labs/busted/busted-1.0.tar.gz"
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
  "lua_cliargs >= 1.1",
  "luafilesystem >= 1.5.0",
  "dkjson >= 2.1.0"
}
build = {
  type = "builtin",
  modules = {
    busted = "busted.lua",
    ["luassert.util"] = "lib/luassert/util.lua",
    ["luassert.spy"] = "lib/luassert/spy.lua",
    ["luassert.stub"] = "lib/luassert/stub.lua",
    ["luassert.assert"] = "lib/luassert/assert.lua",
    ["luassert.modifiers"] = "lib/luassert/modifiers.lua",
    ["luassert.assertions"] = "lib/luassert/assertions.lua",
    ["luassert.mock"] = "lib/luassert/mock.lua",
    ["say.s"] = "lib/say/s.lua",
    ["lib.ansicolors"] = "lib/ansicolors.lua",
    ["output.utf_terminal"] = "src/output/utf_terminal.lua",
    ["output.plain_terminal"] = "src/output/plain_terminal.lua",
    ["output.TAP"] = "src/output/TAP.lua",
    ["output.json"] = "src/output/json.lua",
  },
  install = {
    bin = {
      ["busted"] = "busted",
      ["busted.bat"] = "busted.bat",
      ["bootstrap"] = "bootstrap",
    }
  }
}
