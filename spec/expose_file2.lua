describe('Tests environment exposed from previous file', function()
  it('global environment still has "List"', function()
    assert.is_nil(_G.pl)
    assert.is_not_nil(pl)  --luacheck: ignore
    assert.is_equal('this global is in _G', _G.global_var)
    assert.is_not_nil(List)  --luacheck: ignore
  end)

  it('global environment still has "pl" packages loaded', function()
    assert.is_not_nil(package.loaded['pl'])
    assert.is_not_nil(package.loaded['pl.List'])
  end)
end)
