-- supporting testfile; belongs to 'cl_spec.lua'

require 'busted.runner'()

describe('Tests busted standalone with command-line options', function()

  it('is a test with a tag #tag1', function()
    -- works by counting failure
    error('error 1 on tag1')
  end)

  it('is a test with a tag #tag1', function()
    -- works by counting failure
    error('error 2 on tag1')
  end)

  it('is a test with a tag #tag2', function()
    -- works by counting failure
    error('error on tag2')
  end)

  it('is a test with a tag #tag3', function()
    -- nothing here, makes it succeed
  end)

  it('is a test with two tags #tag3 #tag4', function ()
    -- Always succeed
  end)
end)
