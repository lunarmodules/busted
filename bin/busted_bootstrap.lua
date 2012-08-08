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
cli:add_flag("-v", "verbose output of errors")
cli:add_flag("-c, --color", "disable colored output")
cli:add_flag("-j, --json", "json output")
cli:add_flag("-l, --lua", "execution environment")
cli:add_flag("--suppress-pending", "suppress 'pending' tests")
cli:add_flag("--defer-print", "defer print to when test suite is complete (json output does this by default)")

cli:add_flag("--luajit", "<DISPLAY ONLY> Say that you're running luajit. For busted sh script.")
cli:add_flag("--lua", "<DISPLAY ONLY> Say that you're running lua. For busted sh script.")

local args = cli:parse_args()

if args then 
  set_busted_options({
    verbose = args["v"],
    color = not args["c"],
    json = args["j"],
    suppress_pending = args["suppress-pending"],
    defer_print = args["defer-print"] or args["j"],
  })

  if args["version"] then
    return print("test.lua: version 0.0.0")
  end

  if not args["j"] and args["luajit"] then
    print("Running tests with luajit.")
  end

  if not args["j"] and args["lua"] then
    print("Running tests with lua.")
  end

  local rootFile = args.ROOT or nil

  if fileexists(rootFile) then
    loadfile(rootFile)()
  else
    print "No test files found!"
  end

  print(busted().."\n")
end
