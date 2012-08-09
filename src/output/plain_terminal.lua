--interface:
--  output.short_status
--  output.descriptive_status
--  output.currently_executing

local output = function()
  local pending_description = function(status, options)
    return "\n\n".."Pending: "..
    status.info.short_src.." @ "..
    status.info.linedefined..
    "\n"..status.description
  end

  local error_description = function(status, options)
    return "\n\n".."Failure: "..
           status.info.short_src.." @ "..
           status.info.linedefined..
           "\n"..status.description..
           "\n"..status.err
  end

  local success_string = function()
    return "+"
  end

  local failure_string = function()
    return "x"
  end

  local pending_string = function()
    return "-"
  end

  local running_string = function()
    return "."
  end

  local status_string = function(short_status, descriptive_status, successes, failures, pendings, ms, options)
    local success_str = (successes == 1) and " success" or " successes"
    local failures_str = (failures == 1) and " failure" or " failures"
    local pendings_str = " pending"

    if not options.defer_print then
      io.write("\08 ")
      short_status = ""
    end


    return short_status.."\n"..
           successes..success_str..", "..
           failures..failures_str..", and "..
           pendings..pendings_str.." in "..
           ms.." seconds."..descriptive_status
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
        short_status = short_status..inner_short_status
        descriptive_status = descriptive_status..inner_descriptive_status
        successes = inner_successes + successes
        failures = inner_failures + failures
        pendings = inner_pendings + pendings
      elseif status.type == "success" then
        short_status = short_status..success_string(options)
        successes = successes + 1
      elseif status.type == "failure" then
        short_status = short_status..failure_string(options)
        descriptive_status = descriptive_status..error_description(status, options)

        if options.verbose then
          descriptive_status = descriptive_status.."\n"..status.trace
        end

        failures = failures + 1
      elseif status.type == "pending" then
        short_status = short_status..pending_string(options)
        pendings = pendings + 1

        if not options.suppress_pending then
          descriptive_status = descriptive_status..pending_description(status, options)
        end
      end
    end

    return short_status, descriptive_status, successes, failures, pendings
  end

  local strings = {
    failure = failure_string,
    success = success_string,
    pending = pending_string,
  }

  return {
    options = {},

    header = function(context_tree)
    end,

    footer = function(context_tree)
    end,

    formatted_status = function(statuses, options, ms)
      local short_status, descriptive_status, successes, failures, pendings = format_statuses(statuses, options)
      return status_string(short_status, descriptive_status, successes, failures, pendings, ms, options)
    end,

    currently_executing = function(test_status, options)
      io.write("\08"..strings[test_status.type](options)..running_string(options))
      io.flush()
    end
  }
end

return output

