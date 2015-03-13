
return function(busted)
  local block = require 'busted.block'(busted)

  local function execute(runs, options)
    busted.subscribe({'suite', 'reset'}, function()
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
        busted.publish({ 'suite', 'reset' })
      end

      local root = busted.context.get()
      busted.publish({ 'suite', 'start' }, i, runs)
      busted.execute()
      if busted.context.get('run_teardown') then
        block.dexecAll('teardown', root)
      end
      busted.publish({ 'suite', 'end' }, i, runs)

      if busted.skipAll then
        break
      end
    end
  end

  return execute
end
