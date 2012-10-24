--[[
--jUnit output formatter for busted
--ReMake Electric ehf 2012
--Considered to be released under your choice of Apache, 2 clause BSD, ISC or MIT licenses
--]]
--
local output = function()

  local function make_test_xml(index, blob)
    local xx = string.format([[<testcase classname="%s" name="%s">]],
      blob.info.short_src:gsub(".lua", ""), blob["description"])
    local failtext = ""
    if (blob["type"] == "failure") then
      failtext =  "\n" .. string.format([[
<failure type="busted.generalfailure">%s</failure>
  ]], blob.err)
    end
    return (xx .. failtext .. "</testcase>") 
  end

  return {
    header = function(context_tree)
      return [[<?xml version="1.0" encoding="UTF-8" ?>]]
    end,

    footer = function(context_tree)
      -- current busted is busted ;)
      --return("</testsuite>")
    end,

    formatted_status = function(status, options, ms)
      io.write([[<testsuite name="busted_luatests">]], "\n")
      for i,v in ipairs(status) do
        local test_xml = make_test_xml(i, v)
        io.write(test_xml, "\n")
      end
      io.write("</testsuite>", "\n")
      return ("")
    end,

    currently_executing = function(test_status, options)
      return ("")
    end
  }
end

return output
