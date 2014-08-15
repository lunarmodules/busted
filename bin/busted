#!/usr/bin/env lua
-- Busted command-line runner

local cli = require 'cliargs'
local busted = require 'busted.core'()

local configLoader = require 'busted.modules.configuration_loader'()
local outputHandlerLoader = require 'busted.modules.output_handler_loader'()

local luacov = require 'busted.modules.luacov'()

local path = require 'pl.path'
local utils = require 'pl.utils'

require 'busted.init'(busted)

-- Default cli arg values
local defaultOutput = path.is_windows and 'plainTerminal' or 'utfTerminal'
local defaultLoaders = 'lua,moonscript'
local defaultPattern = '_spec'
local lpathprefix = './src/?.lua;./src/?/?.lua;./src/?/init.lua'
local cpathprefix = path.is_windows and './csrc/?.dll;./csrc/?/?.dll;' or './csrc/?.so;./csrc/?/?.so;'

-- Load up the command-line interface options
cli:set_name('busted')
cli:add_flag('--version', 'prints the program version and exits')

cli:optarg('ROOT', 'test script file/folder. Folders will be traversed for any file that matches the --pattern option.', 'spec', 1)

cli:add_option('-o, --output=LIBRARY', 'output library to load', defaultOutput)
cli:add_option('-d, --cwd=cwd', 'path to current working directory', './')
cli:add_option('-p, --pattern=PATTERN', 'only run test files matching the Lua pattern', defaultPattern)
cli:add_option('-t, --tags=TAGS', 'only run tests with these #tags')
cli:add_option('--exclude-tags=TAGS', 'do not run tests with these #tags, takes precedence over --tags')
cli:add_option('-m, --lpath=PATH', 'optional path to be prefixed to the Lua module search path', lpathprefix)
cli:add_option('--cpath=PATH', 'optional path to be prefixed to the Lua C module search path', cpathprefix)
cli:add_option('-r, --run=RUN', 'config to run from .busted file')
cli:add_option('--lang=LANG', 'language for error messages', 'en')
cli:add_option('--loaders=NAME', 'test file loaders', defaultLoaders)
cli:add_option('--helper=PATH', 'A helper script that is run before tests')

cli:add_flag('-c, --coverage', 'do code coverage analysis (requires `LuaCov` to be installed)')

cli:add_flag('-v, --verbose', 'verbose output of errors')
cli:add_flag('-s, --enable-sound', 'executes `say` command if available')
cli:add_flag('--suppress-pending', 'suppress `pending` test output')
cli:add_flag('--defer-print', 'defer print to when test suite is complete')

-- Parse the cli arguments
local cliArgs, hasError = cli:parse()
if hasError then
  os.exit(1)
end

-- Return early if only asked for the version
if cliArgs.version then
  return print(busted.version)
end

-- Load current working directory
local fpath = cliArgs.d

-- Load busted config file if available
local configFile = { }
local bustedConfigFilePath = path.normpath(path.join(fpath, '.busted'))

local bustedConfigFile = pcall(function() configFile = loadfile(bustedConfigFilePath)() end)

if bustedConfigFile then
  local config, err = configLoader(configFile, cliArgs)

  if err then
    print(err)
  end
end

-- Load test directory
local rootFile = path.normpath(path.join(fpath, cliArgs.ROOT))

local pattern = cliArgs.pattern

local tags = {}
local excludeTags = {}

if cliArgs.t ~= '' then
  tags = utils.split(cliArgs.t, ',')
end

if cliArgs['exclude-tags'] ~= '' then
  excludeTags = utils.split(cliArgs['exclude-tags'], ',')
end

-- If coverage arg is passed in, load LuaCovsupport
if cliArgs.coverage then
  luacov()
end

-- Add additional package paths based on lpath and cpath cliArgs
if #cliArgs.lpath > 0 then
  lpathprefix = cliArgs.lpath
  lpathprefix = lpathprefix:gsub('^%.[/%\\]', fpath )
  lpathprefix = lpathprefix:gsub(';%.[/%\\]', ';' .. fpath)
  package.path = (lpathprefix .. ';' .. package.path):gsub(';;',';')
end

if #cliArgs.cpath > 0 then
  cpathprefix = cliArgs.cpath
  cpathprefix = cpathprefix:gsub('^%.[/%\\]', fpath )
  cpathprefix = cpathprefix:gsub(';%.[/%\\]', ';' .. fpath)
  package.cpath = (cpathprefix .. ';' .. package.cpath):gsub(';;',';')
end

if cliArgs.helper ~= '' then
  dofile(cliArgs.helper)
end

local loaders = {}
if #cliArgs.loaders > 0 then
  string.gsub(cliArgs.loaders, '([^,]+)', function(c) loaders[#loaders+1] = c end)
end

-- We report an error if the same tag appears in both `options.tags`
-- and `options.excluded_tags` because it does not make sense for the
-- user to tell Busted to include and exclude the same tests at the
-- same time.
for _, excluded in pairs(excludeTags) do
  for _, included in pairs(tags) do
    if excluded == included then
      print('Cannot use --tags and --exclude-tags for the same tags')
      os.exit(1)
    end
  end
end

-- Set up output handler to listen to events
local outputHandlerOptions = {
  verbose = cliArgs.verbose,
  suppressPending = cliArgs['suppress-pending'],
  language = cliArgs.lang,
  deferPrint = cliArgs['defer-print']
}

local outputHandler = outputHandlerLoader(cliArgs.output, cliArgs.o, outputHandlerOptions, busted)
outputHandler:subscribe(outputHandlerOptions)

if cliArgs.s then
  require 'busted.outputHandlers.sound'(outputHandlerOptions, busted)
end

local checkTag = function(name, tag, modifier)
  local found = name:find('#' .. tag)
  return (modifier == (found ~= nil))
end

local checkTags = function(name)
  for i, tag in pairs(tags) do
    if not checkTag(name, tag, true) then
      return nil, false
    end
  end

  for i, tag in pairs(excludeTags) do
    if not checkTag(name, tag, false) then
      return nil, false
    end
  end

  return nil, true
end

if cliArgs.t ~= '' or cliArgs['exclude-tags'] ~= '' then
  -- Watch for tags
  busted.subscribe({ 'register', 'it' }, checkTags, { priority = 1 })
  busted.subscribe({ 'register', 'pending' }, checkTags, { priority = 1 })
end

local testFileLoader = require 'busted.modules.test_file_loader'(busted, loaders)
testFileLoader(rootFile, pattern)

-- watch for test errors
local failures = 0
local errors = 0

busted.subscribe({ 'error' }, function(...)
  errors = errors + 1
  return nil, true
end)

busted.subscribe({ 'test', 'end' }, function(element, parent, status)
  if status == 'failure' then
    failures = failures + 1
  end
  return nil, true
end)

busted.publish({ 'suite', 'start' })
busted.execute()
busted.publish({ 'suite', 'end' })

local exit = 0
if failures > 0 or errors > 0 then
  exit = 1
end
os.exit(exit)
