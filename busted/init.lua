local function init(busted)
  local block = require 'busted.block'(busted)

  local file = function(file)
    busted.wrap(file.run)
    if busted.safe_publish('file', { 'file', 'start' }, file) then
      block.execute('file', file)
    end
    busted.safe_publish('file', { 'file', 'end' }, file)
  end

  local describe = function(describe)
    local parent = busted.context.parent(describe)
    if busted.safe_publish('describe', { 'describe', 'start' }, describe, parent) then
      block.execute('describe', describe)
    end
    busted.safe_publish('describe', { 'describe', 'end' }, describe, parent)
  end

  local it = function(element)
    local parent = busted.context.parent(element)
    local finally
    local retries = 0
    local retry = 0

    if not block.lazySetup(parent) then
      -- skip test if any setup failed
      return
    end

    if not element.env then element.env = {} end

    block.rejectAll(element)
    element.env.finally = function(fn) finally = fn end
    element.env.pending = busted.pending
    element.env.set_retries = function(n)
      if type(n) ~= 'number' or n < 0 or n % 1 ~= 0 then
        error(('set_retries: expected non-negative integer, got: %s'):format(tostring(n)), 2)
      end
      retries = n
    end

    local pass, ancestor = block.execAll('before_each', parent, true)

    if pass then
      local status = busted.status('success')
      if busted.safe_publish('test', { 'test', 'start' }, element, parent) then
        local deferred = {}
        while true do
          if retry > 0 then
            -- Retrying: finish the failed attempt, then redo setup.
            finally = nil
            block.dexecAll('after_each', ancestor, true)
            pass, ancestor = block.execAll('before_each', parent, true)
            if not pass then
              break
            end
          end

          deferred = {}
          status = busted.status('success')
          status:update(busted.safe('it', element.run, element, deferred))
          if finally then
            block.reject('pending', element)
            status:update(busted.safe('finally', finally, element, deferred))
          end

          if not (status:failure() or status:error()) or retry >= retries then
            break
          end
          retry = retry + 1
        end

        -- Publish only the final attempt's events (see `deferred` in `busted.safe`).
        for _, event in ipairs(deferred) do
          busted.publish(event[1], event[2], event[3], event[4], event[5])
        end
      else
        status = busted.status('error')
      end
      busted.safe_publish('test', { 'test', 'end' }, element, parent, tostring(status))
    end

    block.dexecAll('after_each', ancestor, true)
  end

  local pending = function(element)
    local parent = busted.context.parent(element)
    local status = 'pending'
    if not busted.safe_publish('it', { 'test', 'start' }, element, parent) then
      status = 'error'
    end
    busted.safe_publish('it', { 'test', 'end' }, element, parent, status)
  end

  busted.register('file', file, { envmode = 'insulate' })

  busted.register('describe', describe)
  busted.register('insulate', 'describe', { envmode = 'insulate' })
  busted.register('expose', 'describe', { envmode = 'expose' })

  busted.register('it', it)

  busted.register('pending', pending, { default_fn = function() end })

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

  busted.hide('file')

  local assert = require 'luassert'
  local spy = require 'luassert.spy'
  local mock = require 'luassert.mock'
  local stub = require 'luassert.stub'
  local match = require 'luassert.match'

  require 'busted.fixtures'  -- just load into the environment, not exposing it

  busted.export('assert', assert)
  busted.export('spy', spy)
  busted.export('mock', mock)
  busted.export('stub', stub)
  busted.export('match', match)

  busted.exportApi('publish', busted.publish)
  busted.exportApi('subscribe', busted.subscribe)
  busted.exportApi('unsubscribe', busted.unsubscribe)

  busted.exportApi('bindfenv', busted.bindfenv)
  busted.exportApi('fail', busted.fail)
  busted.exportApi('gettime', busted.gettime)
  busted.exportApi('monotime', busted.monotime)
  busted.exportApi('sleep', busted.sleep)
  busted.exportApi('parent', busted.context.parent)
  busted.exportApi('children', busted.context.children)
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
