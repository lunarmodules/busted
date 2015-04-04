local function init(busted)
  local block = require 'busted.block'(busted)

  local file = function(file)
    busted.wrap(file.run)
    busted.publish({ 'file', 'start' }, file)
    block.execute('file', file)
    busted.publish({ 'file', 'end' }, file)
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

    if not block.lazySetup(parent) then
      -- skip test if any setup failed
      return
    end

    if not element.env then element.env = {} end

    block.rejectAll(element)
    element.env.finally = function(fn) finally = fn end
    element.env.pending = function(msg) busted.pending(msg) end

    local pass, ancestor = block.execAll('before_each', parent, true)

    if pass then
      local status = busted.status('success')
      busted.publish({ 'test', 'start' }, element, parent)
      status:update(busted.safe('it', element.run, element))
      if finally then
        block.reject('pending', element)
        status:update(busted.safe('finally', finally, element))
      end
      busted.publish({ 'test', 'end' }, element, parent, tostring(status))
    end

    block.dexecAll('after_each', ancestor, true)
  end

  local pending = function(element)
    local parent = busted.context.parent(element)
    busted.publish({ 'test', 'start' }, element, parent)
    busted.publish({ 'test', 'end' }, element, parent, 'pending')
  end

  busted.register('file', file, { envmode = 'insulate' })

  busted.register('describe', describe)
  busted.register('insulate', 'describe', { envmode = 'insulate' })
  busted.register('expose', 'describe', { envmode = 'expose' })

  busted.register('it', it)

  busted.register('pending', pending)

  busted.register('before_each', { envmode = 'unwrap' })
  busted.register('after_each', { envmode = 'unwrap' })

  busted.register('lazy_setup', { envmode = 'unwrap' })
  busted.register('lazy_teardown', { envmode = 'unwrap' })
  busted.register('strict_setup', { envmode = 'unwrap' })
  busted.register('strict_teardown', { envmode = 'unwrap' })

  busted.register('setup', 'strict_setup')
  busted.register('teardown', 'strict_teardown')

  busted.register('context', 'describe')
  busted.register('spec', 'it')
  busted.register('test', 'it')

  local assert = require 'luassert'
  local spy    = require 'luassert.spy'
  local mock   = require 'luassert.mock'
  local stub   = require 'luassert.stub'

  busted.export('assert', assert)
  busted.export('spy', spy)
  busted.export('mock', mock)
  busted.export('stub', stub)

  busted.exportApi('publish', busted.publish)
  busted.exportApi('subscribe', busted.subscribe)
  busted.exportApi('unsubscribe', busted.unsubscribe)

  busted.exportApi('bindfenv', busted.bindfenv)
  busted.exportApi('fail', busted.fail)
  busted.exportApi('parent', busted.context.parent)
  busted.exportApi('version', busted.version)

  busted.bindfenv(assert, 'error', busted.fail)
  busted.bindfenv(assert.is_true, 'error', busted.fail)

  return busted
end

return setmetatable({}, {
  __call = function(self, busted)
    init(busted)

    return setmetatable(self, {
      __index = function(self, key)
        return busted.api[key]
      end,

      __newindex = function(self, key, value)
        error('Attempt to modify busted')
      end
    })
  end
})
