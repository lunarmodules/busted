-- setup for stuff we use inside
local global_context = { type = "describe", description = "global" }
local current_context = global_context
local busted_options = {}

local s = require 'say.s'
s:set_namespace("en")

local output = require('output.utf_terminal')()

--setup luassert
assert = require 'luassert.assert'
require 'luassert.modifiers'
require 'luassert.assertions'

spy = require 'luassert.spy'
mock = require 'luassert.mock'

-- Internal functions
local split = function(string, sep)
  local sep, fields = sep or ".", {}
  local pattern = string.format("([^%s]+)", sep)
  string:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local function busted()

  local function test(description, callback)
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

    if err then
      test_status = { type = "failure", description = description, info = info, trace = stack_trace, err = err }
    else
      test_status = { type = "success", description = description, info = info }
    end

    if not busted_options.defer_print then
      output.currently_executing(test_status, busted_options)
    end

    return test_status
  end

  local function run_context(context)
    match = false

    if busted_options.tags and #busted_options.tags > 0 then
      for i,t in ipairs(busted_options.tags) do
        if string.find(context.description, "#"..t) then
          match = true
        end
      end
    else
      match = true
    end

    local status = { description = context.description, type = "description", run = match }

    if context.setup ~= nil then
      context.setup()
    end

    for i,v in ipairs(context) do
      if context.before_each ~= nil then
        context.before_each()
      end

      if v.type == "test" then
        table.insert(status, test(v.description, v.callback))
      elseif v.type == "describe" then
        table.insert(status, coroutine.create(function() run_context(v) end))
      elseif v.type == "pending" then
        local pending_test_status = { type = "pending", description = v.description, info = v.info }
        v.callback(pending_test_status)
        table.insert(status, pending_test_status)
      end

      if context.after_each ~= nil then
        context.after_each()
      end
    end

    if context.teardown ~= nil then
      context.teardown()
    end
    if coroutine.running() then
      coroutine.yield(status)
    else
      return true, status
    end
  end

  local play_sound = function(failures)
    local failure_messages = {
      "You have %d busted specs",
      "Your specs are busted",
      "Your code is bad and you should feel bad",
      "Your code is in the Danger Zone",
      "Strange game. The only way to win is not to test",
      "My grandmother wrote better specs on a 3 86",
      "Every time there's a failure, drink another beer",
      "Feels bad man"
    }

    local success_messages = {
      "Aww yeah, passing specs",
      "Doesn't matter, had specs",
      "Feels good, man",
      "Great success",
      "Tests pass, drink another beer",
    }

    math.randomseed(os.time())

    if failures > 0 then
      io.popen("say \""..string.format(failure_messages[math.random(1, #failure_messages)], failures).."\"")
    else
      io.popen("say \""..success_messages[math.random(1, #success_messages)].."\"")
    end
  end

  local ms = os.clock()

  if not busted_options.defer_print then
    print(output.header(global_context))
  end

  local function get_statuses(done, list)
    local ret = {}
    for i,v in pairs(list) do
      if type(v) == "thread" then
        local res = get_statuses(coroutine.resume(v))
        for key,value in pairs(res) do
          table.insert(ret, value)
        end
      elseif type(v) == "table" then
          table.insert(ret, v)
      end
    end
    return ret
  end

  local statuses = get_statuses(run_context(global_context))
  ms = os.clock() - ms

  if busted_options.defer_print then
    print(output.header(global_context))
  end

  local status_string = output.formatted_status(statuses, busted_options, ms)

  if busted_options.sound then
    play_sound(failures)
  end

  return status_string
end

-- External functions

describe = function(description, callback)
  match = current_context.run

  if busted_options.tags and #busted_options.tags > 0 then
    for i,t in ipairs(busted_options.tags) do
      if string.find(description, "#"..t) then
        match = true
      end
    end
  else
    match = true
  end

  local local_context = { description = description, callback = callback, type = "describe", run = match  }

  table.insert(current_context, local_context)

  current_context = local_context

  callback()

  current_context = global_context
end

it = function(description, callback)
  match = current_context.run

  if not match then
    if busted_options.tags and #busted_options.tags > 0 then
      for i,t in ipairs(busted_options.tags) do
        if string.find(description, "#"..t) then
          match = true
        end
      end
    end
  end

  if current_context.description ~= nil and match then
    table.insert(current_context, { description = description, callback = callback, type = "test" })
  elseif match then
    test(description, callback)
  end
end

pending = function(description, callback)
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
      if not busted_options.defer_print then
        output.currently_executing(self, busted_options)
      end
    end
  }

  table.insert(current_context, test_status)
end

before_each = function(callback)
  current_context.before_each = callback
end

after_each = function(callback)
  current_context.after_each = callback
end

setup = function(callback)
  current_context.setup = callback
end

teardown = function(callback)
  current_context.teardown = callback
end

set_busted_options = function(options)
  busted_options = options

  if busted_options.lang then
    s:set_namespace(busted_options.lang)
  end

  if busted_options.tags then
    busted_options.tags = split(busted_options.tags, ",")
  end

  if options.output_lib then
    output = require('output.'..options.output_lib)()
  end
end

return busted
