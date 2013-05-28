local output = function()
  return {
    options = {},

    header = function(desc, test_count)
    end,


    formatted_status = function(statuses, options, ms)
    end,

    currently_executing = function(test_status, options)
    end
  }
end

return output

