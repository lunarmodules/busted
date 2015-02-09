-- Busted command-line runner

local getfenv = require 'busted.compatibility'.getfenv
local setfenv = require 'busted.compatibility'.setfenv
local path = require 'pl.path'
local utils = require 'busted.utils'
local loaded = false

return function(options)
  if loaded then return else loaded = true end

  local opt = options or {}
  local isBatch = opt.batch
  local cli = require 'cliargs'
  local busted = require 'busted.core'()

  local configLoader = require 'busted.modules.configuration_loader'()
  local outputHandlerLoader = require 'busted.modules.output_handler_loader'()

  local luacov = require 'busted.modules.luacov'()

  require 'busted'(busted)

  -- Default cli arg values
  local defaultOutput = path.is_windows and 'plainTerminal' or 'utfTerminal'
  local defaultLoaders = 'lua,moonscript'
  local defaultPattern = '_spec'
  local defaultSeed = 'os.time()'
  local lpathprefix = './src/?.lua;./src/?/?.lua;./src/?/init.lua'
  local cpathprefix = path.is_windows and './csrc/?.dll;./csrc/?/?.dll;' or './csrc/?.so;./csrc/?/?.so;'

  local level = 2
  local info = debug.getinfo(level, 'Sf')
  local source = info.source
  local fileName = source:sub(1,1) == '@' and source:sub(2) or source

  -- Load up the command-line interface options
  cli:set_name(path.basename(fileName))
  cli:add_flag('--version', 'prints the program version and exits')

  if isBatch then
    cli:optarg('ROOT', 'test script file/folder. Folders will be traversed for any file that matches the --pattern option.', 'spec', 1)

    cli:add_option('-p, --pattern=PATTERN', 'only run test files matching the Lua pattern', defaultPattern)
  end

  cli:add_option('-o, --output=LIBRARY', 'output library to load', defaultOutput)
  cli:add_option('-d, --cwd=cwd', 'path to current working directory', './')
  cli:add_option('-t, --tags=TAGS', 'only run tests with these #tags')
  cli:add_option('--exclude-tags=TAGS', 'do not run tests with these #tags, takes precedence over --tags')
  cli:add_option('--filter=PATTERN', 'only run test names matching the Lua pattern')
  cli:add_option('--filter-out=PATTERN', 'do not run test names matching the Lua pattern, takes precedence over --filter')
  cli:add_option('-m, --lpath=PATH', 'optional path to be prefixed to the Lua module search path', lpathprefix)
  cli:add_option('--cpath=PATH', 'optional path to be prefixed to the Lua C module search path', cpathprefix)
  cli:add_option('-r, --run=RUN', 'config to run from .busted file')
  cli:add_option('--repeat=COUNT', 'run the tests repeatedly', '1')
  cli:add_option('--seed=SEED', 'random seed value to use for shuffling test order', defaultSeed)
  cli:add_option('--lang=LANG', 'language for error messages', 'en')
  cli:add_option('--loaders=NAME', 'test file loaders', defaultLoaders)
  cli:add_option('--helper=PATH', 'A helper script that is run before tests')

  cli:add_flag('-c, --coverage', 'do code coverage analysis (requires `LuaCov` to be installed)')
  cli:add_flag('-v, --verbose', 'verbose output of errors')
  cli:add_flag('-s, --enable-sound', 'executes `say` command if available')
  cli:add_flag('--no-keep-going', 'quit after first error or failure')
  cli:add_flag('--list', 'list the names of all tests instead of running them')
  cli:add_flag('--shuffle', 'randomize file and test order, takes precedence over --sort (--shuffle-test and --shuffle-files)')
  cli:add_flag('--shuffle-files', 'randomize file execution order, takes precedence over --sort-files')
  cli:add_flag('--shuffle-tests', 'randomize test order within a file, takes precedence over --sort-tests')
  cli:add_flag('--sort', 'sort file and test order (--sort-tests and --sort-files)')
  cli:add_flag('--sort-files', 'sort file execution order')
  cli:add_flag('--sort-tests', 'sort test order within a file')
  cli:add_flag('--suppress-pending', 'suppress `pending` test output')
  cli:add_flag('--defer-print', 'defer print to when test suite is complete')

  -- Parse the cli arguments
  local cliArgs, hasError = cli:parse()
  if hasError then
    os.exit(1)
  end

  -- Return early if only asked for the version
  if cliArgs.version then
    print(busted.version)
    os.exit(0)
  end

  -- Load current working directory
  local fpath = utils.normpath(cliArgs.d)

  -- Load busted config file if available
  local configFile = { }
  local bustedConfigFilePath = utils.normpath(path.join(fpath, '.busted'))

  local bustedConfigFile = pcall(function() configFile = loadfile(bustedConfigFilePath)() end)

  if bustedConfigFile then
    local config, err = configLoader(configFile, cliArgs)

    if err then
      print(err)
    else
      cliArgs = config
    end
  end

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
    lpathprefix = lpathprefix:gsub('^%.([/%\\])', fpath .. '%1')
    lpathprefix = lpathprefix:gsub(';%.([/%\\])', ';' .. fpath .. '%1')
    package.path = (lpathprefix .. ';' .. package.path):gsub(';;',';')
  end

  if #cliArgs.cpath > 0 then
    cpathprefix = cliArgs.cpath
    cpathprefix = cpathprefix:gsub('^%.([/%\\])', fpath .. '%1')
    cpathprefix = cpathprefix:gsub(';%.([/%\\])', ';' .. fpath .. '%1')
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

  -- watch for test errors
  local failures = 0
  local errors = 0
  local quitOnError = cliArgs['no-keep-going']

  busted.subscribe({ 'error' }, function(element, parent, status)
    if element.descriptor == 'output' then
      print('Cannot load output library: ' .. element.name)
    end
    errors = errors + 1
    busted.skipAll = quitOnError
    return nil, true
  end)

  busted.subscribe({ 'failure' }, function(element, parent, status)
    if element.descriptor == 'it' then
      failures = failures + 1
    else
      errors = errors + 1
    end
    busted.skipAll = quitOnError
    return nil, true
  end)

  -- Set up randomization options
  busted.sort = cliArgs['sort-tests'] or cliArgs.sort
  busted.randomize = cliArgs['shuffle-tests'] or cliArgs.shuffle
  busted.randomseed = tonumber(cliArgs.seed) or os.time()
  if cliArgs.seed ~= defaultSeed and tonumber(cliArgs.seed) == nil then
    print('Argument to --seed must be a number')
    errors = errors + 1
  end

  -- Set up output handler to listen to events
  local outputHandlerOptions = {
    verbose = cliArgs.verbose,
    suppressPending = cliArgs['suppress-pending'],
    language = cliArgs.lang,
    deferPrint = cliArgs['defer-print']
  }

  local outputHandler = outputHandlerLoader(cliArgs.output, cliArgs.o, outputHandlerOptions, busted, defaultOutput)
  outputHandler:subscribe(outputHandlerOptions)

  if cliArgs.s then
    require 'busted.outputHandlers.sound'(outputHandlerOptions, busted)
  end

  local getFullName = function(name)
    local parent = busted.context.get()
    local names = { name }

    while parent and (parent.name or parent.descriptor) and
          parent.descriptor ~= 'file' do
      table.insert(names, 1, parent.name or parent.descriptor)
      parent = busted.context.parent(parent)
    end

    return table.concat(names, ' ')
  end

  local hasTag = function(name, tag)
    local found = name:find('#' .. tag)
    return (found ~= nil)
  end

  local filterExcludeTags = function(name)
    for i, tag in pairs(excludeTags) do
      if hasTag(name, tag) then
        return nil, false
      end
    end
    return nil, true
  end

  local filterTags = function(name)
    local fullname = getFullName(name)
    for i, tag in pairs(tags) do
      if hasTag(fullname, tag) then
        return nil, true
      end
    end
    return nil, (#tags == 0)
  end

  local filterOutNames = function(name)
    local found = (getFullName(name):find(cliArgs['filter-out']) ~= nil)
    return nil, not found
  end

  local filterNames = function(name)
    local found = (getFullName(name):find(cliArgs.filter) ~= nil)
    return nil, found
  end

  local printNameOnly = function(name, fn, trace)
    local fullname = getFullName(name)
    if trace and trace.what == 'Lua' then
      print(trace.short_src .. ':' .. trace.currentline .. ': ' .. fullname)
    else
      print(fullname)
    end
    return nil, false
  end

  local ignoreAll = function()
    return nil, false
  end

  local skipOnError = function()
    return nil, (failures == 0 and errors == 0)
  end

  local applyFilter = function(descriptors, name, fn)
    if cliArgs[name] and cliArgs[name] ~= '' then
      for _, descriptor in ipairs(descriptors) do
        busted.subscribe({ 'register', descriptor }, fn, { priority = 1 })
      end
    end
  end

  if cliArgs.list then
    busted.subscribe({ 'suite', 'start' }, ignoreAll, { priority = 1 })
    busted.subscribe({ 'suite', 'end' }, ignoreAll, { priority = 1 })
    applyFilter({ 'setup', 'teardown', 'before_each', 'after_each' }, 'list', ignoreAll)
    applyFilter({ 'it', 'pending' }, 'list', printNameOnly)
  end

  applyFilter({ 'setup', 'teardown', 'before_each', 'after_each' }, 'no-keep-going', skipOnError)
  applyFilter({ 'file', 'describe', 'it', 'pending' }, 'no-keep-going', skipOnError)

  -- The following filters are applied in reverse order
  applyFilter({ 'it', 'pending' }            , 'filter'      , filterNames      )
  applyFilter({ 'describe', 'it', 'pending' }, 'filter-out'  , filterOutNames   )
  applyFilter({ 'it', 'pending' }            , 'tags'        , filterTags       )
  applyFilter({ 'describe', 'it', 'pending' }, 'exclude-tags', filterExcludeTags)

  -- Set up test loader options
  local testFileLoaderOptions = {
    verbose = cliArgs.verbose,
    sort = cliArgs['sort-files'] or cliArgs.sort,
    shuffle = cliArgs['shuffle-files'] or cliArgs.shuffle,
    seed = busted.randomseed
  }

  -- Load test directory
  local rootFile = cliArgs.ROOT and utils.normpath(path.join(fpath, cliArgs.ROOT)) or fileName
  local pattern = cliArgs.pattern
  local testFileLoader = require 'busted.modules.test_file_loader'(busted, loaders, testFileLoaderOptions)
  local fileList = testFileLoader(rootFile, pattern)
  if #fileList == 0 then
    print('No test files found matching Lua pattern: ' .. pattern)
    errors = errors + 1
  end

  if not cliArgs.ROOT then
    local ctx = busted.context.get()
    local file = busted.context.children(ctx)[1]
    getmetatable(file.run).__call = info.func
  end

  busted.subscribe({'suite', 'repeat'}, function()
    local oldctx = busted.context.get()
    local children = busted.context.children(oldctx)

    busted.context.clear()
    local ctx = busted.context.get()
    for k, v in pairs(oldctx) do
      ctx[k] = v
    end

    for _, child in pairs(children) do
      for descriptor, _ in pairs(busted.executors) do
        child[descriptor] = nil
      end
      busted.context.attach(child)
    end

    busted.randomseed = tonumber(cliArgs.seed) or os.time()

    return nil, true
  end)

  local runs = tonumber(cliArgs['repeat']) or 1
  local runString = (runs > 1 and '\nRepeating all tests (run %d of %d) . . .\n\n' or '')
  for i = 1, runs do
    io.write(runString:format(i, runs))
    io.flush()
    if i > 1 then
      busted.publish({ 'suite', 'repeat' })
    end

    busted.publish({ 'suite', 'start' })
    busted.execute()
    busted.publish({ 'suite', 'end' })

    if quitOnError and (failures > 0 or errors > 0) then
      break
    end
  end

  local exit = 0
  if failures > 0 or errors > 0 then
    exit = failures + errors
    if exit > 255 then
      exit = 255
    end
  end
  os.exit(exit)
end
