-- Busted command-line runner

--dirname function to get current directory
--this allows us to be location agnostic
local function dirname(f)
  if not f then f=arg and arg[0] or "./" end
  return string.gsub(f,"(.*/).*","%1")
end

package.path = dirname()..'../?.lua;'..package.path

local busted = require 'busted'
local cli = require 'cliargs'
local lfs = require 'lfs'

function dirtree(dir)
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        entry=dir.."/"..entry
        local attr=lfs.attributes(entry)
        coroutine.yield(entry,attr)
        if attr.mode == "directory" then
          yieldtree(entry)
        end
      end
    end
  end

  return coroutine.wrap(function() yieldtree(dir) end)
end

cli:set_name("busted")
cli:add_arg("ROOT", "test script file/folder")
cli:add_flag("--version", "prints the program's version and exits")
cli:add_option("-v", "verbose output of errors")
cli:add_option("-c, --color", "disable colored output")
cli:add_option("-j, --json", "json output")
cli:add_option("-l, --lua=luajit", "path to the execution environment", nil, "luajit")

local args = cli:parse_args()
if args then
  if args["version"] then
    return print("busted: version 0.0.0")
  end

  local rootFile = args.ROOT or nil
  local found = false
  for filename,attr in dirtree(rootFile) do
    if attr.mode == 'file' then
      local file = loadfile(filename)
      if file then
        file()
        found = true
      end
    end
  end

  if not found then
    loadfile(rootFile)()
  end

  print(busted({
    verbose = args["v"] ~= "",
    color = args["c"] == "",
    json = args["j"] ~= "",
  }))
end
