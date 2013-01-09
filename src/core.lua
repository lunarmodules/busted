require "pl"

-- return truthy if we're in a coroutine
local function in_coroutine()
  local current_routine, main = coroutine.running()
  -- need check to the main variable for 5.2, it's nil for 5.1
  return current_routine and (main == nil or main == false)
end

local function language(lang)
  if lang then
    require('busted.languages.'..lang)
    require('luassert.languages.'..lang)
  end
end

local function getoutputter(output, opath, default)
  local success, out, f
  if output:match(".lua$") then
    f = function() return loadfile(path.normpath(path.join(opath, output)))() end
  else
    f = function() return require('busted.output.'..output)() end
  end
  
  success, out = pcall(f)
  if not success then
    if not default then
        -- even default failed, so error out the hard way
      return error("Failed to open the busted default output; " .. tostring(output) .. ".\n"..out)
    else
      busted.internal_error("Unable to open output module; requested option '--output=" .. tostring(output).."'.", out)
      -- retry with default outputter
      return getoutputter(default, opath)
    end
  end
  return out
end

local function gettestfiles(root_file, pattern)
  local filelist
  if path.isfile(root_file) then
    filelist = { root_file }
  elseif path.isdir(root_file) then
    local pattern = pattern ~= "" and pattern or defaultpattern
    filelist = dir.getallfiles(root_file)
    filelist = tablex.filter(filelist, function(filename)
        return path.basename(filename):find(pattern)
      end )      
  end
  return filelist
end

local function load_testfile(filename)
  -- runs a testfile
  local success, err = pcall(function() loadfile(filename)() end)
  if not success then
    busted.internal_error("Failed executing testfile; " .. tostring(filename), err)
  end
end

local busted = {
  root_context = { type = "describe", description = "global", before_each_stack = {}, after_each_stack = {} },
  options = {},

  internal_error = function(description, err)
    -- report a test-process error as a failed test
    local tag = ""
    if busted.options.tags and #busted.options.tags > 0 then
      -- tags specified; must insert a tag to make sure the error gets displayed
      tag = " #"..busted.options.tags[1] 
    end
    describe("Busted process errors occured" .. tag, function()
      it(description .. tag, function()
        error(err)
      end)
    end)
  end,

  __call = function(self)
    
    local failures = 0
    
    language(self.options.lang)
    self.output = getoutputter(self.options.output, self.options.fpath, self.defaultoutput)
    -- if no filelist given, get them
    self.options.filelist = self.options.filelist or gettestfiles(self.options.root_file, self.options.pattern)
    -- load testfiles
    tablex.foreachi(self.options.filelist, load_testfile)


   
    --run test
    local function test(description, callback, no_output)
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

      if not status then
        if type(err) == "table" then
          err = pretty.write(err)
        end

        test_status = { type = "failure", description = description, info = info, trace = stack_trace, err = err }
        failures = failures + 1
      else
        test_status = { type = "success", description = description, info = info }
      end

      if not no_output and not self.options.defer_print then
        self.output.currently_executing(test_status, self.options)
      end

      return test_status
    end

    -- run setup/teardown
    local function run_setup(context, stype, decsription)
      if not context[stype] then
        return true
      else
        if type(context[stype]) == "function" then
          local result = test("Failed running test initializer '"..stype.."'", context[stype], true)
          return (result.type == "success"), result
        elseif type(context[stype]) == "table" then
          if #context[stype] > 0 then
            local result

            for _,v in ipairs(context[stype]) do
              result = test("Failed running test initializer '"..decsription.."'", v, true)

              if result.type ~= "success" then
                return (result.type == "success"), result
              end
            end

            return (result.type == "success"), result
          else
            return true
          end
        end
      end
    end

    --run test case
    local function run_context(context)
      local match = false

      if self.options.tags and #self.options.tags > 0 then
        for _,t in ipairs(self.options.tags) do
          if context.description:find("#"..t) then
            match = true
          end
        end
      else
        match = true
      end

      local status = { description = context.description, type = "description", run = match }
      local setup_ok, setup_error

      setup_ok, setup_error = run_setup(context, "setup")

      if setup_ok then
        for _,v in ipairs(context) do
          if v.type == "test" then
            setup_ok, setup_error = run_setup(context, "before_each_stack", "before_each")
            if not setup_ok then break end

            table.insert(status, test(v.description, v.callback))

            setup_ok, setup_error = run_setup(context, "after_each_stack", "after_each")
            if not setup_ok then break end
          elseif v.type == "describe" then
            table.insert(status, coroutine.create(function() run_context(v) end))
          elseif v.type == "pending" then
            local pending_test_status = { type = "pending", description = v.description, info = v.info }
            v.callback(pending_test_status)
            table.insert(status, pending_test_status)
          end
        end
      end

      if setup_ok then setup_ok, setup_error = run_setup(context, "teardown") end

      if not setup_ok then table.insert(status, setup_error) end
      if in_coroutine() then
        coroutine.yield(status)
      else
        return true, status
      end
    end

    local play_sound = function(failures)
      math.randomseed(os.time())

      if self.failure_messages and #self.failure_messages > 0 and
         self.success_messages and #self.success_messages > 0 then
        if failures and failures > 0 then
          io.popen("say \""..self.failure_messages[math.random(1, #self.failure_messages)]:format(failures).."\"")
        else
          io.popen("say \""..self.success_messages[math.random(1, #self.success_messages)].."\"")
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
      for _,v in ipairs(list) do
        local vtype = type(v)
        if vtype == "thread" then
          local res = get_statuses(coroutine.resume(v))
          for _,value in pairs(res) do
            table.insert(ret, value)
          end
        elseif vtype == "table" then
          table.insert(ret, v)
        end
      end
      return ret
    end

    local old_TEST = _TEST
    _TEST = busted._VERSION
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

    if not self.options.defer_print then
      print(self.output.footer(self.root_context))
    end

    _TEST = old_TEST
    return status_string, failures
  end
}
return setmetatable(busted, busted)
