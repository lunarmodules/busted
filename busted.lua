local json = require("dkjson")

local ansicolors = require("lib/ansicolors")
local global_context = { type = "describe", description = "global" }
local current_context = global_context
local original_assert = assert
local global_options = {}

local equalTables = (function(traverse, equalTables)
  -- traverse a table, and test equality to another
  traverse = function(primary, secondary)
    -- use pairs for both the hash, and array part of the table
    for k,v in pairs(primary) do
      -- value is a table (do a deep equality), and the secondary value
      if not secondary or not secondary[k] then return false end
      local tableState, secondVal = type(v) == 'table', secondary[k]
      -- check for deep table inequality, or value inequality
      if (tableState and not equalTables(v, secondVal)) or (not tableState and v ~= secondVal) then
        return false
      end
    end
    -- passed all tests, the tables are equal
    return true
  end

  -- main equality function
  equalTables = function(first, second)
    -- traverse both first, and second tables to be sure of equality
    return traverse(first, second) and traverse(second, first)
  end

  -- return main function to keep traverse private
  return equalTables
end)()

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

test = function(description, callback)
  local debug_info = debug.getinfo(callback)
  local info = { 
    source = debug_info.source, 
    short_src = debug_info.short_src,  
    linedefined = debug_info.linedefined,
  } 

  if pcall(callback) then
    return { type = "success", description = "description", info = info }
  else
    return { type = "failure", description = "description", info = info, trace = debug.traceback() }
  end
end

spy_on = function(object, method)
end

mock = function(object)
end

before_each = function(callback)
  current_context.before_each = callback
end

after_each = function(callback)
  current_context.after_each = callback
end

format_statuses = function (options, statuses)
  local short_status = ""
  local descriptive_status = ""
  local successes = 0
  local failures = 0

  for i,status in ipairs(statuses) do
    if status.type == "description" then
      local inner_short_status, inner_descriptive_status, inner_successes, inner_failures = format_statuses(options, status)
      short_status = short_status..inner_short_status
      descriptive_status = descriptive_status..inner_descriptive_status
      successes = inner_successes + successes
      failures = inner_failures + failures
    elseif status.type == "success" then
      short_status = short_status..success_string()
      successes = successes + 1
    elseif status.type == "failure" then
      short_status = short_status..failure_string()
      descriptive_status = descriptive_status.."\n\nFailure in block \""..status.description.."\"\n"..status.short_src.." @ line "..status.line
      if global_options.verbose then
        descriptive_status = descriptive_status.."\n"..status.trace
      end
      failures = failures + 1
    end
  end

  return short_status, descriptive_status, successes, failures
end

success_string = function()
  if global_options.color then
    return ansicolors('%{green}✓')
  else
    return "✓"
  end
end

failure_string = function()
  if global_options.color then
    return ansicolors('%{red}✗')
  else
    return "✗"
  end
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
    end

    if context.after_each ~= nil then
      context.after_each()
    end
  end

  return status
end

local busted = function(options)
  local ms = os.clock()

  global_options = options

  local statuses = run_context(global_context)

  if options.json then
    return json.encode(statuses)
  end

  local short_status, descriptive_status, successes, failures = format_statuses(options, statuses)

  ms = os.clock() - ms

  return short_status.."\n "..successes.." successes and "..failures.." failures in "..ms.." seconds."
end

return busted
