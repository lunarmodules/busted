local busted = {
  root_context = { type = "describe", description = "global" },
  options = {},

  __call = function(self)
    self.output = self.options.output

    --run test
    local function test(description, callback)
      local debug_info = debug.getinfo(callback)

      local info = {
        source = debug_info.source,
        short_src = debug_info.short_src,
        linedefined = debug_info.linedefined,
      }

      local stack_trace = ""

      local function err_handler(err)
        stack_trace = debug.traceback("", 4)
        return err
      end

      local status, err = xpcall(callback, err_handler)

      local test_status = {}

      if err then
        test_status = { type = "failure", description = description, info = info, trace = stack_trace, err = err }
      else
        test_status = { type = "success", description = description, info = info }
      end

      if not self.options.defer_print then
        self.output.currently_executing(test_status, self.options)
      end

      return test_status
    end

    --run test case
    local function run_context(context)
      local match = false

      if self.options.tags and #self.options.tags > 0 then
        for i,t in ipairs(self.options.tags) do
          if context.description:find("#"..t) then
            match = true
          end
        end
      else
        match = true
      end

      local status = { description = context.description, type = "description", run = match }

      if context.setup then
        context.setup()
      end

      for i,v in ipairs(context) do
        if context.before_each then
          context.before_each()
        end

        if v.type == "test" then
          table.insert(status, test(v.description, v.callback))
        elseif v.type == "describe" then
          table.insert(status, coroutine.create(function() run_context(v) end))
        elseif v.type == "pending" then
          local pending_test_status = { type = "pending", description = v.description, info = v.info }
          v.callback(pending_test_status)
          table.insert(status, pending_test_status)
        end

        if context.after_each then
          context.after_each()
        end
      end

      if context.teardown then
        context.teardown()
      end
      if coroutine.running() then
        coroutine.yield(status)
      else
        return true, status
      end
    end

    local play_sound = function(failures)
      math.randomseed(os.time())

      if self.options.failure_messages and #self.options.failure_messages > 0 and self.options.success_messages and #self.options.success_messages > 0 then
        if failures and failures > 0 then
          io.popen("say \""..failure_messages[math.random(1, #failure_messages)]:format(failures).."\"")
        else
          io.popen("say \""..success_messages[math.random(1, #success_messages)].."\"")
        end
      end
    end

    local ms = os.clock()

    if not self.options.defer_print then
      print(self.output.header(self.root_context))
    end

    --fire off tests, return status list
    local function get_statuses(done, list)
      local ret = {}
      for i,v in pairs(list) do
        local vtype = type(v)
        if vtype == "thread" then
          local res = get_statuses(coroutine.resume(v))
          for key,value in pairs(res) do
            table.insert(ret, value)
          end
        elseif vtype == "table" then
          table.insert(ret, v)
        end
      end
      return ret
    end
    local statuses = get_statuses(run_context(self.root_context))

    --final run time
    ms = os.clock() - ms

    if self.options.defer_print then
      print(self.output.header(self.root_context))
    end

    local status_string = self.output.formatted_status(statuses, self.options, ms)

    if self.options.sound then
      play_sound(failures)
    end

    return status_string
  end
}
return setmetatable(busted, busted)
