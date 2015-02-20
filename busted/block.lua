local shuffle = require 'busted.utils'.shuffle

local function sort(elements)
  table.sort(elements, function(t1, t2)
    if t1.name and t2.name then
      return t1.name < t2.name
    end
    return t2.name ~= nil
  end)
  return elements
end

return function(busted)
  local block = {}

  function block.execute(descriptor, element)
    if not element.env then element.env = {} end

    local randomize = busted.randomize
    element.env.randomize = function() randomize = true end

    if busted.safe(descriptor, element.run, element):success() then
      if randomize then
        element.randomseed = busted.randomseed
        shuffle(busted.context.children(element), busted.randomseed)
      elseif busted.sort then
        sort(busted.context.children(element))
      end
      if busted.execAll('setup', element) then
        busted.execute(element)
      end
      busted.dexecAll('teardown', element)
    end
  end

  return block
end
