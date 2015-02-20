local function init(busted)
  local block = require 'busted.block'(busted)

  local file = function(file)
    busted.environment.wrap(file.run)
    busted.publish({ 'file', 'start' }, file.name)
    block.execute('file', file)
    busted.publish({ 'file', 'end' }, file.name)
  end

  local describe = function(describe)
    local parent = busted.context.parent(describe)
    busted.publish({ 'describe', 'start' }, describe, parent)
    block.execute('describe', describe)
    busted.publish({ 'describe', 'end' }, describe, parent)
  end

  local it = function(element)
    local parent = busted.context.parent(element)
    local finally

    busted.publish({ 'test', 'start' }, element, parent)

    if not element.env then element.env = {} end

    busted.rejectAll(element)
    element.env.finally = function(fn) finally = fn end
    element.env.pending = function(msg) busted.pending(msg) end

    local status = busted.status('success')
    local onError = function(descriptor)
      if element.message then element.message = element.message .. '\n' end
      element.message = (element.message or '') .. 'Error in ' .. descriptor
      status:update('error')
    end

    local pass, ancestor = busted.execAll('before_each', parent, true, onError)
    if pass then
      status:update(busted.safe('it', element.run, element))
    end

    if not element.env.done then
      busted.reject('pending', element)
      if finally then status:update(busted.safe('finally', finally, element)) end
      busted.dexecAll('after_each', ancestor, true, onError)
      busted.publish({ 'test', 'end' }, element, parent, tostring(status))
    end
  end

  local pending = function(element)
    local parent = busted.context.parent(element)
    busted.publish({ 'test', 'start' }, element, parent)
    busted.publish({ 'test', 'end' }, element, parent, 'pending')
  end

  busted.register('file', file)

  busted.register('describe', describe)

  busted.register('it', it)

  busted.register('pending', pending)

  busted.register('setup')
  busted.register('teardown')
  busted.register('before_each')
  busted.register('after_each')

  busted.alias('context', 'describe')
  busted.alias('spec', 'it')
  busted.alias('test', 'it')

  local assert = require 'luassert'
  local spy    = require 'luassert.spy'
  local mock   = require 'luassert.mock'
  local stub   = require 'luassert.stub'

  busted.environment.set('assert', assert)
  busted.environment.set('spy', spy)
  busted.environment.set('mock', mock)
  busted.environment.set('stub', stub)

  busted.replaceErrorWithFail(assert)
  busted.replaceErrorWithFail(assert.True)

  return busted
end

return setmetatable({}, {
  __call = function(self, busted)
    local root = busted.context.get()
    init(busted)

    return setmetatable(self, {
      __index = function(self, key)
        return rawget(root.env, key) or busted.executors[key]
      end,

      __newindex = function(self, key, value)
        error('Attempt to modify busted')
      end
    })
  end
})
