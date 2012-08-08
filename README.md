busted
======

Unit testing in Lua.

## Usage

```lua
require("busted")

describe("Busted unit testing framework, function()
  describe("should be awesome", function()
    it("should be easy to use", function()
      assert.truthy("Yup.")
    end)

    it("should have lots of features, function()
      assert_equal({ table = "great"}, { table = "great" })
      assert.not_same({ table = "great"}, { table = "great"})
    end)

    it("should be easy to read", function()
      object_mock = mock(myObject)
      spy_on(object_mock.alert)

      object_mock.alert("Lua")

      assert.called_with("object_mock", "Lua")
    end)
  end)
end)
```
