local function metatype(obj)
  local otype = type(obj)
  if otype == 'table' then
    local mt = getmetatable(obj)
    if mt and mt.__type then
      return mt.__type
    end
  end
  return otype
end

local failureMt = {
  __index = {},
  __tostring = function(e) return e.message end,
  __type = 'failure'
}

local pendingMt = {
  __index = {},
  __tostring = function(p) return p.message end,
  __type = 'pending'
}

local getfenv = require 'busted.compatibility'.getfenv
local setfenv = require 'busted.compatibility'.setfenv
local unpack = require 'busted.compatibility'.unpack
local pretty = require 'pl.pretty'
local throw = error

return function()
  local mediator = require 'mediator'()

  local busted = {}
  busted.version = '2.0.rc5-0'

  local root = require 'busted.context'()
  busted.context = root.ref()

  local environment = require 'busted.environment'(busted.context)

  busted.executors = {}
  local executors = {}

  busted.status = require 'busted.status'

  function busted.getTrace(element, level, msg)
    level = level or  3

    local info = debug.getinfo(level, 'Sl')
    while info.what == 'C' or info.short_src:match('luassert[/\\].*%.lua$') or
          info.short_src:match('busted[/\\].*%.lua$') do
      level = level + 1
      info = debug.getinfo(level, 'Sl')
    end

    info.traceback = debug.traceback('', level)
    info.message = msg

    local file = busted.getFile(element)
    return file.getTrace(file.name, info)
  end

  function busted.getErrorMessage(err)
    if getmetatable(err) and getmetatable(err).__tostring then
      return tostring(err)
    elseif type(err) ~= 'string' then
      return err and pretty.write(err) or 'Nil error'
    end

    return err
  end

  function busted.rewriteMessage(element, message, trace)
    local file = busted.getFile(element)

    return file.rewriteMessage and file.rewriteMessage(file.name, message) or message
  end

  function busted.publish(...)
    return mediator:publish(...)
  end

  function busted.subscribe(...)
    return mediator:subscribe(...)
  end

  function busted.getFile(element)
    local current, parent = element, busted.context.parent(element)

    while parent do
      if parent.file then
        local file = parent.file[1]
        return {
          name = file.name,
          getTrace = file.run.getTrace,
          rewriteMessage = file.run.rewriteMessage
        }
      end

      if parent.descriptor == 'file' then
        return {
          name = parent.name,
          getTrace = parent.run.getTrace,
          rewriteMessage = parent.run.rewriteMessage
        }
      end

      parent = busted.context.parent(parent)
    end

    return parent
  end

  function busted.fail(msg, level)
    local _, emsg = pcall(throw, msg, level+2)
    local e = { message = emsg }
    setmetatable(e, failureMt)
    throw(e, level+1)
  end

  function busted.pending(msg)
    local p = { message = msg }
    setmetatable(p, pendingMt)
    throw(p)
  end

  function busted.replaceErrorWithFail(callable)
    local env = {}
    local f = getmetatable(callable).__call or callable
    setmetatable(env, { __index = getfenv(f) })
    env.error = busted.fail
    setfenv(f, env)
  end

  function busted.wrapEnv(callable)
    if (type(callable) == 'function' or getmetatable(callable).__call) then
      -- prioritize __call if it exists, like in files
      environment.wrap(getmetatable(callable).__call or callable)
    end
  end

  function busted.safe(descriptor, run, element)
    busted.context.push(element)
    local trace, message
    local status = 'success'

    if not element.env then element.env = {} end

    element.env.error = function(msg, level)
      local level = level or 1
      _, message = pcall(throw, busted.getErrorMessage(msg), level+2)
      error(msg, level+1)
    end

    local ret = { xpcall(run, function(msg)
      local errType = metatype(msg)
      status = ((errType == 'pending' or errType == 'failure') and errType or 'error')
      trace = busted.getTrace(element, 3, msg)
      message = busted.rewriteMessage(element, message or tostring(msg), trace)
    end) }

    if not ret[1] then
      busted.publish({ status, descriptor }, element, busted.context.parent(element), message, trace)
    end
    ret[1] = busted.status(status)

    busted.context.pop()
    return unpack(ret)
  end

  function busted.register(descriptor, executor)
    executors[descriptor] = executor

    local publisher = function(name, fn)
      if not fn and type(name) == 'function' then
        fn = name
        name = nil
      end

      local trace

      local ctx = busted.context.get()
      if busted.context.parent(ctx) then
        trace = busted.getTrace(ctx, 3, name)
      end

      local publish = function(f)
        busted.publish({ 'register', descriptor }, name, f, trace)
      end

      if fn then publish(fn) else return publish end
    end

    busted.executors[descriptor] = publisher
    if descriptor ~= 'file' then
      environment.set(descriptor, publisher)
    end

    busted.subscribe({ 'register', descriptor }, function(name, fn, trace)
      local ctx = busted.context.get()
      local plugin = {
        descriptor = descriptor,
        name = name,
        run = fn,
        trace = trace
      }

      busted.context.attach(plugin)

      if not ctx[descriptor] then
        ctx[descriptor] = { plugin }
      else
        ctx[descriptor][#ctx[descriptor]+1] = plugin
      end
    end)
  end

  function busted.execute(current)
    if not current then current = busted.context.get() end
    for _, v in pairs(busted.context.children(current)) do
      local executor = executors[v.descriptor]
      if executor then
        busted.safe(v.descriptor, function() executor(v) end, v)
      end
    end
  end

  return busted
end
