-- Busted command-line runner

--dirname function to get current directory
--this allows us to be location agnostic
local function dirname(f)
  if not f then f=arg and arg[0] or "./" end
  return string.gsub(f,"(.*/).*","%1")
end
local dirname = dirname()

package.path = dirname..'../?.lua;'..dirname..'../lib/?.lua;'..dirname..'../src/?.lua;'..package.path

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
  dirattr = lfs.attributes(dir)
  if dirattr and dirattr.mode == "directory" then
    return coroutine.wrap(function() yieldtree(dir) end)
  else
    return function() end
  end
end

cli:set_name("busted")
cli:add_flag("--version", "prints the program's version and exits")

cli:add_argument("ROOT", "test script file/folder")

cli:add_option("-o, --output=LIBRARY", "output library to load", "output_lib", "utf_terminal")
cli:add_option("-l, --lua=luajit", "path to the execution environment (lua or luajit)")

cli:add_flag("-v", "verbose output of errors")
cli:add_flag("-s, --enable-sound", "executes 'say' command if available")
cli:add_flag("--suppress-pending", "suppress 'pending' test output")
cli:add_flag("--defer-print", "defer print to when test suite is complete")


local args = cli:parse_args()

if args then
  set_busted_options({
    verbose = args["v"],
    color = not args["c"],
    json = args["j"],
    suppress_pending = args["suppress-pending"],
    defer_print = args["defer-print"],
    utf = not args["u"],
    sound = args["s"],
    output_lib = args["output_lib"],
  })

  if args["version"] then
    return print("busted: version 0.0.0")
  end

  local rootFile = args.ROOT or "./spec"
  local found = false

  for filename,attr in dirtree(rootFile) do
    if attr.mode == 'file' then
      local path,derp,ext = string.match(filename, "(.-)([^\\]-([^%.]+))$")
      if ext == 'lua' then
        local file, err = loadfile(filename)
        if file then
          file()
          found = true
        else
          print("Error during test load::"..err)
        end
      end
    end
  end

  if not found then
    local file = loadfile(rootFile)
    if file then
      file()
    end
  end

  print(busted().."\n")
end
