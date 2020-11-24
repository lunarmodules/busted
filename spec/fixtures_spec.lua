local pl_path = require "pl.path"

describe("fixtures:", function()

  describe("fixture_path()", function()

    it("returns the absolute fixture path", function()
      local path = fixture_path("fixtures/myfile.txt")
      assert.match("^.-busted[/\\]spec[/\\]fixtures[/\\]myfile.txt$", path)
    end)

    it("returns the absolute fixture path normalized", function()
      local path = fixture_path("../fixtures/myfile.txt")
      assert.match("^.-busted[/\\]fixtures[/\\]myfile.txt$", path)
    end)

  end)

end)

