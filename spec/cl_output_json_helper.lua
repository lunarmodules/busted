return function(busted, helper, options)
  local non_string_spec = function(element)
    local parent = busted.context.parent(element)
    local status = 'custom'
    if busted.safe_publish('it', { 'test', 'start' }, element, parent) then
      busted.safe_publish('it', { 'test', 'end' }, element, parent, status)
    else
      status = 'error'
    end
  end

  busted.register('non_string_spec', non_string_spec, {
    default_fn = function() end,
    non_string_attribute_1 = function() end,
    non_string_attribute_2 = function() end,
    non_string_attribute_3 = function() end
  })
  return true
end
