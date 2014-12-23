-- supporting testfile; belongs to 'cl_spec.lua'

describe 'Test moonscript errors show file and line for', ->
  it 'failures #fail', ->
    assert.is_equal true, false
    return

  it 'table errors #table', ->
    error {}
    return

  it 'nil errors #nil', ->
    error!
    return

  it 'string errors #string', ->
    error 'error message'
    return

  return

return
