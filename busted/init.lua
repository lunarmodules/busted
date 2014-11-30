math.randomseed(os.time())

local function shuffle(t, seed)
  if seed then math.randomseed(seed) end
  local n = #t
  while n >= 2 do
    local k = math.random(n)
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
  return t
end

return function(busted)
  local function remove(descriptors, element)
    for _, descriptor in ipairs(descriptors) do
      element.env[descriptor] = function(...)
        error("'" .. descriptor .. "' not supported inside current context block", 2)
      end
    end
  end

  local function exec(descriptor, element)
      if not element.env then element.env = {} end

      remove({ 'randomize' }, element)
      remove({ 'pending' }, element)
      remove({ 'describe', 'context', 'it', 'spec', 'test' }, element)
      remove({ 'setup', 'teardown', 'before_each', 'after_each' }, element)

      local ret = { busted.safe(descriptor, element.run, element) }
      return unpack(ret)
  end

  local function execAll(descriptor, current, propagate)
    local parent = busted.context.parent(current)

    if propagate and parent then execAll(descriptor, parent, propagate) end

    local list = current[descriptor] or {}

    for _, v in pairs(list) do
      exec(descriptor, v)
    end
  end

  local function dexecAll(descriptor, current, propagate)
    local parent = busted.context.parent(current)
    local list = current[descriptor] or {}

    for _, v in pairs(list) do
      exec(descriptor, v)
    end

    if propagate and parent then dexecAll(descriptor, parent, propagate) end
  end

  local file = function(file)
    busted.publish({ 'file', 'start' }, file.name)

    busted.wrapEnv(file.run)
    if not file.env then file.env = {} end

    local randomize = false
    file.env.randomize = function()
      randomize = true
    end

    if busted.safe('file', file.run, file) == 'success' then
      if randomize then
        file.randomseed = busted.randomseed
        shuffle(busted.context.children(file), busted.randomseed)
      end
      execAll('setup', file)
      busted.execute(file)
      dexecAll('teardown', file)
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

    if busted.safe('describe', describe.run, describe) == 'success' then
      if randomize then
        describe.randomseed = busted.randomseed
        shuffle(busted.context.children(describe), busted.randomseed)
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

    remove({ 'randomize' }, element)
    remove({ 'describe', 'context', 'it', 'spec', 'test' }, element)
    remove({ 'setup', 'teardown', 'before_each', 'after_each' }, element)
    element.env.finally = function(fn) finally = fn end
    element.env.pending = function(msg) busted.pending(msg) end

    local parent = busted.context.parent(element)

    execAll('before_each', parent, true)

    busted.publish({ 'test', 'start' }, element, parent)

    local status = busted.safe('element', element.run, element)
    if not element.env.done then
      remove({ 'pending' }, element)
      busted.publish({ 'test', 'end' }, element, parent, status)
      if finally then busted.safe('finally', finally, element) end
      dexecAll('after_each', parent, true)
    end
  end

  local pending = function(element)
    local parent = busted.context.parent(pending)
    busted.publish({ 'test', 'start' }, element, parent)
    busted.publish({ 'test', 'end' }, element, parent, 'pending')
  end

  busted.register('file', file)

  busted.register('describe', describe)
  busted.register('context', describe)

  busted.register('it', it)
  busted.register('spec', it)
  busted.register('test', it)

  busted.register('pending', pending)

  busted.register('setup')
  busted.register('teardown')
  busted.register('before_each')
  busted.register('after_each')

  assert = require 'luassert'
  spy    = require 'luassert.spy'
  mock   = require 'luassert.mock'
  stub   = require 'luassert.stub'

  busted.replaceErrorWithFail(assert)
  busted.replaceErrorWithFail(assert.True)

  return busted
end
