return function()
  local context = {}

  local data = {}
  local parents = {}
  local children = {}
  local stack = {}

  function context.ref()
    local ref = {}
    local ctx = data

    function ref.get(key)
      if not key then return ctx end
      return ctx[key]
    end

    function ref.set(key, value)
      ctx[key] = value
    end

    function ref.attach(child)
      if not children[ctx] then children[ctx] = {} end
      parents[child] = ctx
      table.insert(children[ctx], child)
    end

    function ref.children(parent)
      return children[parent] or {}
    end

    function ref.parent(child)
      return parents[child]
    end

    function ref.push(current)
      if not parents[current] then error('Detached child. Cannot push.') end
      table.insert(stack, ctx)
      ctx = current
    end

    function ref.pop()
      local current = ctx
      ctx = table.remove(stack)
      if not ctx then error('Context stack empty. Cannot pop.') end
    end

    return ref
  end

  return context
end
