
local path = require("pl.path")
local ditch = " > /dev/null 2>&1"
if path.is_windows then
  ditch = " 1> NUL 2>NUL"
end
--ditch = ""  -- uncomment this line, to show output of failing commands, for debugging

local error_started
local error_start = function()
  if ditch ~= "" then return end
  print("================================================")
  print("==  Error block follows                       ==")
  print("================================================")
  error_started = true
end
local error_end = function()
  if ditch ~= "" then return end
  print("================================================")
  print("==  Error block ended, all according to plan  ==")
  print("================================================")
  error_started = false
end

-- if exitcode >256, then take MSB as exit code
local modexit = function(exitcode)
  if exitcode>255 then
    return math.floor(exitcode/256), exitcode - math.floor(exitcode/256)*256
  else
    return exitcode
  end
end





describe("Tests the busted command-line options", function()

  setup(function()
    require("pl")
  end)

  after_each(function()
    if error_started then
      print("================================================")
      print("==  Error block ended, something was wrong    ==")
      print("================================================")
      error_started = false
    end
  end)
  

  it("tests running with --tags specified", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=_tags.lua$"..ditch)
    assert.is_false(success)
    assert.is_equal(3, (modexit(exitcode)))
    success, exitcode = utils.execute("busted --pattern=_tags.lua$ --tags=tag1"..ditch)
    assert.is_false(success)
    assert.is_equal(2, (modexit(exitcode)))
    success, exitcode = utils.execute("busted --pattern=_tags.lua$ --tags=tag1,tag2"..ditch)
    assert.is_false(success)
    assert.is_equal(3, (modexit(exitcode)))
    error_end()
  end)

  it("tests running with --lang specified", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_success.lua$ --lang=en"..ditch)
    assert.is_true(success)
    assert.is_equal(0, (modexit(exitcode)))  
    success, exitcode = utils.execute("busted --pattern=cl_success --lang=not_found_here"..ditch)
    assert.is_false(success)
    assert.is_equal(1, (modexit(exitcode)))  -- busted errors out on non-available language
    error_end()
  end)

  it("tests running with --version specified", function()
    local success, exitcode
    success, exitcode = utils.execute("busted --version"..ditch)
    assert.is_true(success)
    assert.is_equal(0, (modexit(exitcode)))
  end)

  it("tests running with --help specified", function()
    local success, exitcode
    success, exitcode = utils.execute("busted --help"..ditch)
    assert.is_true(success)
    assert.is_equal(0, (modexit(exitcode)))
  end)

  it("tests running a non-compiling testfile", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_compile_fail.lua$"..ditch)
    assert.is_false(success)
    assert.is_equal(1, (modexit(exitcode)))
    error_end()
  end)

  it("tests running a testfile throwing errors when being run", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_execute_fail.lua$"..ditch)
    assert.is_false(success)
    assert.is_equal(1, (modexit(exitcode)))
    error_end()
  end)

  it("tests running with --output specified", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_success.lua$ --output=TAP"..ditch)
    assert.is_true(success)
    assert.is_equal(0, (modexit(exitcode)))  
    success, exitcode = utils.execute("busted --pattern=cl_two_failures.lua$ --output=not_found_here"..ditch)
    assert.is_false(success)
    assert.is_equal(3, (modexit(exitcode)))  -- outputter missing, defaults to default outputter +1 error
    error_end()
  end)

end)
