local path = require('pl.path')
local dir = require('pl.dir')
local tablex = require('pl.tablex')

local busted = {}   -- exported module table
busted._COPYRIGHT   = "Copyright (c) 2013 Olivine Labs, LLC."
busted._DESCRIPTION = "A unit testing framework with a focus on being easy to use. http://www.olivinelabs.com/busted"
busted._VERSION     = "Busted 1.6"

-- set defaults
busted.defaultoutput = path.is_windows and "plain_terminal" or "utf_terminal"
busted.defaultpattern = '_spec.lua$'
busted.defaultlua = 'luajit'
busted.lpathprefix = "./src/?.lua;./src/?/?.lua;./src/?/init.lua"
busted.cpathprefix = path.is_windows and "./csrc/?.dll;./csrc/?/?.dll;" or "./csrc/?.so;./csrc/?/?.so;"
require('busted.languages.en')    -- Load default language pack

local failures = 0
local options
local root_context = { type = "describe", description = "global", before_each_stack = {}, after_each_stack = {} }
local current_context = root_context


-- report a test-process error as a failed test
local function internal_error(description, err)
  local tag = ""
  if options.tags and #options.tags > 0 then
    -- tags specified; must insert a tag to make sure the error gets displayed
    tag = " #"..options.tags[1]
  end
  describe("Busted process errors occured" .. tag, function()
    it(description .. tag, function()
      error(err)
    end)
  end)
end

local function language(lang)
  if lang then
    busted.messages = require('busted.languages.'..lang)
    require('luassert.languages.'..lang)
  end
end

-- load the outputter as set in the options, revert to default if it fails
local function getoutputter(output, opath, default)
  local success, out, f
  if output:match(".lua$") then
    f = function() return loadfile(path.normpath(path.join(opath, output)))() end
  else
    f = function() return require('busted.output.'..output)() end
  end

  success, out = pcall(f)
  if not success then
    if not default then
        -- even default failed, so error out the hard way
      return error("Failed to open the busted default output; " .. tostring(output) .. ".\n"..out)
    else
      internal_error("Unable to open output module; requested option '--output=" .. tostring(output).."'.", out)
      -- retry with default outputter
      return getoutputter(default, opath)
    end
  end
  return out
end

-- acquire set of test files from the options specified
local function gettestfiles(root_file, pattern)
  local filelist
  if path.isfile(root_file) then
    filelist = { root_file }
  elseif path.isdir(root_file) then
    local pattern = pattern ~= "" and pattern or defaultpattern
    filelist = dir.getallfiles(root_file)
    filelist = tablex.filter(filelist, function(filename)
        return path.basename(filename):find(pattern)
      end )
  end
  return filelist
end

-- runs a testfile, loading its tests
local function load_testfile(filename)
  local old_TEST = _TEST
  _TEST = busted._VERSION
  
  local success, err = pcall(function() loadfile(filename)() end)
  if not success then
    internal_error("Failed executing testfile; " .. tostring(filename), err)
  end

  _TEST = old_TEST
end

