expose('Tests expose from file root', function()
  pl = require 'pl'
  _G.global_var = 'this global is in _G'

  it('loads global environment with "List"', function()
    assert.is_not_nil(pl)
    assert.is_not_nil(List)
  end)
end)
