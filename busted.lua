require 'luassert.all'
local s = require 'say.s'
local global_context = { type = "describe", description = "global" }

local busted = {
  root_context = global_context,
  current_context = global_context,
  output = require 'output.utf_terminal'(),
  options = {},

  __call = function(self)
    --setup options
    s:set_namespace(self.options.lang)
    self.output = require('output.'..self.options.output_lib)()

    --run test
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

      if not self.options.defer_print then
        self.output.currently_executing(test_status, self.options)
      end

      return test_status
    end

    --run test case
    local function run_context(context)
      local match = false

      if self.options.tags and #self.options.tags > 0 then
        for i,t in ipairs(self.options.tags) do
          if context.description:find("#"..t) then
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
        io.popen("say \""..failure_messages[math.random(1, #failure_messages)]:format(failures).."\"")
      else
        io.popen("say \""..success_messages[math.random(1, #success_messages)].."\"")
      end
    end

    local ms = os.clock()

    if not self.options.defer_print then
      print(self.output.header(self.root_context))
    end

    --fire off tests, return status list
    local function get_statuses(done, list)
      local ret = {}
      for i,v in pairs(list) do
        local vtype = type(v)
        if vtype == "thread" then
          local res = get_statuses(coroutine.resume(v))
          for key,value in pairs(res) do
            table.insert(ret, value)
          end
        elseif vtype == "table" then
          table.insert(ret, v)
        end
      end
      return ret
    end
    local statuses = get_statuses(run_context(self.root_context))

    --final run time
    ms = os.clock() - ms

    if self.options.defer_print then
      print(self.output.header(self.root_context))
    end

    local status_string = self.output.formatted_status(statuses, self.options, ms)

    if self.options.sound then
      play_sound(failures)
    end

    return status_string
  end
}
busted = setmetatable(busted, busted)

-- Global functions
describe = function(description, callback)
  local match = busted.current_context.run

  if busted.options.tags and #busted.options.tags > 0 then
    for i,t in ipairs(busted.options.tags) do
      if description:find("#"..t) then
        match = true
      end
    end
  else
    match = true
  end

  local local_context = { description = description, callback = callback, type = "describe", run = match  }

  table.insert(busted.current_context, local_context)

  busted.current_context = local_context

  callback()

  busted.current_context = busted.root_context
end

it = function(description, callback)
  local match = busted.current_context.run

  if not match then
    if busted.options.tags and #busted.options.tags > 0 then
      for i,t in ipairs(busted.options.tags) do
        if description:find("#"..t) then
          match = true
        end
      end
    end
  end

  if busted.current_context.description ~= nil and match then
    table.insert(busted.current_context, { description = description, callback = callback, type = "test" })
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
      if not busted.options.defer_print then
        busted.output.currently_executing(self, busted.options)
      end
    end
  }

  table.insert(busted.current_context, test_status)
end

before_each = function(callback)
  busted.current_context.before_each = callback
end

after_each = function(callback)
  busted.current_context.after_each = callback
end

setup = function(callback)
  busted.current_context.setup = callback
end

teardown = function(callback)
  busted.current_context.teardown = callback
end

return busted
