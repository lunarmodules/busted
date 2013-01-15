Busted
======

[![travis-ci status](https://secure.travis-ci.org/Olivine-Labs/busted.png)](http://travis-ci.org/#!/Olivine-Labs/busted/builds)

busted is a unit testing framework with a focus on being **easy to
use**.

Check out the [official docs](http://www.olivinelabs.com/busted) for
extended info.

busted test specs read naturally without being too verbose. You can even
chain asserts and negations, such as `assert.not.equals`. Nest blocks of
tests with contextual descriptions using `describe`, and add tags to
blocks so you can run arbitrary groups of tests.

An extensible assert library allows you to extend and craft your own
assert functions specific to your case with method chaining. A modular
output library lets you add on your own output format, along with the
default pretty and plain terminal output, JSON with and without
streaming, and TAP-compatible output that allows you to run busted specs
within most CI servers.

```lua
describe("Busted unit testing framework", function()
  describe("should be awesome", function()
    it("should be easy to use", function()
      assert.truthy("Yup.")
    end)

    it("should have lots of features", function()
      -- deep check comparisons!
      assert.same({ table = "great"}, { table = "great" })

      -- or check by reference!
      assert.is_not.equals({ table = "great"}, { table = "great"})

      assert.falsy(nil)
      assert.error(function() error("Wat") end)
    end)

    it("should provide some shortcuts to common functions", function()
      assert.unique({{ thing = 1 }, { thing = 2 }, { thing = 3 }})
    end)

    it("should have mocks and spies for functional tests", function()
      local thing = require("thing_module")
      spy.spy_on(thing, "greet")
      thing.greet("Hi!")

      assert.spy(thing.greet).was.called()
      assert.spy(thing.greet).was.called_with("Hi!")
    end)
  end)
end)
```
