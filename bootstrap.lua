-- Busted command-line runner
package.path = './?.lua;./lib/?.lua;./src/?.lua;'..package.path

local busted = require 'busted'
local cli = require 'cliargs'
local lfs = require 'lfs'

local function sub_dir(dir)
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
  local dirattr = lfs.attributes(dir)
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
cli:add_option("-d, --cwd=cwd", "path to current working directory")

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
    cwd = args["d"],
    output_lib = args["output_lib"],
  })

  if args["version"] then
    return print("busted: version 0.0.0")
  end

  local root_file = args.ROOT or "spec"
  if args["d"] then
    root_file = args["d"]..root_file
  end

  local file = loadfile(root_file)
  if file then
    file()
  else
    for filename,attr in sub_dir(root_file) do
      if attr.mode == 'file' then
        local path,fullname,ext = string.match(filename, "(.-)([^\\]-([^%.]+))$")
        if ext == 'lua' then
          local file, err = loadfile(filename)
          if file then
            file()
          else
            print("An error occurred while loading a test::"..err)
          end
        end
      end
    end
  end

  print(busted().."\n")
end
