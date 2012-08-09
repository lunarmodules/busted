--interface:
--  output.short_status
--  output.descriptive_status
--  output.currently_executing

local json = require("dkjson")

local output = function()
  return {
    formatted_status = function(statuses, options, ms)
      return json.encode(statuses)
    end,

    currently_executing = function(test_status, options)
      io.write(json.encode(test_status))
      io.flush()
    end
  }
end

return output
