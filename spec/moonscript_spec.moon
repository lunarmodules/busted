describe 'moonscript tests', ->

  -- failure
  it 'really fails', ->
    assert.are.equal true, false

  -- pending
  pending 'pending', ->

  -- success
  it 'succeeds', ->
    assert.are.equal true, true

  pending 'another', ->

  it 'is a moonscript bug?', ->
    assert.are.equal 'a', 'a'

