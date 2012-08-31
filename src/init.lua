-- Expose luassert elements as part of global interfcae
assert = require('luassert')
spy = require('luassert.spy')
mock = require('luassert.mock')

-- Load default language pack
require('busted.languages.en')

-- Load and expose busted core as part of global interface
busted = require('busted.core')

local current_context = busted.root_context

-- Global functions
describe = function(description, callback)
  local match = current_context.run

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

  table.insert(current_context, local_context)

  current_context = local_context

  callback()

  current_context = busted.root_context
end

it = function(description, callback)
  local match = current_context.run

  if not match then
    if busted.options.tags and #busted.options.tags > 0 then
      for i,t in ipairs(busted.options.tags) do
        if description:find("#"..t) then
          match = true
        end
      end
    end
  end

  if current_context.description and match then
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
      if not busted.options.defer_print then
        busted.output.currently_executing(self, busted.options)
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
