local egg = ''

setup(function()
  egg = egg..'S'
end)

teardown(function()
  egg = egg..'T'
  assert.equal('Sb1ab2aT', egg)
end)

before_each(function()
  egg = egg..'b'
end)

after_each(function()
  egg = egg..'a'
end)

it('file context before_each after_each egg test 1', function()
  assert.equal('Sb', egg)
  egg = egg..'1'
end)

it('file context before_each after_each egg test 2', function()
  assert.equal('Sb1ab', egg)
  egg = egg..'2'
end)
