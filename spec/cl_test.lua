-- Tests the commandline options by executing busted through
-- os.execute(). It can be run through the following command:
--
--    busted --pattern=cl_test.lua --defer-print


local error_started
local error_start = function()
  print("================================================")
  print("==  Error block follows                       ==")
  print("================================================")
  error_started = true
end
local error_end = function()
  print("================================================")
  print("==  Error block ended, all according to plan  ==")
  print("================================================")
  error_started = false
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
    success, exitcode = utils.execute("busted --pattern=_tags.lua$")
    assert.is_false(success)
    assert.is_equal(exitcode, 3)
    success, exitcode = utils.execute("busted --pattern=_tags.lua$ --tags=tag1")
    assert.is_false(success)
    assert.is_equal(exitcode, 2)
    success, exitcode = utils.execute("busted --pattern=_tags.lua$ --tags=tag1,tag2")
    assert.is_false(success)
    assert.is_equal(exitcode, 3)
    error_end()
  end)

  it("tests running with --lang specified", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_success.lua$ --lang=en")
    assert.is_true(success)
    assert.is_equal(exitcode, 0)  
    success, exitcode = utils.execute("busted --pattern=cl_success --lang=not_found_here")
    assert.is_false(success)
    assert.is_equal(exitcode, 1)  -- busted errors out on non-available language
    error_end()
  end)

  it("tests running with --version specified", function()
    local success, exitcode
    success, exitcode = utils.execute("busted --version")
    assert.is_true(success)
    assert.is_equal(exitcode, 0)
  end)

  it("tests running with --help specified", function()
    local success, exitcode
    success, exitcode = utils.execute("busted --help")
    assert.is_true(success)
    assert.is_equal(exitcode, 0)
  end)

  it("tests running a non-compiling testfile", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_compile_fail.lua$")
    assert.is_false(success)
    assert.is_equal(exitcode, 1)
    error_end()
  end)

  it("tests running a testfile throwing errors when being run", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_execute_fail.lua$")
    assert.is_false(success)
    assert.is_equal(exitcode, 1)
    error_end()
  end)

  it("tests running with --output specified", function()
    local success, exitcode
    error_start()
    success, exitcode = utils.execute("busted --pattern=cl_success.lua$ --output=TAP")
    assert.is_true(success)
    assert.is_equal(exitcode, 0)  
    success, exitcode = utils.execute("busted --pattern=cl_two_failures.lua$ --output=not_found_here")
    assert.is_false(success)
    assert.is_equal(exitcode, 1)  -- 1 for outputter missing
    error_end()
  end)

end)
