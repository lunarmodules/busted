local getfenv = require 'busted.compatibility'.getfenv
local unpack = require 'busted.compatibility'.unpack
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

  function block.reject(descriptor, element)
    local env = getfenv(element.run)
    if env[descriptor] then
      element.env[descriptor] = function(...)
        error("'" .. descriptor .. "' not supported inside current context block", 2)
      end
    end
  end

  function block.rejectAll(element)
    block.reject('randomize', element)
    for descriptor, _ in pairs(busted.executors) do
      block.reject(descriptor, element)
    end
  end

  local function exec(descriptor, element)
    if not element.env then element.env = {} end

    block.rejectAll(element)

    local parent = busted.context.parent(element)
    setmetatable(element.env, {
      __newindex = function(self, key, value)
        if not parent.env then parent.env = {} end
        parent.env[key] = value
      end
    })

    local ret = { busted.safe(descriptor, element.run, element) }
    return unpack(ret)
  end

  function block.execAll(descriptor, current, propagate, err)
    local parent = busted.context.parent(current)

    if propagate and parent then
      local success, ancestor = block.execAll(descriptor, parent, propagate)
      if not success then
        return success, ancestor
      end
    end

    local list = current[descriptor] or {}

    local success = true
    for _, v in pairs(list) do
      if not exec(descriptor, v):success() then
        if err then err(descriptor) end
        success = nil
      end
    end
    return success, current
  end

  function block.execAllOnce(descriptor, current, propagate, err)
    local key = descriptor .. '_result'
    local result = busted.context.get(key)
    if not result then
      result = {block.execAll(descriptor, current, propagate, err)}
      busted.context.set_parents(key, result)
    end
    return unpack(result)
  end

  function block.dexecAll(descriptor, current, propagate, err)
    local parent = busted.context.parent(current)
    local list = current[descriptor] or {}

    local success = true
    for _, v in pairs(list) do
      if not exec(descriptor, v):success() then
        if err then err(descriptor) end
        success = nil
      end
    end

    if propagate and parent then
      if not block.dexecAll(descriptor, parent, propagate) then
        success = nil
      end
    end
    return success
  end

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
      busted.execute(element)
      if busted.context.get('run_teardown') then
        block.dexecAll('teardown', element)
      end
    end
  end

  return block
end
