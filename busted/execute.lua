
return function(busted)
  local function execute(runs, options)
    busted.subscribe({'suite', 'reinitialize'}, function()
      local oldctx = busted.context.get()
      local children = busted.context.children(oldctx)

      busted.context.clear()
      local ctx = busted.context.get()
      for k, v in pairs(oldctx) do
        ctx[k] = v
      end

      for _, child in pairs(children) do
        for descriptor, _ in pairs(busted.executors) do
          child[descriptor] = nil
        end
        busted.context.attach(child)
      end

      busted.randomseed = tonumber(options.seed) or os.time()

      return nil, true
    end)

    for i = 1, runs do
      if i > 1 then
        busted.publish({ 'suite', 'reinitialize' })
      end

      busted.publish({ 'suite', 'start' }, i, runs)
      busted.execute()
      busted.publish({ 'suite', 'end' }, i, runs)

      if busted.skipAll then
        break
      end
    end
  end

  return execute
end
