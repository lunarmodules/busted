local utils = require 'busted.utils'
local path = require 'pl.path'
local tablex = require 'pl.tablex'

return function(options)
  local appName = ''
  local options = options or {}
  local cli = require 'cliargs'

  local configLoader = require 'busted.modules.configuration_loader'()

  -- Default cli arg values
  local defaultOutput = options.defaultOutput
  local defaultLoaders = 'lua,moonscript'
  local defaultPattern = '_spec'
  local defaultSeed = 'os.time()'
  local lpathprefix = './src/?.lua;./src/?/?.lua;./src/?/init.lua'
  local cpathprefix = path.is_windows and './csrc/?.dll;./csrc/?/?.dll;' or './csrc/?.so;./csrc/?/?.so;'

  local cliArgsParsed = {}

  local function fixupList(values, sep)
    local sep = sep or ','
    local list = type(values) == 'table' and values or { values }
    local olist = {}
    for _, v in ipairs(list) do
      tablex.insertvalues(olist, utils.split(v, sep))
    end
    return olist
  end

  local function processOption(key, value, altkey, opt)
    if altkey then cliArgsParsed[altkey] = value end
    cliArgsParsed[key] = value
    return true
  end

  local function processArg(key, value)
    cliArgsParsed[key] = value
    return true
  end

  local function processArgList(key, value)
    local list = cliArgsParsed[key] or {}
    tablex.insertvalues(list, utils.split(value, ','))
    processArg(key, list)
    return true
  end

  local function processNumber(key, value, altkey, opt)
    local number = tonumber(value)
    if not number then
      return nil, 'argument to ' .. opt:gsub('=.*', '') .. ' must be a number'
    end
    if altkey then cliArgsParsed[altkey] = number end
    cliArgsParsed[key] = number
    return true
  end

  local function processList(key, value, altkey, opt)
    local list = cliArgsParsed[key] or {}
    tablex.insertvalues(list, utils.split(value, ','))
    processOption(key, list, altkey, opt)
    return true
  end

  local function processMultiOption(key, value, altkey, opt)
    local list = cliArgsParsed[key] or {}
    table.insert(list, value)
    processOption(key, list, altkey, opt)
    return true
  end

  local function append(s1, s2, sep)
    local sep = sep or ''
    if not s1 then return s2 end
    return s1 .. sep .. s2
  end

  local function processLoaders(key, value, altkey, opt)
    local loaders = append(cliArgsParsed[key], value, ',')
    processOption(key, loaders, altkey, opt)
    return true
  end

  local function processPath(key, value, altkey, opt)
    local lpath = append(cliArgsParsed[key], value, ';')
    processOption(key, lpath, altkey, opt)
    return true
  end

  local function processDir(key, value, altkey, opt)
    local dpath = path.join(cliArgsParsed[key] or '', value)
    processOption(key, dpath, altkey, opt)
    return true
  end

  -- Load up the command-line interface options
  cli:add_flag('--version', 'prints the program version and exits', processOption)

  if options.batch then
    cli:optarg('ROOT', 'test script file/folder. Folders will be traversed for any file that matches the --pattern option.', 'spec', 999, processArgList)

    cli:add_option('-p, --pattern=PATTERN', 'only run test files matching the Lua pattern', defaultPattern, processOption)
  end

  cli:add_option('-o, --output=LIBRARY', 'output library to load', defaultOutput, processOption)
  cli:add_option('-C, --directory=DIR', 'change to directory DIR before running tests. If multiple options are specified, each is interpreted relative to the previous one.', './', processDir)
  cli:add_option('-t, --tags=TAGS', 'only run tests with these #tags', {}, processList)
  cli:add_option('--exclude-tags=TAGS', 'do not run tests with these #tags, takes precedence over --tags', {}, processList)
  cli:add_option('--filter=PATTERN', 'only run test names matching the Lua pattern', {}, processMultiOption)
  cli:add_option('--filter-out=PATTERN', 'do not run test names matching the Lua pattern, takes precedence over --filter', {}, processMultiOption)
  cli:add_option('-m, --lpath=PATH', 'optional path to be prefixed to the Lua module search path', lpathprefix, processPath)
  cli:add_option('--cpath=PATH', 'optional path to be prefixed to the Lua C module search path', cpathprefix, processPath)
  cli:add_option('-r, --run=RUN', 'config to run from .busted file', nil, processOption)
  cli:add_option('--repeat=COUNT', 'run the tests repeatedly', '1', processNumber)
  cli:add_option('--seed=SEED', 'random seed value to use for shuffling test order', defaultSeed, processNumber)
  cli:add_option('--lang=LANG', 'language for error messages', 'en', processOption)
  cli:add_option('--loaders=NAME', 'test file loaders', defaultLoaders, processLoaders)
  cli:add_option('--helper=PATH', 'A helper script that is run before tests', nil, processOption)

  cli:add_option('-Xoutput OPTION', 'pass `OPTION` as an option to the output handler. If `OPTION` contains commas, it is split into multiple options at the commas.', {}, processList)
  cli:add_option('-Xhelper OPTION', 'pass `OPTION` as an option to the helper script. If `OPTION` contains commas, it is split into multiple options at the commas.', {}, processList)

  cli:add_flag('-c, --coverage', 'do code coverage analysis (requires `LuaCov` to be installed)', processOption)
  cli:add_flag('-v, --verbose', 'verbose output of errors', processOption)
  cli:add_flag('-s, --enable-sound', 'executes `say` command if available', processOption)
  cli:add_flag('-l, --list', 'list the names of all tests instead of running them', processOption)
  cli:add_flag('--lazy', 'use lazy setup/teardown as the default', processOption)
  cli:add_flag('--no-auto-insulate', 'disable file insulation', processOption)
  cli:add_flag('--no-keep-going', 'quit after first error or failure', processOption)
  cli:add_flag('--no-recursive', 'do not recurse into subdirectories', processOption)
  cli:add_flag('--shuffle', 'randomize file and test order, takes precedence over --sort (--shuffle-test and --shuffle-files)', processOption)
  cli:add_flag('--shuffle-files', 'randomize file execution order, takes precedence over --sort-files', processOption)
  cli:add_flag('--shuffle-tests', 'randomize test order within a file, takes precedence over --sort-tests', processOption)
  cli:add_flag('--sort', 'sort file and test order (--sort-tests and --sort-files)', processOption)
  cli:add_flag('--sort-files', 'sort file execution order', processOption)
  cli:add_flag('--sort-tests', 'sort test order within a file', processOption)
  cli:add_flag('--suppress-pending', 'suppress `pending` test output', processOption)
  cli:add_flag('--defer-print', 'defer print to when test suite is complete', processOption)

  local function parse(args)
    -- Parse the cli arguments
    local cliArgs, cliErr = cli:parse(args, true)
    if not cliArgs then
      return nil, cliErr
    end

    -- Load busted config file if available
    local configFile = { }
    local bustedConfigFilePath = utils.normpath(path.join(cliArgs.directory, '.busted'))
    local bustedConfigFile = pcall(function() configFile = loadfile(bustedConfigFilePath)() end)
    if bustedConfigFile then
      local config, err = configLoader(configFile, cliArgsParsed, cliArgs)
      if err then
        return nil, appName .. ': error: ' .. err
      else
        cliArgs = config
      end
    else
      cliArgs = tablex.merge(cliArgs, cliArgsParsed, true)
    end

    -- Fixup options in case options from config file are not of the right form
    cliArgs.tags = fixupList(cliArgs.tags)
    cliArgs.t = cliArgs.tags
    cliArgs['exclude-tags'] = fixupList(cliArgs['exclude-tags'])
    cliArgs.loaders = fixupList(cliArgs.loaders)
    cliArgs.Xoutput = fixupList(cliArgs.Xoutput)
    cliArgs.Xhelper = fixupList(cliArgs.Xhelper)

    -- We report an error if the same tag appears in both `options.tags`
    -- and `options.excluded_tags` because it does not make sense for the
    -- user to tell Busted to include and exclude the same tests at the
    -- same time.
    for _, excluded in pairs(cliArgs['exclude-tags']) do
      for _, included in pairs(cliArgs.tags) do
        if excluded == included then
          return nil, appName .. ': error: Cannot use --tags and --exclude-tags for the same tags'
        end
      end
    end

    cliArgs['repeat'] = tonumber(cliArgs['repeat'])

    return cliArgs
  end

  return {
    set_name = function(self, name)
      appName = name
      return cli:set_name(name)
    end,

    parse = function(self, args)
      return parse(args)
    end
  }
end