local play_sound = function(failures)
  math.randomseed(os.time())

  if busted.messages.failure_messages and #busted.messages.failure_messages > 0 and
     busted.messages.success_messages and #busted.messages.success_messages > 0 then
    if failures and failures > 0 then
      io.popen("say \""..busted.messages.failure_messages[math.random(1, #busted.messages.failure_messages)]:format(failures).."\"")
    else
      io.popen("say \""..busted.messages.success_messages[math.random(1, #busted.messages.success_messages)].."\"")
    end
  end
end


--=============================
-- Test engine
--=============================

--run a single test
local function test(description, callback, no_output)
  local debug_info = debug.getinfo(callback)

  local info = {
    source = debug_info.source,
    short_src = debug_info.short_src,
    linedefined = debug_info.linedefined,
  }

  local stack_trace = ""

  local function err_handler(err)
    stack_trace = debug.traceback("", 4)
    return err
  end

  local status, err = xpcall(callback, err_handler)

  local test_status = {}

  if not status then
    if type(err) == "table" then
      err = pretty.write(err)
    end

    test_status = { type = "failure", description = description, info = info, trace = stack_trace, err = err }
    failures = failures + 1
  else
    test_status = { type = "success", description = description, info = info }
  end

  if not no_output and not options.defer_print then
    busted.output.currently_executing(test_status, options)
  end

  return test_status
end

-- run setup/teardown
local function run_setup(context, stype, decsription)
  if not context[stype] then
    return true
  else
    if type(context[stype]) == "function" then
      local result = test("Failed running test initializer '"..stype.."'", context[stype], true)
      return (result.type == "success"), result
    elseif type(context[stype]) == "table" then
      if #context[stype] > 0 then
        local result

        for _,v in ipairs(context[stype]) do
          result = test("Failed running test initializer '"..decsription.."'", v, true)

          if result.type ~= "success" then
            return (result.type == "success"), result
          end
        end

        return (result.type == "success"), result
      else
        return true
      end
    end
  end
end

--run single test case
local function run_context(context)
  local match = false

  if options.tags and #options.tags > 0 then
    for _,t in ipairs(options.tags) do
      if context.description:find("#"..t) then
        match = true
      end
    end
  else
    match = true
  end

  local status = { description = context.description, type = "description", run = match }
  local setup_ok, setup_error

  setup_ok, setup_error = run_setup(context, "setup")

  if setup_ok then
    for _,v in ipairs(context) do
      if v.type == "test" then
        setup_ok, setup_error = run_setup(context, "before_each_stack", "before_each")
        if not setup_ok then break end

        table.insert(status, test(v.description, v.callback))

        setup_ok, setup_error = run_setup(context, "after_each_stack", "after_each")
        if not setup_ok then break end
      elseif v.type == "describe" then
        local res = run_context(v)
        for key,value in ipairs(res) do
          table.insert(status, value)
        end
      elseif v.type == "pending" then
        local pending_test_status = { type = "pending", description = v.description, info = v.info }
        v.callback(pending_test_status)
        table.insert(status, pending_test_status)
      end
    end
  end

  if setup_ok then setup_ok, setup_error = run_setup(context, "teardown") end

  if not setup_ok then table.insert(status, setup_error) end
  
  return status
end

-- test runner
busted.run = function(got_options)

  options = got_options
  failures = 0

  language(options.lang)
  busted.output = getoutputter(options.output, options.fpath, busted.defaultoutput)
  -- if no filelist given, get them
  options.filelist = options.filelist or gettestfiles(options.root_file, options.pattern)
  -- load testfiles
  tablex.foreachi(options.filelist, load_testfile)

  local ms = os.clock()

  if not options.defer_print then
    print(busted.output.header(root_context))
  end

  local old_TEST = _TEST
  _TEST = busted._VERSION
  local statuses = run_context(root_context)

  --final run time
  ms = os.clock() - ms

  if options.defer_print then
    print(busted.output.header(root_context))
  end

  local status_string = busted.output.formatted_status(statuses, options, ms)

  if options.sound then
    play_sound(failures)
  end

  if not options.defer_print then
    print(busted.output.footer(root_context))
  end

  _TEST = old_TEST
  return status_string, failures
end


--=============================
-- Global test functions
--=============================
busted.describe = function(description, callback)
  local match = current_context.run
  local parent = current_context

  if options.tags and #options.tags > 0 then
    for _,t in ipairs(options.tags) do
      if description:find("#"..t) then
        match = true
      end
    end
  else
    match = true
  end

  local local_context = {
    description = description,
    callback = callback,
    type = "describe",
    run = match,
    before_each_stack = {},
    after_each_stack = {}
  }

  for _,v in pairs(current_context.before_each_stack) do
    table.insert(local_context.before_each_stack, v)
  end

  for _,v in pairs(current_context.after_each_stack) do
    table.insert(local_context.after_each_stack, v)
  end

  table.insert(current_context, local_context)

  current_context = local_context

  callback()

  current_context = parent
end

busted.it = function(description, callback)
  assert(current_context ~= root_context, debug.traceback("An it() block must be wrapped in a describe() block/n", 2))
  local match = current_context.run

  if not match then
    if options.tags and #options.tags > 0 then
      for _,t in ipairs(options.tags) do
        if description:find("#"..t) then
          match = true
        end
      end
    end
  end

  if match then
    table.insert(current_context, { description = description, callback = callback, type = "test" })
  end
end

busted.pending = function(description, callback)
  assert(current_context ~= root_context, debug.traceback("A pending() block must be wrapped in a describe() block/n", 2))
  local debug_info = debug.getinfo(callback)

  local info = {
    source = debug_info.source,
    short_src = debug_info.short_src,
    linedefined = debug_info.linedefined,
  }

  local test_status = {
    description = description,
    type = "pending",
    info = info,
    callback = function(self)
      if not options.defer_print then
        busted.output.currently_executing(self, options)
      end
    end
  }

  table.insert(current_context, test_status)
end

busted.before_each = function(callback)
  table.insert(current_context.before_each_stack, callback)
end

busted.after_each = function(callback)
  table.insert(current_context.after_each_stack, 1, callback)
end

busted.setup = function(callback)
  current_context.setup = callback
end

busted.teardown = function(callback)
  current_context.teardown = callback
end


return setmetatable(busted, {
    __call = function(self, ...)
      return busted.run(...)
    end } )

