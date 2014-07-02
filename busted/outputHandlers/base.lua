return function(busted)
  local handler = { }

  handler.subscribe = function(handler, busted, options)
    require('busted.languages.en')

    if options.language ~= 'en' then
      require('busted.languages.' .. options.language)
    end

    busted.subscribe({ 'suite', 'start' }, handler.baseSuiteStart)
    busted.subscribe({ 'suite', 'end' }, handler.baseSuiteEnd)
    busted.subscribe({ 'test', 'start' }, handler.baseTestStart)
    busted.subscribe({ 'test', 'end' }, handler.baseTestEnd)
    busted.subscribe({ 'error', 'it' }, handler.baseError)
    busted.subscribe({ 'error', 'file' }, handler.baseError)
    busted.subscribe({ 'error', 'pending' }, handler.baseError)

    busted.subscribe({ 'test', 'start' }, handler.testStart)
    busted.subscribe({ 'test', 'end' }, handler.testEnd)
    busted.subscribe({ 'file', 'start' }, handler.fileStart)
    busted.subscribe({ 'file', 'end' }, handler.fileEnd)
    busted.subscribe({ 'suite', 'start' }, handler.suiteStart)
    busted.subscribe({ 'suite', 'end' }, handler.suiteEnd)
    busted.subscribe({ 'error', 'file' }, handler.error)
    busted.subscribe({ 'error', 'pending' }, handler.error)
    busted.subscribe({ 'error', 'describe' }, handler.failure)
    busted.subscribe({ 'error', 'it' }, handler.failure)
  end

  handler.getFullName = function(context)
    local parent = busted.context.parent(context)
    local names = { (context.name or context.descriptor) }

    while parent and (parent.name or parent.descriptor) and
          parent.descriptor ~= 'file' do

      current_context = context.parent
      table.insert(names, 1, parent.name or parent.descriptor)
      parent = busted.context.parent(parent)
    end

    return table.concat(names, ' ')
  end


  handler.format = function(element, parent, message, debug, isError)
    local formatted = {
      trace = element.trace or debug,
      name = handler.getFullName(element),
      message = message,
      isError = isError
    }

    return formatted
  end

  handler.successes = {}
  handler.successesCount = 0

  handler.pendings = {}
  handler.pendingsCount = 0

  handler.failures = {}
  handler.failuresCount = 0

  handler.errors = {}
  handler.errorsCount = 0

  handler.inProgress = {}

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
    end

    insertTable[id] = handler.format(element, parent, nil, debug)

    if handler.inProgress[id] then
      for k, v in pairs(handler.inProgress[id]) do
        insertTable[id][k] = v
      end

      handler.inProgress[id] = nil
    end

    return nil, true
  end

  handler.baseError = function(element, parent, message, debug)
    if element.descriptor == 'it' then
      handler.inProgress[tostring(element)].message = message
    else
      handler.errorsCount = handler.errorsCount + 1
      table.insert(handler.errors, handler.format(element, parent, message, debug, true))
    end

    return nil, true
  end

  -- Overwrite these

  handler.testStart = function(name, parent)
    return nil, true
  end

  handler.testEnd = function(element, parent, status)
    return nil, true
  end

  handler.fileStart = function(name, parent)
    return nil, true
  end

  handler.fileEnd = function(name, parent)
    return nil, true
  end

  handler.suiteStart = function(name, parent)
    return nil, true
  end

  handler.suiteEnd = function(name, parent)
    return nil, true
  end

  handler.failure = function(element, parent, message, debug)
    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    return nil, true
  end

  return handler
end
