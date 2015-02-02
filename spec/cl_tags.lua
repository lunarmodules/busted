-- supporting testfile; belongs to 'cl_spec.lua'

describe('Tests the busted command-line options', function()

  it('is a test with a tag #tag1', function()
    -- works by counting failure
    error('error 1 on tag1')
  end)

  spec('is a test with a tag #tag1', function()
    -- works by counting failure
    error('error 2 on tag1')
  end)

  test('is a test with a tag #tag2', function()
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

describe('Tests describe with a tag #dtag1', function()
  before_each(function()
    error('error in before_each on dtag1')
  end)

  after_each(function()
    error('error in after_each on dtag1')
  end)

  it('is a test inside describe', function()
  end)

  it('is another test inside describe', function()
  end)
end)

context('Tests context with a tag #dtag2', function()
  setup(function()
    error('error in setup on dtag2')
  end)
end)
