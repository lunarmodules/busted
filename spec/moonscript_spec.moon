describe "moonscript tests", ->
  it "runs", ->
    assert.are.equal true, true

  it "fails", ->
    assert.error(-> assert.are.equal false, true)

