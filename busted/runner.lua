-- Busted command-line runner

local utils = require 'busted.utils'
local exit = require 'busted.compatibility'.exit
local loadstring = require 'busted.compatibility'.loadstring
local loaded = false

return function(options)
  if loaded then return function() end else loaded = true end

  local path = require 'pl.path'
  local tablex = require 'pl.tablex'
  local term = require 'term'

  local isatty = io.type(io.stdout) == 'file' and term.isatty(io.stdout)
  options = tablex.update(require 'busted.options', options or {})
  options.output = options.output or (isatty and 'utfTerminal' or 'plainTerminal')

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
  local fileName = source:sub(1,1) == '@' and source:sub(2) or nil
  local forceExit = fileName == nil

  -- Parse the cli arguments
  local appName = path.basename(fileName or 'busted')
  cli:set_name(appName)
  local cliArgs, err = cli:parse(arg)
  if not cliArgs then
    io.stderr:write(err .. '\n')
    exit(1, forceExit)
  end

  if cliArgs.help then
    io.stdout:write(cliArgs.helpText .. '\n')
    exit(0, forceExit)
  end

  if cliArgs.version then
    -- Return early if asked for the version
    io.stdout:write(busted.version .. '\n')
    exit(0, forceExit)
  end

  -- Load current working directory
  local _, err = path.chdir(path.normpath(cliArgs.directory))
  if err then
    io.stderr:write(appName .. ': error: ' .. err .. '\n')
    exit(1, forceExit)
  end

  -- If coverage arg is passed in, load LuaCovsupport
  if cliArgs.coverage then
    local ok, err = luacov(cliArgs['coverage-config-file'])
    if not ok then
      io.stderr:write(appName .. ': error: ' .. err .. '\n')
      exit(1, forceExit)
    end
  end

  -- If auto-insulate is disabled, re-register file without insulation
  if not cliArgs['auto-insulate'] then
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

  -- Load and execute commands given on the command-line
  if cliArgs.e then
    for k,v in ipairs(cliArgs.e) do
      loadstring(v)()
    end
  end

  -- watch for test errors and failures
  local failures = 0
  local errors = 0
  local quitOnError = not cliArgs['keep-going']

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

  -- Set up randomization options
  busted.sort = cliArgs['sort-tests']
  busted.randomize = cliArgs['shuffle-tests']
  busted.randomseed = tonumber(cliArgs.seed) or utils.urandom() or os.time()

  -- Set up output handler to listen to events
  outputHandlerLoader(busted, cliArgs.output, {
    defaultOutput = options.output,
    enableSound = cliArgs['enable-sound'],
    verbose = cliArgs.verbose,
    suppressPending = cliArgs['suppress-pending'],
    language = cliArgs.lang,
    deferPrint = cliArgs['defer-print'],
    arguments = cliArgs.Xoutput,
  })

  -- Pre-load the LuaJIT 'ffi' module if applicable
  require 'busted.luajit'()

  -- Set up helper script, must succeed to even start tests
  if cliArgs.helper and cliArgs.helper ~= '' then
    local ok, err = helperLoader(busted, cliArgs.helper, {
      verbose = cliArgs.verbose,
      language = cliArgs.lang,
      arguments = cliArgs.Xhelper
    })
    if not ok then
      io.stderr:write(appName .. ': failed running the specified helper (' ..
                      cliArgs.helper .. '), error: ' .. err .. '\n')
      exit(1, forceExit)
    end
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

  if cliArgs['log-success'] then
    local logFile = assert(io.open(cliArgs['log-success'], 'a'))
    busted.subscribe({ 'test', 'end' }, function (test, parent, status)
      if status == "success" then
        logFile:write(getFullName() .. "\n")
      end
    end)
  end

  -- Load tag and test filters
  filterLoader(busted, {
    tags = cliArgs.tags,
    excludeTags = cliArgs['exclude-tags'],
    filter = cliArgs.filter,
    name = cliArgs.name,
    filterOut = cliArgs['filter-out'],
    excludeNamesFile = cliArgs['exclude-names-file'],
    list = cliArgs.list,
    nokeepgoing = not cliArgs['keep-going'],
    suppressPending = cliArgs['suppress-pending'],
  })

  -- Function to load test files
  local function loadTestFiles(rootFilesOverride)
    local rootFiles = rootFilesOverride or cliArgs.ROOT
    local patterns = cliArgs.pattern

    if rootFiles then
      local testFileLoader = require 'busted.modules.test_file_loader'(busted, cliArgs.loaders)
      testFileLoader(rootFiles, patterns, {
        excludes = cliArgs['exclude-pattern'],
        verbose = cliArgs.verbose,
        recursive = cliArgs['recursive'],
      })
    else
      -- Running standalone, use standalone loader
      local testFileLoader = require 'busted.modules.standalone_loader'(busted)
      testFileLoader(info, { verbose = cliArgs.verbose })
    end

    return true
  end

  -- Function to run tests once
  -- Note: resetCounters=true resets failures/errors counters (used by watch mode)
  local function runTests(resetCounters)
    if resetCounters then
      failures = 0
      errors = 0
      busted.skipAll = false
    end

    local runs = cliArgs['repeat']
    local executeModule = require 'busted.execute'(busted)
    executeModule(runs, {
      seed = cliArgs.seed,
      shuffle = cliArgs['shuffle-files'],
      sort = cliArgs['sort-files'],
    })

    return failures + errors
  end

  -- Reset counters before initial loading
  -- (errors may be recorded during file loading if no files match)
  failures = 0
  errors = 0
  busted.skipAll = false

  -- Initial test file loading
  local loadOk, loadExitCode = loadTestFiles()
  if not loadOk then
    if not cliArgs.watch then
      exit(loadExitCode or 0, forceExit)
    end
  end

  -- Check if watch mode is enabled
  if cliArgs.watch then
    local WatchMode = require 'busted.modules.watch'
    local watchMode = WatchMode.new(busted, cliArgs)

    -- Function to reload and run tests in watch mode
    local function watchRunTests(filesOverride)
      -- Reset counters for each watch run
      failures = 0
      errors = 0
      busted.skipAll = false

      -- Preserve the old context env (contains busted API: describe, it, etc.)
      local oldctx = busted.context.get()

      -- Clear context for fresh run
      busted.context.clear()
      local ctx = busted.context.get()

      -- Restore env and other properties from old context
      for k, v in pairs(oldctx) do
        ctx[k] = v
      end

      -- Reload test files
      local ok, loadErr = pcall(function()
        loadTestFiles(filesOverride)
      end)

      if not ok then
        io.stderr:write('Error loading tests: ' .. tostring(loadErr) .. '\n')
        return 1
      end

      -- Run tests (don't reset counters as we already did above)
      local exitCode = runTests(false)
      watchMode:set_exit_code(exitCode)
      return exitCode
    end

    -- Start watch mode
    local exitCode = watchMode:start(watchRunTests)
    busted.publish({ 'exit' })
    exit(exitCode, forceExit)
  else
    -- Normal execution (non-watch mode)
    -- Don't reset counters as we already did before loadTestFiles()
    runTests(false)
    busted.publish({ 'exit' })

    if options.standalone or failures > 0 or errors > 0 then
      exit(failures + errors, forceExit)
    end
  end
end
