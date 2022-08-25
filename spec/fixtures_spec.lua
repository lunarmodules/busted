local fixtures = require 'busted.fixtures'

describe("fixtures:", function()

  describe("path()", function()

    it("returns the absolute fixture path", function()
      local path = fixtures.path("fixtures/myfile.txt")
      assert.match("^.-busted[/\\]spec[/\\]fixtures[/\\]myfile.txt$", path)
    end)

    it("returns the absolute fixture path normalized", function()
      local path = fixtures.path("../fixtures/myfile.txt")
      assert.match("^.-busted[/\\]fixtures[/\\]myfile.txt$", path)
    end)

    it("errors on bad input", function()
      assert.has.error(function()
        fixtures.path(123) -- pass in a number
      end, "bad argument to 'path' expected a string (relative filename) or nil, got: number")
    end)

  end)



  describe("read()", function()

    it("returns the contents of a file", function()
      local contents, err = fixtures.read("../spec/.hidden/dont_execute_spec.lua")
      assert.is_nil(err)
      assert.equal("assert(false,'should not be executed')\n", contents)
    end)

    it("errors on bad input", function()
      assert.has.error(function()
        fixtures.read(123) -- pass in a number
      end, "bad argument to 'read' expected a string (relative filename), got: number")
    end)

    it("errors on read failure", function()
      assert.has.error(function()
        fixtures.read("./doesnt/really/exist")
      end)
    end)

  end)


  describe("load()", function()

    it("returns the executed contents of a lua file", function()
      local contents, err = fixtures.load("../spec/.hidden/some_file.lua")
      assert.is_nil(err)
      assert.equal("hello world", contents)
    end)

    it("returns the executed contents of a lua file, without specifying the extension", function()
      local contents, err = fixtures.load("../spec/.hidden/some_file")
      assert.is_nil(err)
      assert.equal("hello world", contents)
    end)

    it("errors on bad input", function()
      assert.has.error(function()
        fixtures.load(123) -- pass in a number
      end, "bad argument to 'load' expected a string (relative filename), got: number")
    end)

    it("errors on read failure", function()
      assert.has.error(function()
        fixtures.load("./doesnt/really/exist")
      end)
    end)

    it("errors on compile failure", function()
      assert.has.error(function()
        fixtures.load("./cl_compile_fail.lua")
      end)
    end)

  end)


end)

