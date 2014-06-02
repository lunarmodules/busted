return function()
  local context = {}

  local data = {}
  local parents = {}
  local children = {}

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
      children[ctx][#children[ctx]+1] = child
    end

    function ref.children(parent)
      return children[parent] or {}
    end

    function ref.parent(child)
      return parents[child]
    end

    function ref.push(child)
      if not parents[child] then error('Detached child. Cannot push.') end
      ctx = child
    end

    function ref.pop()
      ctx = parents[ctx]
    end

    return ref
  end

  return context
end
