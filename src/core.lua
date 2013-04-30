local moon = require('busted.moon')
local path = require('pl.path')
local dir = require('pl.dir')
local tablex = require('pl.tablex')
require'pl'

-- exported module table
busted = {}
busted._COPYRIGHT   = "Copyright (c) 2013 Olivine Labs, LLC."
busted._DESCRIPTION = "A unit testing framework with a focus on being easy to use. http://www.olivinelabs.com/busted"
busted._VERSION     = "Busted 1.8"

-- set defaults
busted.defaultoutput = path.is_windows and "plain_terminal" or "utf_terminal"
busted.defaultpattern = '_spec.lua$'
busted.defaultlua = 'luajit'
busted.lpathprefix = "./src/?.lua;./src/?/?.lua;./src/?/init.lua"
busted.cpathprefix = path.is_windows and "./csrc/?.dll;./csrc/?/?.dll;" or "./csrc/?.so;./csrc/?/?.so;"
require('busted.languages.en')-- Load default language pack

local options = {}
local current_context

-- report a test-process error as a failed test
local internal_error = function(description, err)
  local tag = ""

  if options.tags and #options.tags > 0 then
    -- tags specified; must insert a tag to make sure the error gets displayed
    tag = " #"..options.tags[1]
  end

  if not current_context then
    busted.reset()
  end

  describe("Busted process errors occured" .. tag, function()
    it(description .. tag, function()
      error(err)
    end)
  end)
end

-- returns current time in seconds
local function get_time()
  local success, socket = pcall(function() return require "socket" end)
  if success then
    get_time = function()
      return socket.gettime()
    end
  else
    get_time = os.clock
  end

  return get_time()
end

local language = function(lang)
  if lang then
    busted.messages = require('busted.languages.'..lang)
    require('luassert.languages.'..lang)
  end
end

-- load the outputter as set in the options, revert to default if it fails
local getoutputter = function(output, opath, default)
  local success, out, f
  if output:match(".lua$") then
    f = function()
      return loadfile(path.normpath(path.join(opath, output)))()
    end
  else
    f = function()
      return require('busted.output.'..output)()
    end
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
local gettestfiles = function(root_file, pattern)
  local filelist

  if path.isfile(root_file) then
    filelist = { root_file }
  elseif path.isdir(root_file) then
    local pattern = pattern ~= "" and pattern or defaultpattern
    filelist = dir.getallfiles(root_file)

    filelist = tablex.filter(filelist, function(filename)
      return path.basename(filename):find(pattern)
    end)
  else
    filelist = {}
    internal_error("Getting test files", "No test files found for path '"..root_file.."' and pattern `"..pattern.."`. Please review your commandline, re-run with `--help` for usage.")
  end

  return filelist
end

-- runs a testfile, loading its tests
local load_testfile = function(filename)
  local old_TEST = _TEST
  _TEST = busted._VERSION

  local success, err = pcall(function() moon.loadfile(filename)() end)

  if not success then
    internal_error("Failed executing testfile; " .. tostring(filename), err)
  end

  _TEST = old_TEST
end

