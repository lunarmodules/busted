return function()
  local function filter(busted, options)
    local getFullName = function(name)
      local parent = busted.context.get()
      local names = { name }

      while parent and (parent.name or parent.descriptor) and
            parent.descriptor ~= 'file' do
        table.insert(names, 1, parent.name or parent.descriptor)
        parent = busted.context.parent(parent)
      end

      return table.concat(names, ' ')
    end

    local hasTag = function(name, tag)
      local found = name:find('#' .. tag)
      return (found ~= nil)
    end

    local filterExcludeTags = function(name)
      for i, tag in pairs(options.excludeTags) do
        if hasTag(name, tag) then
          return nil, false
        end
      end
      return nil, true
    end

    local filterTags = function(name)
      local fullname = getFullName(name)
      for i, tag in pairs(options.tags) do
        if hasTag(fullname, tag) then
          return nil, true
        end
      end
      return nil, (#options.tags == 0)
    end

    local filterOutNames = function(name)
      for _, filter in pairs(options.filterOut) do
        if getFullName(name):find(filter) ~= nil then
          return nil, false
        end
      end
      return nil, true
    end

    local filterNames = function(name)
      for _, filter in pairs(options.filter) do
        if getFullName(name):find(filter) ~= nil then
          return nil, true
        end
      end
      return nil, (#options.filter == 0)
    end

    local printNameOnly = function(name, fn, trace)
      local fullname = getFullName(name)
      if trace and trace.what == 'Lua' then
        print(trace.short_src .. ':' .. trace.currentline .. ': ' .. fullname)
      else
        print(fullname)
      end
      return nil, false
    end

    local ignoreAll = function()
      return nil, false
    end

    local skipOnError = function()
      return nil, not busted.skipAll
    end

    local applyFilter = function(descriptors, name, fn)
      if options[name] and options[name] ~= '' then
        for _, descriptor in ipairs(descriptors) do
          busted.subscribe({ 'register', descriptor }, fn, { priority = 1 })
        end
      end
    end

    if options.list then
      busted.subscribe({ 'suite', 'start' }, ignoreAll, { priority = 1 })
      busted.subscribe({ 'suite', 'end' }, ignoreAll, { priority = 1 })
      applyFilter({ 'setup', 'teardown', 'before_each', 'after_each' }, 'list', ignoreAll)
      applyFilter({ 'lazy_setup', 'lazy_teardown' }, 'list', ignoreAll)
      applyFilter({ 'strict_setup', 'strict_teardown' }, 'list', ignoreAll)
      applyFilter({ 'it', 'pending' }, 'list', printNameOnly)
    end

    applyFilter({ 'lazy_setup', 'lazy_teardown' }, 'nokeepgoing', skipOnError)
    applyFilter({ 'strict_setup', 'strict_teardown' }, 'nokeepgoing', skipOnError)
    applyFilter({ 'setup', 'teardown', 'before_each', 'after_each' }, 'nokeepgoing', skipOnError)
    applyFilter({ 'file', 'describe', 'it', 'pending' }, 'nokeepgoing', skipOnError)

    -- The following filters are applied in reverse order
    applyFilter({ 'it', 'pending' }            , 'filter'     , filterNames      )
    applyFilter({ 'describe', 'it', 'pending' }, 'filterOut'  , filterOutNames   )
    applyFilter({ 'it', 'pending' }            , 'tags'       , filterTags       )
    applyFilter({ 'describe', 'it', 'pending' }, 'excludeTags', filterExcludeTags)
  end

  return filter
end
