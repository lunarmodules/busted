-- Busted command-line runner

--dirname function to get current directory
--this allows us to be location agnostic
local function dirname(f)
  if not f then f=arg[0] end
  return string.gsub(f,"(.*/).*","%1")
end

function fileexists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

package.path = dirname()..'../?.lua;'..package.path

local busted = require 'busted'
local cli = require("cliargs")

cli:set_name("test")
cli:add_argument("ROOT", "test script file")
cli:add_flag("--version", "prints the program's version and exits")
cli:add_option("-v", "verbose output of errors")
cli:add_option("-c, --color", "disable colored output")
cli:add_option("-j, --json", "json output")
cli:add_option("-l, --lua", "execution environment")

local args = cli:parse_args()

if args then 
  if args["version"] then
    return print("test.lua: version 0.0.0")
  end
  local rootFile = args.ROOT or nil
  if fileexists(rootFile) then
    loadfile(rootFile)()
  else
    print "No test files found!"
  end

  print(busted({
    verbose = args["v"] ~= "",
    color = args["c"] == "",
    json = args["j"] ~= "",
  }))
end