local play_sound = function(failures)
  if busted.messages.failure_messages and #busted.messages.failure_messages > 0 and
    busted.messages.success_messages and #busted.messages.success_messages > 0 then

    math.randomseed(os.time())

    if failures and failures > 0 then
      io.popen("say \""..busted.messages.failure_messages[math.random(1, #busted.messages.failure_messages)]:format(failures).."\"")
    else
      io.popen("say \""..busted.messages.success_messages[math.random(1, #busted.messages.success_messages)].."\"")
    end
  end
end

local get_fname = function(short_src)
  local i = short_src:find('"', 1, true)
  if i then
    local j = short_src:find('"', i+1, true)
    if j then
      return short_src:sub(i+1, j-1)
    end
  end
end

--=============================
-- Test engine
--=============================

local push = table.insert

local suite = {
  tests = {},
  done = {},
  started = {},
  test_index = 1,
  loop_pcall = pcall,
  loop_step = function() end,
}

local options

step = function(...)
  local steps = { ... }
  if #steps == 1 and type(steps[1]) == 'table' then
    steps = steps[1]
  end

  local i = 0

  local next

  next = function()
    i = i + 1
    local step = steps[i]
    if step then
      step(next)
    end
  end

  next()
end

busted.step = step

guard = function(f, test)
  local test = suite.tests[suite.test_index]

  local safef = function(...)
    local result = { suite.loop_pcall(f, ...) }

    if result[1] then
      return unpack(result, 2)
    else
      local err = result[2]
      if type(err) == "table" then
        err = pretty.write(err)
      end

      local stack_trace = debug.traceback("", 2)
      err, stack_trace = moon.rewrite_traceback(err, stack_trace)

      test.status.type = 'failure'
      test.status.trace = stack_trace
      test.status.err = err
      assert(type(test.done) == 'function', 'non-test step failed (before/after/etc.):\n'..err)
      test.done()
    end
  end

  return safef
end

busted.guard = guard

local next_test

next_test = function()
  if #suite.done == #suite.tests then
    return
  end

  if not suite.started[suite.test_index] then
    suite.started[suite.test_index] = true

    local test = suite.tests[suite.test_index]
    assert(test, suite.test_index..debug.traceback('', 1))
    local steps = {}

    local execute_test = function(next)
      local done = function()
        if test.done_trace then
          if test.status.err == nil then
            local stack_trace = debug.traceback("", 2)
            err, stack_trace = moon.rewrite_traceback(err, stack_trace)

            test.status.err = 'test already "done":"'..test.name..'"'
            test.status.err = test.status.err..'. First called from '..test.done_trace
            test.status.type = 'failure'
            test.status.trace = stack_trace
          end
          return
        end

        assert(suite.test_index <= #suite.tests, 'invalid test index: '..suite.test_index)

        suite.done[suite.test_index] = true
        -- keep done trace for easier error location when called multiple time
        local done_trace = debug.traceback("", 2)
        err, done_trace = moon.rewrite_traceback(err, done_trace)

        test.done_trace = pretty.write(done_trace)

        if not options.defer_print then
          busted.output.currently_executing(test.status, options)
        end

        test.context:decrement_test_count()
        next()
      end

      test.done = done

      local ok, err = suite.loop_pcall(test.f, done)

      if not ok then
        if type(err) == "table" then
          err = pretty.write(err)
        end

        local trace = debug.traceback("", 2)
        err, trace = moon.rewrite_traceback(err, trace)

        test.status.type = 'failure'
        test.status.trace = trace
        test.status.err = err
        done()
      end
    end

    local check_before = function(context)
      if context.before then
        local execute_before = function(next)
          context.before(
            function()
              context.before = nil
              next()
            end)
        end

        push(steps, execute_before)
      end
    end

    local parents = test.context.parents

    for p=1, #parents do
      check_before(parents[p])
    end

    check_before(test.context)

    for p=1, #parents do
      if parents[p].before_each then
        push(steps, parents[p].before_each)
      end
    end

    if test.context.before_each then
      push(steps, test.context.before_each)
    end

    push(steps, execute_test)

    if test.context.after_each then
      push(steps, test.context.after_each)
    end

    local post_test = function(next)
      local post_steps = {}

      local check_after = function(context)
        if context.after then
          if context:all_tests_done() then
            local execute_after = function(next)
              context.after(
                function()
                  context.after = nil
                  next()
                end)
            end

            push(post_steps, execute_after)
          end
        end
      end

      for p=#parents, 1, -1 do
        if parents[p].after_each then
          push(post_steps, parents[p].after_each)
        end
      end

      check_after(test.context)

      for p=#parents, 1, -1 do
        check_after(parents[p])
      end

      local forward = function(next)
        suite.test_index = suite.test_index + 1
        next_test()
        next()
      end

      push(post_steps, forward)
      step(post_steps)
    end

    push(steps, post_test)
    step(steps)
  end
end

local create_context = function(desc)
  local context = {
    desc = desc,
    parents = {},
    test_count = 0,
    increment_test_count = function(self)
      self.test_count = self.test_count + 1
      for _, parent in ipairs(self.parents) do
        parent.test_count = parent.test_count + 1
      end
    end,

    decrement_test_count = function(self)
      self.test_count = self.test_count - 1
      for _, parent in ipairs(self.parents) do
        parent.test_count = parent.test_count - 1
      end
    end,

    all_tests_done = function(self)
      return self.test_count == 0
    end,

    add_parent = function(self, parent)
      push(self.parents, parent)
    end
  }

  return context
end

local suite_name

busted.describe = function(desc, more)
  if not suite_name then
    suite_name = desc
  end

  local context = create_context(desc)

  for i, parent in ipairs(current_context.parents) do
    context:add_parent(parent)
  end

  context:add_parent(current_context)

  local old_context = current_context

  current_context = context
  more()

  current_context = old_context
end

busted.before = function(sync_before, async_before)
  if async_before then
    current_context.before = async_before
  else
    current_context.before = function(done)
      sync_before()
      done()
    end
  end
end

busted.before_each = function(sync_before, async_before)
  if async_before then
    current_context.before_each = async_before
  else
    current_context.before_each = function(done)
      sync_before()
      done()
    end
  end
end

busted.after = function(sync_after, async_after)
  if async_after then
    current_context.after = async_after
  else
    current_context.after = function(done)
      sync_after()
      done()
    end
  end
end

busted.after_each = function(sync_after, async_after)
  if async_after then
    current_context.after_each = async_after
  else
    current_context.after_each = function(done)
      sync_after()
      done()
    end
  end
end

local function buildInfo(debug_info)
  local info = {
    source = debug_info.source,
    short_src = debug_info.short_src,
    linedefined = debug_info.linedefined,
  }

  fname = get_fname(info.short_src)

  if fname and moon.is_moon(fname) then
    info.linedefined = moon.rewrite_linenumber(fname, info.linedefined) or info.linedefined
  end

  return info
end


busted.pending = function(name)
  local test = {
    context = current_context,
    name = name
  }

  test.context:increment_test_count()

  local debug_info = debug.getinfo(2)

  test.f = function(done)
    done()
  end

  test.status = {
    description = name,
    type = 'pending',
    info = buildInfo(debug_info)
  }

  suite.tests[#suite.tests+1] = test
end

busted.it = function(name, sync_test, async_test)
  local test = {
    context = current_context,
    name = name
  }

  test.context:increment_test_count()

  local debug_info

  if async_test then
    debug_info = debug.getinfo(async_test)
    test.f = async_test
  else
    debug_info = debug.getinfo(sync_test)
    -- make sync test run async
    test.f = function(done)
      sync_test()
      done()
    end
  end

  test.status = {
    description = test.name,
    type = 'success',
    info = buildInfo(debug_info)
  }

  suite.tests[#suite.tests+1] = test
end

busted.reset = function()
  current_context = create_context('Root context')

  suite = {
    tests = {},
    done = {},
    started = {},
    test_index = 1,
    loop_pcall = pcall,
    loop_step = function() end,
  }
  suite_name = nil
end

busted.setloop = function(...)
  local args = { ... }

  if type(args[1]) == 'string' then
    local loop = args[1]

    if loop == 'ev' then
      local ev = require'ev'

      suite.loop_pcall = pcall
      suite.loop_step = function()
        ev.Loop.default:loop()
      end
    elseif loop == 'copas' then
      local copas = require'copas'

      require'coxpcall'

      suite.loop_pcall = copcall
      suite.loop_step = function()
        copas.step(0)
      end
    end
  else
    suite.loop_step = args[1]
    suite.loop_pcall = args[2] or pcall
  end
end

busted.run_internal_test = function(describe_tests)
  local suite_bak = suite
  local output_bak = busted.output

  busted.output = require 'busted.output.stub'()

  suite = {
    tests = {},
    done = {},
    started = {},
    test_index = 1,
    loop_pcall = pcall,
    loop_step = function() end
  }

  describe_tests()

  repeat
    next_test()
    suite.loop_step()
  until #suite.done == #suite.tests

  local statuses = {}

  for _, test in ipairs(suite.tests) do
    push(statuses, test.status)
  end

  suite = suite_bak
  busted.output = output_bak

  return statuses
end

-- test runner
busted.run = function(got_options)
  options = got_options

  language(options.lang)
  busted.output = getoutputter(options.output, options.fpath, busted.defaultoutput)
  -- if no filelist given, get them
  options.filelist = options.filelist or gettestfiles(options.root_file, options.pattern)
  -- load testfiles

  local ms = get_time()

  local statuses = {}
  local failures = 0
  local suites = {}
  local tests = 0

  local function run_suite()
    repeat
      next_test()
      suite.loop_step()
    until #suite.done == #suite.tests

    for _, test in ipairs(suite.tests) do
      push(statuses, test.status)
      if test.status.type == 'failure' then
        failures = failures + 1
      end
    end
  end

  -- there's already a test! probably an error
  if #suite.tests > 0 then
    run_suite()
  end

  for i, filename in ipairs(options.filelist) do
    local old_TEST = _TEST
    _TEST = busted._VERSION

    busted.reset()

    suite._TEST = _TEST

    load_testfile(filename)
    tests = tests + #suite.tests

    suites[i] = suite
    _TEST = old_TEST
  end

  if not options.defer_print then
    print(busted.output.header('global', tests))
  end

  for i, filename in ipairs(options.filelist) do
    _TEST = suites[i]._TEST
    suite = suites[i]
    run_suite()
  end

  --final run time
  ms = get_time() - ms

  local status_string = busted.output.formatted_status(statuses, options, ms)

  if options.sound then
    play_sound(failures)
  end

  return status_string, failures
end

it = busted.it
pending = busted.pending
describe = busted.describe
before = busted.before
after = busted.after
setup = busted.before
busted.setup = busted.before
teardown = busted.after
busted.teardown = busted.after
before_each = busted.before_each
after_each = busted.after_each
step = step
setloop = busted.setloop

return setmetatable(busted, {
  __call = function(self, ...)
    return busted.run(...)
  end
 })

