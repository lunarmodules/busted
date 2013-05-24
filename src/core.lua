local moon = require('busted.moon')
local path = require('pl.path')
local dir = require('pl.dir')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')

-- exported module table
busted = {}
busted._COPYRIGHT   = "Copyright (c) 2013 Olivine Labs, LLC."
busted._DESCRIPTION = "A unit testing framework with a focus on being easy to use. http://www.olivinelabs.com/busted"
busted._VERSION     = "Busted 1.9.0"

-- set defaults
busted.defaultoutput = path.is_windows and "plain_terminal" or "utf_terminal"
busted.defaultpattern = '_spec'
busted.defaultlua = 'luajit'
busted.lpathprefix = "./src/?.lua;./src/?/?.lua;./src/?/init.lua"
busted.cpathprefix = path.is_windows and "./csrc/?.dll;./csrc/?/?.dll;" or "./csrc/?.so;./csrc/?/?.so;"
require('busted.languages.en')-- Load default language pack

-- platform detection
local system, sayer_pre, sayer_post
if pcall(require, 'ffi') then
  system = require('ffi').os
elseif path.is_windows then
  system = 'Windows'
else
  system = io.popen('uname -s'):read('*l')
end

if system == 'Linux' then
  sayer_pre = 'espeak -s 160 '
  sayer_post = ' > /dev/null 2>&1'
elseif system and system:match('^Windows') then
  sayer_pre = 'echo '
  sayer_post = ' | ptts'
else
  sayer_pre = 'say '
  sayer_post = ''
end
system = nil

local options = {}
local current_context
local test_is_async

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
local get_time = os.clock
if pcall(require, "socket") then
  get_time = package.loaded["socket"].gettime
end

local language = function(lang)
  if lang then
    busted.messages = require('busted.languages.'..lang)
    require('luassert.languages.'..lang)
  end
end

