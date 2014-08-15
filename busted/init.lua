math.randomseed(os.time())

local function shuffle(t)
  local n = #t
  while n >= 2 do
    local k = math.random(n)
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
  return t
end

return function(busted)
  local function execAll(descriptor, current, propagate)
    local parent = busted.context.parent(current)

    if propagate and parent then execAll(descriptor, parent, propagate) end

    local list = current[descriptor]

    if list then
      for _, v in pairs(list) do
        busted.safe(descriptor, v.run, v)
      end
    end
  end

  local function dexecAll(descriptor, current, propagate)
    local parent = busted.context.parent(current)
    local list = current[descriptor]

    if list then
      for _, v in pairs(list) do
        busted.safe(descriptor, v.run, v)
      end
    end

    if propagate and parent then execAll(descriptor, parent, propagate) end
  end

  local file = function(file)
    busted.publish({ 'file', 'start' }, file.name)

    if busted.safe('file', file.run, file, true) then
      busted.execute(file)
    end

    busted.publish({ 'file', 'end' }, file.name)
  end

  local describe = function(describe)
    local parent = busted.context.parent(describe)

    busted.publish({ 'describe', 'start' }, describe, parent)

    if not describe.env then describe.env = {} end

    local randomize = false
    describe.env.randomize = function()
      randomize = true
    end

    if busted.safe('describe', describe.run, describe) then
      if randomize then
        shuffle(busted.context.children(describe))
      end
      execAll('setup', describe)
      busted.execute(describe)
      dexecAll('teardown', describe)
    end

    busted.publish({ 'describe', 'end' }, describe, parent)
  end

  local it = function(element)
    local finally

    if not element.env then element.env = {} end

    element.env.finally = function(fn)
      finally = fn
    end

    local parent = busted.context.parent(element)

    execAll('before_each', parent, true)

    busted.publish({ 'test', 'start' }, element, parent)
    busted.publish({ 'test', 'foo' }, element, parent)

    local res = busted.safe('element', element.run, element)
    if not element.env.done then
      local trace = busted.getTrace(element, 3)
      busted.publish({ 'test', 'end' }, element, parent, res and 'success' or 'failure', trace)
      if finally then busted.safe('finally', finally, element) end
      dexecAll('after_each', parent, true)
    end
  end

  local pending = function(element)
    local parent = busted.context.parent(pending)
    local trace = busted.getTrace(element, 3)
    busted.publish({ 'test', 'start' }, element, parent)
    busted.publish({ 'test', 'end' }, element, parent, 'pending', trace)
  end

  busted.register('file', file)

  busted.register('describe', describe)
  busted.register('context', describe)

  busted.register('it', it)
  busted.register('pending', pending)

  busted.register('setup')
  busted.register('teardown')
  busted.register('before_each')
  busted.register('after_each')

  assert = require 'luassert'
  spy    = require 'luassert.spy'
  mock   = require 'luassert.mock'
  stub   = require 'luassert.stub'

  return busted
end
