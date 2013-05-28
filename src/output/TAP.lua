--interface:
--  output.short_status
--  output.descriptive_status
--  output.currently_executing

local s = require 'say'

local output = function()
  local success_string = function(test_index, test_status)
    return string.format("ok %d - %s", test_index, test_status.description)
  end

  local failure_string = function(test_index, test_status)
    return string.format("not ok %d - %s", test_index, test_status.description)
  end
  
  local error_description = function(status, options)
    return "\n\n"..s('output.failure')..": "..
           status.info.short_src.." @ "..
           status.info.linedefined..
           "\n"..status.description..
           "\n"..status.err
  end

  local pending_string = function(test_index, test_status, options)
    if not options.suppress_pending then
      return string.format("ok %d - #SKIP %s", test_index, test_status.description)
    end
  end

  local test_length = function(context_tree)
  end

  local strings = {
    failure = failure_string,
    success = success_string,
    pending = pending_string,
  }

  local index = 1

  test_length = function(context_tree)
    local length = 0

    for i,c in ipairs(context_tree) do
      if(c.type == "describe") then
        length = length + test_length(c)
      else
        length = length + 1
      end
    end

    return length
  end

  format_statuses = function (statuses, options)
    local short_status = ""
    local descriptive_status = ""
    local successes = 0
    local failures = 0
    local pendings = 0

    for i,status in ipairs(statuses) do
      if status.type == "description" then
        local inner_short_status, inner_descriptive_status, inner_successes, inner_failures, inner_pendings = format_statuses(status, options)
        successes = inner_successes + successes
        failures = inner_failures + failures
        pendings = inner_pendings + pendings
      elseif status.type == "success" then
        short_status = short_status..success_string(index, status).."\n"
        index = index + 1
        successes = successes + 1
      elseif status.type == "failure" then
        short_status = short_status..failure_string(index, status).."\n"
        descriptive_status = descriptive_status..error_description(status, options).."\n"
        index = index + 1
        failures = failures + 1
      elseif status.type == "pending" then
        short_status = short_status..pending_string(index, status, options).."\n"
        index = index + 1
        pendings = pendings + 1
      end
    end

    return short_status, descriptive_status, successes, failures, pendings
  end

  return {
    header = function(desc, test_count)
      io.write("1.."..test_count)
      io.flush()
    end,

    formatted_status = function(statuses, options, ms)
      if options.defer_print then
        index = 1
        local str = ""

        return format_statuses(statuses, options)
      end

      return ""
    end,

    currently_executing = function(test_status, options)
      print(strings[test_status.type](index, test_status, options))
      index = index + 1
    end
  }
end

return output