-- load the outputter as set in the options, revert to default if it fails
local getoutputter  -- define first to enable recursion
getoutputter = function(output, opath, default)
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
    local pattern = pattern ~= "" and pattern or busted.defaultpattern
    filelist = dir.getallfiles(root_file)

    filelist = tablex.filter(filelist, function(filename)
      return path.basename(filename):find(pattern)
    end)

    filelist = tablex.filter(filelist, function(filename)
      if path.is_windows then
        return not filename:find('%\\%.%w+.%w+')
      else
        return not filename:find('/%.%w+.%w+')
      end
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

  local success, err = pcall(function() 
    local chunk,err
    if moon.is_moon(filename) then
      if moon.has_moon then
        chunk,err = moon.loadfile(filename)
      else
        chunk = function()
          busted.describe("Moon script not installed", function()
            pending("File not tested because 'moonscript' isn't installed; "..tostring(filename))
          end)
        end
      end      
    else
      chunk,err = loadfile(filename)
    end
    
    if not chunk then
      error(err,2)
    end
    chunk()
  end)

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
      io.popen(sayer_pre.."\""..busted.messages.failure_messages[math.random(1, #busted.messages.failure_messages)]:format(failures).."\""..sayer_post)
    else
      io.popen(sayer_pre.."\""..busted.messages.success_messages[math.random(1, #busted.messages.success_messages)].."\""..sayer_post)
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
  loop = require('busted.loop.default')
}

busted.step = function(...)
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

busted.async = function(f)
  test_is_async = true
  if not f then
    -- this allows async() to be called on its own to mark any test as async.
    return
  end
  local test = suite.tests[suite.test_index]

  local safef = function(...)
    local result = { suite.loop.pcall(f, ...) }

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

local match_tags = function(testName)
  if #options.tags > 0 then

    for t = 1, #options.tags do
      if testName:find(options.tags[t]) then
        return true
      end
    end

    return false
  else
    -- default to true if no tags are set
    return true
  end
end

local syncwrapper = function(f)
  return function(done, ...)
    test_is_async = nil
    f(done, ...)
    if not test_is_async then
      -- async function wasn't called, so it is a sync test/function
      -- hence must call it ourselves
      done()
    end
  end
end

-- wraps a done callback into a done-object supporting tokens to sign-off
local function wrap_done(done_callback)
  local obj = {
    tokens = {},
    tokens_done = {},
    done_cb = done_callback,

    ordered = true,  -- default for sign off of tokens

    -- adds tokens to the current wait list, does not change order/unordered
    wait = function(self, ...)
      local tlist = { ... }
      for _, token in ipairs(tlist) do
        if type(token) ~= "string" then
          error("Wait tokens must be strings. Got "..type(token), 2)
        end
        table.insert(self.tokens, token)
      end
    end,

    -- set list as unordered, adds tokens to current wait list
    wait_unordered = function(self, ...)
      self.ordered = false
      self:wait(...)
    end,

    -- set list as ordered, adds tokens to current wait list
    wait_ordered = function(self, ...)
      self.ordered = true
      self:wait(...)
    end,

    -- generates a message listing tokens received/open
    tokenlist = function(self)
      local list
      if #self.tokens_done == 0 then
        list = "No tokens received."
      else
        list = "Tokens received ("..tostring(#self.tokens_done)..")"
        local s = ": "
        for _,t in ipairs(self.tokens_done) do
          list = list .. s .. "'"..t.."'"
          s = ", "
        end
        list = list .. "."
      end
      if #self.tokens == 0 then
        list = list .. " No more tokens expected."
      else
        list = list .. " Tokens not received ("..tostring(#self.tokens)..")"
        local s = ": "
        for _, t in ipairs(self.tokens) do
          list = list .. s .. "'"..t.."'"
          s = ", "
        end
        list = list .. "."
      end
      return list
    end,
    
    -- marks a token as completed, checks for ordered/unordered, checks for completeness
    done = function(self, ...) self:_done(...) end,  -- extra wrapper for same error level constant as __call method
    _done = function(self, token)
      if token then
        if type(token) ~= "string" then
          error("Wait tokens must be strings. Got "..type(token), 3)
        end
        if self.ordered then
          if self.tokens[1] == token then
            table.remove(self.tokens, 1)
            table.insert(self.tokens_done, token)
          else
            if self.tokens[1] then
              error(("Bad token, expected '%s' got '%s'. %s"):format(self.tokens[1], token, self:tokenlist()), 3)
            else
              error(("Bad token (no more tokens expected) got '%s'. %s"):format(token, self:tokenlist()), 3)
            end
          end
        else
          -- unordered
          for i, t in ipairs(self.tokens) do
            if t == token then
              table.remove(self.tokens, i)
              table.insert(self.tokens_done, token)
              token = nil
              break
            end
          end
          if token then
            error(("Unknown token '%s'. %s"):format(token, self:tokenlist()), 3)
          end
        end
      end
      if not next(self.tokens) then
        -- no more tokens, so we're really done...
        self.done_cb()
      end
    end,
  }

  setmetatable( obj, {
    __call = function(self, ...)
      self:_done(...)
    end })

  return obj
end

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
      local timer
      local done = function()
        if timer then
          timer:stop()
          timer = nil
        end
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

      if suite.loop.create_timer then
        settimeout = function(timeout)
          if not timer then
            timer = suite.loop.create_timer(timeout,function()
              if not test.done_trace then
                test.status.type = 'failure'
                test.status.trace = ''
                test.status.err = 'test timeout elapsed ('..timeout..'s)'
                done()
              end
            end)
          end
        end
      else
        settimeout = nil
      end

      test.done = done

      local ok, err = suite.loop.pcall(test.f, wrap_done(done)) 
      if ok then
        if settimeout and not timer and not test.done_trace then
          settimeout(1.0)
        end
      else
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
          context.before(wrap_done(
            function()
              context.before = nil
              next()
            end))
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
              context.after(wrap_done(
                function()
                  context.after = nil
                  next()
                end))
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


busted.describe = function(desc, more)
  local context = create_context(desc)

  for _, parent in ipairs(current_context.parents) do
    context:add_parent(parent)
  end

  context:add_parent(current_context)

  local old_context = current_context

  current_context = context
  more()

  current_context = old_context
end

busted.before = function(before_func)
  assert(type(before_func) == "function", "Expected function, got "..type(before_func))
  current_context.before = syncwrapper(before_func)
end

busted.before_each = function(before_func)
  assert(type(before_func) == "function", "Expected function, got "..type(before_func))
  current_context.before_each = syncwrapper(before_func)
end

busted.after = function(after_func)
  assert(type(after_func) == "function", "Expected function, got "..type(after_func))
  current_context.after = syncwrapper(after_func)
end

busted.after_each = function(after_func)
  assert(type(after_func) == "function", "Expected function, got "..type(after_func))
  current_context.after_each = syncwrapper(after_func)
end

local function buildInfo(debug_info)
  local info = {
    source = debug_info.source,
    short_src = debug_info.short_src,
    linedefined = debug_info.linedefined,
  }

  local fname = get_fname(info.short_src)

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

  test.f = syncwrapper(function() end)

  test.status = {
    description = name,
    type = 'pending',
    info = buildInfo(debug_info)
  }

  if match_tags(test.name) then
    suite.tests[#suite.tests+1] = test
  end
end

busted.it = function(name, test_func)
  assert(type(test_func) == "function", "Expected function, got "..type(test_func))
  local test = {
    context = current_context,
    name = name
  }

  test.context:increment_test_count()

  local debug_info

  debug_info = debug.getinfo(test_func)
  test.f = syncwrapper(test_func)

  test.status = {
    description = test.name,
    type = 'success',
    info = buildInfo(debug_info)
  }

  if match_tags(test.name) then
    suite.tests[#suite.tests+1] = test
  end
end

busted.reset = function()
  current_context = create_context('Root context')

  suite = {
    tests = {},
    done = {},
    started = {},
    test_index = 1,
    loop = require('busted.loop.default')
  }
  busted.output = busted.output_reset
end

busted.setloop = function(loop)
  if type(loop) == 'string' then
     suite.loop = require('busted.loop.'..loop)
  else
     assert(loop.pcall)
     assert(loop.step)
     suite.loop = loop
  end
end

busted.run_internal_test = function(describe_tests)
  local suite_bak = suite
  local output_bak = busted.output
  local current_context_bak = current_context
  busted.reset()

  busted.output = require 'busted.output.stub'()
  suite = {
    tests = {},
    done = {},
    started = {},
    test_index = 1,
    loop = require('busted.loop.default')
  }

  if type(describe_tests) == 'function' then
     describe_tests()
  else
     load_testfile(describe_tests)
  end

  repeat
    next_test()
    suite.loop.step()
  until #suite.done == #suite.tests

  local statuses = {}

  for _, test in ipairs(suite.tests) do
    push(statuses, test.status)
  end

  suite = suite_bak
  current_context = current_context_bak
  busted.output = output_bak

  return statuses
end

-- test runner
busted.run = function(got_options)
  options = got_options

  language(options.lang)
  busted.output = getoutputter(options.output, options.fpath, busted.defaultoutput)
  busted.output_reset = busted.output  -- store in case we need a reset
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
      suite.loop.step()
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

busted.setup    = busted.before
busted.teardown = busted.after
it              = busted.it
pending         = busted.pending
describe        = busted.describe
before          = busted.before
after           = busted.after
setup           = busted.setup
teardown        = busted.teardown
before_each     = busted.before_each
after_each      = busted.after_each
step            = busted.step
setloop         = busted.setloop
async           = busted.async

return setmetatable(busted, {
  __call = function(self, ...)
    return busted.run(...)
  end
 })

