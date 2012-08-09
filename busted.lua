require("lib/assert")

-- setup for stuff we use inside
local global_context = { type = "describe", description = "global" }
local current_context = global_context
local busted_options = {}

output = require("src/output/utf_terminal")()

-- Internal functions

local test = function(description, callback)
  local debug_info = debug.getinfo(callback)

  local info = {
    source = debug_info.source, 
    short_src = debug_info.short_src,  
    linedefined = debug_info.linedefined,
  }

  local status, err = pcall(callback)

  local test_status = { type = "success", description = description, info = info }

  if err then
    test_status = { type = "failure", description = description, info = info, trace = debug.traceback(), err = err }
  end

  if not busted_options.defer_print then
    output.currently_executing(test_status, busted_options)
  end

  return test_status
end

run_context = function(context)
  local status = { description = context.description, type = "description" }

  for i,v in ipairs(context) do
    if context.before_each ~= nil then
      context.before_each()
    end

    if v.type == "test" then
      table.insert(status, test(v.description, v.callback))
    elseif v.type == "describe" then
      table.insert(status, run_context(v))
    elseif v.type == "pending" then
      table.insert(status, { type = "pending", description = v.description, info = v.info })
    end

    if context.after_each ~= nil then
      context.after_each()
    end
  end

  return status
end

local play_sound = function(failures)
  local failure_messages = {
    "You have %d busted specs",
    "Your specs are busted",
    "Your code is bad and you should feel bad",
  }

  local success_messages = {
    "Aww yeah, passing specs",
    "Doesn't matter, had specs",
    "Feels good, man",
  }

  math.randomseed(os.time())

  if failures > 0 then
    os.execute("say \""..string.format(failure_messages[math.random(1, #failure_messages)], failures).."\"")
  else
    os.execute("say \""..success_messages[math.random(1, #failure_messages)].."\"")
  end
end

local busted = function()
  local ms = os.clock()
  local statuses = run_context(global_context)

  ms = os.clock() - ms

  if busted_options.sound then
    play_sound(failures)
  end

  return output.formatted_status(statuses, busted_options, ms)
end

-- External functions

describe = function(description, callback)
  local local_context = { description = description, callback = callback, type = "describe"  }

  table.insert(current_context, local_context)

  current_context = local_context

  callback()

  current_context = global_context
end

it = function(description, callback)
  if current_context.description ~= nil then
    table.insert(current_context, { description = description, callback = callback, type = "test" })
  else
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

  local test_status = { description = description, type = "pending", info = info }

  table.insert(current_context, test_status)

  if not busted_options.defer_print then
    output.currently_executing(test_status, busted_options)
  end
end

spy_on = function(object, method)
  error("Not implemented yet!")
end

mock = function(object)
  error("Not implemented yet!")
end

before_each = function(callback)
  current_context.before_each = callback
end

after_each = function(callback)
  current_context.after_each = callback
end

set_busted_options = function(options)
  busted_options = options

  if options.output_lib then
    output = require("src/output/"..options.output_lib)()
  end
end

return busted
