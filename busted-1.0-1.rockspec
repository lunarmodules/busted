package = "test_command_line"
version = "1.0-1"
source = {
  url = ""
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
  "lua >= 5.1"
}
build = {
  type = "builtin",
   modules = {
    test_command_line = "test_command_line.lua"
  }
}
