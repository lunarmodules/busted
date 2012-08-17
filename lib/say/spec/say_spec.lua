describe("Tests to make sure the say library is functional", function()
  local s = require('say.s')
  s:set_namespace('en')

  it("tests the set function metamethod", function()
    s:set('herp', 'derp')
    assert(s.registry.en.herp == 'derp')
  end)

  it("tests the __call metamethod", function()
    s:set('herp', 'derp')
    assert(s('herp') == 'derp')

    s:set('herp', '%s')
    assert(s('herp', {'test'}) == 'test')

    s:set('herp', '%s%s')
    assert(s('herp', {'test', 'test'}) == 'testtest')
  end)
end)
