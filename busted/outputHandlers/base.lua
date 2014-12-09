return function(busted)
  local handler = {
    successes = {},
    successesCount = 0,
    pendings = {},
    pendingsCount = 0,
    failures = {},
    failuresCount = 0,
    errors = {},
    errorsCount = 0,
    inProgress = {}
  }

  handler.cancelOnPending = function(element, parent, status)
    return not ((element.descriptor == 'pending' or status == 'pending') and handler.options.suppressPending)
  end

  handler.subscribe = function(handler, options)
    require('busted.languages.en')
    handler.options = options

    if options.language ~= 'en' then
      require('busted.languages.' .. options.language)
    end

    busted.subscribe({ 'suite', 'start' }, handler.baseSuiteStart)
    busted.subscribe({ 'suite', 'end' }, handler.baseSuiteEnd)
    busted.subscribe({ 'test', 'start' }, handler.baseTestStart, { predicate = handler.cancelOnPending })
    busted.subscribe({ 'test', 'end' }, handler.baseTestEnd, { predicate = handler.cancelOnPending })
    busted.subscribe({ 'pending' }, handler.basePending, { predicate = handler.cancelOnPending })
    busted.subscribe({ 'failure' }, handler.baseError)
    busted.subscribe({ 'error' }, handler.baseError)
  end

  handler.getFullName = function(context)
    local parent = busted.context.parent(context)
    local names = { (context.name or context.descriptor) }

    while parent and (parent.name or parent.descriptor) and
          parent.descriptor ~= 'file' do

      table.insert(names, 1, parent.name or parent.descriptor)
      parent = busted.context.parent(parent)
    end

    return table.concat(names, ' ')
  end

  handler.format = function(element, parent, message, debug, isError)
    local formatted = {
      trace = debug or element.trace,
      element = element,
      name = handler.getFullName(element),
      message = message,
      isError = isError
    }
    formatted.element.trace = element.trace or debug

    return formatted
  end

  handler.getDuration = function()
    if not handler.endTime or not handler.startTime then
      return 0
    end

    return handler.endTime - handler.startTime
  end

  handler.baseSuiteStart = function(name, parent)
    handler.startTime = os.clock()

    return nil, true
  end

  handler.baseSuiteEnd = function(name, parent)
    handler.endTime = os.clock()
    return nil, true
  end

  handler.baseTestStart = function(element, parent)
    handler.inProgress[tostring(element)] = {}
    return nil, true
  end

  handler.baseTestEnd = function(element, parent, status, debug)

    local isError
    local insertTable
    local id = tostring(element)

    if status == 'success' then
      insertTable = handler.successes
      handler.successesCount = handler.successesCount + 1
    elseif status == 'pending' then
      insertTable = handler.pendings
      handler.pendingsCount = handler.pendingsCount + 1
    elseif status == 'failure' then
      insertTable = handler.failures
      handler.failuresCount = handler.failuresCount + 1
    elseif status == 'error' then
      insertTable = handler.errors
      handler.errorsCount = handler.errorsCount + 1
      isError = true
    end

    insertTable[id] = handler.format(element, parent, element.message, debug, isError)

    if handler.inProgress[id] then
      for k, v in pairs(handler.inProgress[id]) do
        insertTable[id][k] = v
      end

      handler.inProgress[id] = nil
    end

    return nil, true
  end

  handler.basePending = function(element, parent, message, debug)
    if element.descriptor == 'it' then
      local id = tostring(element)
      handler.inProgress[id].message = message
      handler.inProgress[id].trace = debug
    end

    return nil, true
  end

  handler.baseError = function(element, parent, message, debug)
    if element.descriptor == 'it' then
      if parent.randomseed then
        message = 'Random Seed: ' .. parent.randomseed .. '\n' .. message
      end
      local id = tostring(element)
      handler.inProgress[id].message = message
      handler.inProgress[id].trace = debug
    else
      handler.errorsCount = handler.errorsCount + 1
      table.insert(handler.errors, handler.format(element, parent, message, debug, true))
    end

    return nil, true
  end

  return handler
end
