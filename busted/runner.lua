-- Busted command-line runner

local getfenv = require 'busted.compatibility'.getfenv
local setfenv = require 'busted.compatibility'.setfenv
local path = require 'pl.path'
local utils = require 'pl.utils'
local loaded = false

-- Do not use pl.path.normpath
-- It is broken for paths with leading '../../'
local function normpath(fpath)
  if type(fpath) ~= 'string' then
    error(fpath .. ' is not a string')
  end
  local sep = '/'
  if path.is_windows then
    sep = '\\'
    if fpath:match '^\\\\' then -- UNC
      return '\\\\' .. normpath(fpath:sub(3))
    end
    fpath = fpath:gsub('/','\\')
  end
  local np_gen1, np_gen2 = '([^SEP]+)SEP(%.%.SEP?)', 'SEP+%.?SEP'
  local np_pat1 = np_gen1:gsub('SEP', sep)
  local np_pat2 = np_gen2:gsub('SEP', sep)
  local k
  repeat -- /./ -> /
    fpath, k = fpath:gsub(np_pat2, sep)
  until k == 0
  repeat -- A/../ -> (empty)
    local oldpath = fpath
    fpath, k = fpath:gsub(np_pat1, function(d, up)
      if d == '..' then return nil end
      if d == '.' then return up end
      return ''
    end)
  until k == 0 or oldpath == fpath
  if fpath == '' then fpath = '.' end
  return fpath
end

return function(options)
  if loaded then return else loaded = true end

  local opt = options or {}
  local isBatch = opt.batch
  local cli = require 'cliargs'
  local busted = require 'busted.core'()

  local configLoader = require 'busted.modules.configuration_loader'()
  local outputHandlerLoader = require 'busted.modules.output_handler_loader'()

  local luacov = require 'busted.modules.luacov'()

  require 'busted.init'(busted)

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
  cli:add_flag('--randomize', 'force randomized test order')
  cli:add_flag('--shuffle', 'force randomized test order (alias for randomize)')
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
  local fpath = cliArgs.d

  -- Load busted config file if available
  local configFile = { }
  local bustedConfigFilePath = normpath(path.join(fpath, '.busted'))

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

  -- watch for test errors
  local failures = 0
  local errors = 0

  busted.subscribe({ 'error' }, function(element, parent, status)
    if element.descriptor == 'output' then
      print('Cannot load output library: ' .. element.name)
    end
    errors = errors + 1
    return nil, true
  end)

  busted.subscribe({ 'failure' }, function(element, parent, status)
    if element.descriptor == 'it' then
      failures = failures + 1
    else
      errors = errors + 1
    end
    return nil, true
  end)

  -- Set up randomization options
  busted.randomize = cliArgs.randomize or cliArgs.shuffle
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

  local hasTag = function(name, tag)
    local found = name:find('#' .. tag)
    return (found ~= nil)
  end

  local checkTags = function(name)
    for i, tag in pairs(excludeTags) do
      if hasTag(name, tag) then
        return nil, false
      end
    end

    for i, tag in pairs(tags) do
      if hasTag(name, tag) then
        return nil, true
      end
    end

    return nil, (#tags == 0)
  end

  if cliArgs.t ~= '' or cliArgs['exclude-tags'] ~= '' then
    -- Watch for tags
    busted.subscribe({ 'register', 'it' }, checkTags, { priority = 1 })
    busted.subscribe({ 'register', 'pending' }, checkTags, { priority = 1 })
  end

  -- Load test directory
  local rootFile = cliArgs.ROOT and normpath(path.join(fpath, cliArgs.ROOT)) or fileName
  local pattern = cliArgs.pattern
  local testFileLoader = require 'busted.modules.test_file_loader'(busted, loaders)
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
