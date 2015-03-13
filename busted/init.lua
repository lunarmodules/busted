local function init(busted)
  local block = require 'busted.block'(busted)

  local file = function(file)
    busted.wrap(file.run)
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

    if parent.setup_failed then
      -- skip all tests in a suite when the setup hook failed
      return
    end

    if not element.env then element.env = {} end

    block.rejectAll(element)
    element.env.finally = function(fn) finally = fn end
    element.env.pending = function(msg) busted.pending(msg) end

    local pass, ancestor = block.execAll('setup', parent, true)
    if not pass then
      parent.setup_failed = true
      return
    end

    pass, ancestor = block.execAll('before_each', parent, true)

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
    busted.context.test_executed()
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

  busted.export('assert', assert)
  busted.export('spy', spy)
  busted.export('mock', mock)
  busted.export('stub', stub)

  busted.exportApi('publish', busted.publish)
  busted.exportApi('subscribe', busted.subscribe)
  busted.exportApi('unsubscribe', busted.unsubscribe)

  busted.replaceErrorWithFail(assert)
  busted.replaceErrorWithFail(assert.is_true)

  return busted
end

return setmetatable({}, {
  __call = function(self, busted)
    init(busted)

    return setmetatable(self, {
      __index = function(self, key)
        return busted.modules[key]
      end,

      __newindex = function(self, key, value)
        error('Attempt to modify busted')
      end
    })
  end
})
