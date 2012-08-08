statuses = {}
local cjson = require("cjson")

local ansicolors = require("lib/ansicolors")
local current_context = {}
local context = { current_context }
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

  for i,v in ipairs(local_context) do
    if local_context.before_each ~= nil then
      local_context.before_each()
    end

    if v.type == "test" then
      test(v.description, v.callback)
    end

    if local_context.after_each ~= nil then
      local_context.after_each()
    end
  end
end

it = function(description, callback)
  if current_context.description ~= nil then
    table.insert(current_context, { description = description, callback = callback, type = "test" })
  else
    test(description, callback)
  end
end

test = function(description, callback)
  if pcall(callback) then
    table.insert(statuses, { type = "success"  })
  else
    info = debug.getinfo(callback)
    table.insert(statuses, { type = "failure", description = description, trace = debug.traceback(), short_src = info.short_src, line = info.linedefined  })
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

local format_statuses = function (options, statuses)
  short_status = ""
  descriptive_status = ""

  for i,status in ipairs(statuses) do
    if status.type == "success" then
      short_status = short_status..success_string()
    else
      short_status = short_status..error_string()
      descriptive_status = descriptive_status.."\n\nFailure in block \""..status.description.."\"\n"..status.short_src.." @ line "..status.line
      if global_options.verbose then
        descriptive_status = descriptive_status.."\n"..status.trace
      end
    end
  end

  return short_status..descriptive_status
end

success_string = function()
  if global_options.color then
    return ansicolors('%{green}✓')
  else
    return "✓"
  end
end

error_string = function()
  if global_options.color then
    return ansicolors('%{red}✗')
  else
    return "✗"
  end
end

local busted = function(options)
  global_options = options

  if options.json then
    return cjson.encode(statuses)
  end

  return format_statuses(options, statuses)
end

return busted
