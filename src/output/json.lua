--interface:
--  output.short_status
--  output.descriptive_status
--  output.currently_executing

local json = require("dkjson")

local output = function()
  return {
    header = function(desc, test_count)
    end,


    formatted_status = function(statuses, options, ms)
      if options.defer_print then
        index = 1
        local str = ""

        return json.encode(statuses)
      end

      return ""
    end,

    currently_executing = function(test_status, options)
      io.write(json.encode(test_status))
      io.flush()
    end
  }
end

return output
