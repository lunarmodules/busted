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

pending = function(description, callback)
  local debug_info = debug.getinfo(callback)

  local info = {
    source = debug_info.source, 
    short_src = debug_info.short_src,  
    linedefined = debug_info.linedefined,
  }

  table.insert(current_context, { description = description, type = "pending", info = info })
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
  local pendings = 0

  for i,status in ipairs(statuses) do
    if status.type == "description" then
      local inner_short_status, inner_descriptive_status, inner_successes, inner_failures, inner_pendings = format_statuses(options, status)
      short_status = short_status..inner_short_status
      descriptive_status = descriptive_status..inner_descriptive_status
      successes = inner_successes + successes
      failures = inner_failures + failures
      pendings = inner_pendings + pendings
    elseif status.type == "success" then
      short_status = short_status..success_string()
      successes = successes + 1
    elseif status.type == "failure" then
      short_status = short_status..failure_string()
      descriptive_status = descriptive_status..error_description(status)
      if global_options.verbose then
        descriptive_status = descriptive_status.."\n"..status.trace
      end
      failures = failures + 1
    elseif status.type == "pending" then
      short_status = short_status..pending_string()
      pendings = pendings + 1

      if not options.suppress_pending then
        descriptive_status = descriptive_status..pending_description(status)
      end
    end
  end

  return short_status, descriptive_status, successes, failures, pendings
end

pending_description = function(status)
  if global_options.color then
    return "\n\n"..ansicolors("%{yellow}Pending").." → "..
    ansicolors("%{blue}"..status.info.short_src).." @ "..
    ansicolors("%{blue}"..status.info.linedefined)..
    "\n"..ansicolors("%{bright}"..status.description)
  end

  return "\n\n".."Pending Test".."\n"..status.description
end

error_description = function(status)
  if global_options.color then
    return "\n\n"..ansicolors("%{red}Failure").." → "..
           ansicolors("%{blue}"..status.info.short_src).." @ "..
           ansicolors("%{blue}"..status.info.linedefined)..
           "\n"..ansicolors("%{bright}"..status.description)
  end

  return "\n\nFailure in block \""..status.description.."\"\n→ "..status.info.short_src.." @ "..status.info.linedefined
end

success_string = function()
  if global_options.color then
    return ansicolors('%{green}●')
  end

  return "✓"
end

failure_string = function()
  if global_options.color then
    return ansicolors('%{red}●')
  end

  return "✗"
end

pending_string = function()
  if global_options.color then
    return ansicolors('%{yellow}●')
  end

  return "-"
end

status_string = function(short_status, descriptive_status, successes, failures, pendings, ms)
  local success_str = (success == 1) and " success" or " successes"
  local failures_str = (failures == 1) and " failure" or " failures"
  local pendings_str = " pending"

  if global_options.color then
    return short_status.."\n"..
           ansicolors('%{green}'..successes)..success_str..", "..
           ansicolors('%{red}'..failures)..failures_str..", and "..
           ansicolors('%{yellow}'..pendings)..pendings_str.." in "..
           ansicolors('%{bright}'..ms).." seconds."..descriptive_status
  end

  return short_status.."\n"..successes.." successes and "..failures.." failures in "..ms.." seconds."..descriptive_status
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

local busted = function(options)
  local ms = os.clock()

  global_options = options

  local statuses = run_context(global_context)

  if options.json then
    return json.encode(statuses)
  end

  local short_status, descriptive_status, successes, failures, pendings = format_statuses(options, statuses)

  ms = os.clock() - ms

  return status_string(short_status, descriptive_status, successes, failures, pendings, ms)
end

return busted
