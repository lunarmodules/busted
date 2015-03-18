-- Busted command-line runner

local path = require 'pl.path'
local term = require 'term'
local utils = require 'busted.utils'
local osexit = require 'busted.compatibility'.osexit
local loaded = false

return function(options)
  if loaded then return else loaded = true end

  local options = options or {}
  options.defaultOutput = term.isatty(io.stdout) and 'utfTerminal' or 'plainTerminal'

  local busted = require 'busted.core'()

  local cli = require 'busted.modules.cli'(options)
  local filterLoader = require 'busted.modules.filter_loader'()
  local helperLoader = require 'busted.modules.helper_loader'()
  local outputHandlerLoader = require 'busted.modules.output_handler_loader'()

  local luacov = require 'busted.modules.luacov'()

  require 'busted'(busted)

  local level = 2
  local info = debug.getinfo(level, 'Sf')
  local source = info.source
  local fileName = source:sub(1,1) == '@' and source:sub(2) or source

  -- Parse the cli arguments
  local appName = path.basename(fileName)
  cli:set_name(appName)
  local cliArgs, err = cli:parse(arg)
  if not cliArgs then
    io.stderr:write(err .. '\n')
    osexit(1, true)
  end

  if cliArgs.version then
    -- Return early if asked for the version
    print(busted.version)
    osexit(0, true)
  end

  -- Load current working directory
  local _, err = path.chdir(utils.normpath(cliArgs.directory))
  if err then
    io.stderr:write(appName .. ': error: ' .. err .. '\n')
    osexit(1, true)
  end

  -- If coverage arg is passed in, load LuaCovsupport
  if cliArgs.coverage then
    luacov()
  end

  -- If auto-insulate is disabled, re-register file without insulation
  if cliArgs['no-auto-insulate'] then
    busted.register('file', 'file', {})
  end

  -- If lazy is enabled, make lazy setup/teardown the default
  if cliArgs.lazy then
    busted.register('setup', 'lazy_setup')
    busted.register('teardown', 'lazy_teardown')
  end

  -- Add additional package paths based on lpath and cpath cliArgs
  if #cliArgs.lpath > 0 then
    package.path = (cliArgs.lpath .. ';' .. package.path):gsub(';;',';')
  end

  if #cliArgs.cpath > 0 then
    package.cpath = (cliArgs.cpath .. ';' .. package.cpath):gsub(';;',';')
  end

  -- watch for test errors and failures
  local failures = 0
  local errors = 0
  local quitOnError = cliArgs['no-keep-going']

  busted.subscribe({ 'error', 'output' }, function(element, parent, message)
    io.stderr:write(appName .. ': error: Cannot load output library: ' .. element.name .. '\n' .. message .. '\n')
    return nil, true
  end)

  busted.subscribe({ 'error', 'helper' }, function(element, parent, message)
    io.stderr:write(appName .. ': error: Cannot load helper script: ' .. element.name .. '\n' .. message .. '\n')
    return nil, true
  end)

  busted.subscribe({ 'error' }, function(element, parent, message)
    errors = errors + 1
    busted.skipAll = quitOnError
    return nil, true
  end)

  busted.subscribe({ 'failure' }, function(element, parent, message)
    if element.descriptor == 'it' then
      failures = failures + 1
    else
      errors = errors + 1
    end
    busted.skipAll = quitOnError
    return nil, true
  end)

  -- Set up output handler to listen to events
  local outputHandlerOptions = {
    verbose = cliArgs.verbose,
    suppressPending = cliArgs['suppress-pending'],
    language = cliArgs.lang,
    deferPrint = cliArgs['defer-print'],
    arguments = cliArgs.Xoutput
  }

  local outputHandler = outputHandlerLoader(cliArgs.output, outputHandlerOptions, busted, options.defaultOutput)
  outputHandler:subscribe(outputHandlerOptions)

  if cliArgs['enable-sound'] then
    require 'busted.outputHandlers.sound'(outputHandlerOptions, busted)
  end

  -- Set up randomization options
  busted.sort = cliArgs['sort-tests'] or cliArgs.sort
  busted.randomize = cliArgs['shuffle-tests'] or cliArgs.shuffle
  busted.randomseed = tonumber(cliArgs.seed) or os.time()

  -- Set up tag and test filter options
  local filterLoaderOptions = {
    tags = cliArgs.tags,
    excludeTags = cliArgs['exclude-tags'],
    filter = cliArgs.filter,
    filterOut = cliArgs['filter-out'],
    list = cliArgs.list,
    nokeepgoing = cliArgs['no-keep-going'],
  }

  -- Load tag and test filters
  filterLoader(filterLoaderOptions, busted)

  -- Set up helper script
  if cliArgs.helper and cliArgs.helper ~= '' then
    local helperOptions = {
      verbose = cliArgs.verbose,
      language = cliArgs.lang,
      arguments = cliArgs.Xhelper
    }

    helperLoader(cliArgs.helper, helperOptions, busted)
  end

  -- Set up test loader options
  local testFileLoaderOptions = {
    verbose = cliArgs.verbose,
    sort = cliArgs['sort-files'] or cliArgs.sort,
    shuffle = cliArgs['shuffle-files'] or cliArgs.shuffle,
    recursive = not cliArgs['no-recursive'],
    seed = busted.randomseed
  }

  -- Load test directory
  local rootFiles = cliArgs.ROOT or { fileName }
  local pattern = cliArgs.pattern
  local testFileLoader = require 'busted.modules.test_file_loader'(busted, cliArgs.loaders, testFileLoaderOptions)
  local fileList = testFileLoader(rootFiles, pattern)

  if not cliArgs.ROOT then
    local ctx = busted.context.get()
    local file = busted.context.children(ctx)[1]
    getmetatable(file.run).__call = info.func
  end

  local runs = cliArgs['repeat']
  local execute = require 'busted.execute'(busted)
  execute(runs, { seed = cliArgs.seed })

  busted.publish({ 'exit' })

  local exit = 0
  if failures > 0 or errors > 0 then
    exit = failures + errors
    if exit > 255 then
      exit = 255
    end
  end
  osexit(exit, true)
end
