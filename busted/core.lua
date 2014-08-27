return function()
  local mediator = require 'mediator'()

  local busted = {}
  busted.version = '2.0.rc3-0'

  local root = require 'busted.context'()
  busted.context = root.ref()

  local environment = require 'busted.environment'(busted.context)

  busted.executors = {}
  local executors = {}

  busted.getTrace = function(element, level, msg)
    level = level or  3

    local info = debug.getinfo(level, 'Sl')
    info.traceback = debug.traceback('', level)
    info.message = msg

    local file = busted.getFile(element)
    return file.getTrace(file.name, info)
  end

  busted.rewriteMessage = function(element, message)
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

  function busted.safe(descriptor, run, element, setenv)
    if setenv and (type(run) == 'function' or getmetatable(run).__call) then
      -- prioritize __call if it exists, like in files
      environment.wrap(getmetatable(run).__call or run)
    end

    busted.context.push(element)
    local trace, message

    local ret = { xpcall(run, function(msg)
      message = busted.rewriteMessage(element, msg)
      trace = busted.getTrace(element, 3, msg)
    end) }

    if not ret[1] then
      busted.publish({ 'error', descriptor }, element, busted.context.parent(element), message, trace)
    end

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

      if descriptor ~= 'file' then
        trace = busted.getTrace(busted.context.get(), 3, name)
      end

      busted.publish({ 'register', descriptor }, name, fn, trace)
    end

    busted.executors[descriptor] = publisher
    environment.set(descriptor, publisher)

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
        busted.safe(v.descriptor, function() return executor(v) end, v)
      end
    end
  end

  return busted
end
