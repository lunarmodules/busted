local pretty = require 'pl.pretty'

return function(options, busted)
  local language = require('busted.languages.' .. options.language)
  local handler = {}

  local isFailure = false

  handler.testEnd = function(element, parent, status)
    if status == 'failure' then
      isFailure = true
    end

    return nil, true
  end

  handler.suiteEnd = function(name, parent)
    local system, sayer_pre, sayer_post
    local messages

    if system == 'Linux' then
      sayer_pre = 'espeak -s 160 '
      sayer_post = ' > /dev/null 2>&1'
    elseif system and system:match('^Windows') then
      sayer_pre = 'echo '
      sayer_post = ' | ptts'
    else
      sayer_pre = 'say '
      sayer_post = ''
    end

    math.randomseed(os.time())

    if isFailure then
      messages = language.failure_messages
    else
      messages = language.success_messages
    end

    io.popen(sayer_pre .. '"' .. messages[math.random(1, #messages)] .. '"' .. sayer_post)

    return nil, true
  end

  handler.error = function(element, parent, message, debug)
    isFailure = true

    return nil, true
  end

  return handler
end
