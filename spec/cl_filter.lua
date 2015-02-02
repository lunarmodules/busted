-- supporting testfile; belongs to 'cl_spec.lua'

describe('Tests the busted command-line options', function()

  it('is a test with pattern1', function()
    -- works by counting failure
    error('error 1 on pattern1')
  end)

  it('is another test with pattern1', function()
    -- works by counting failure
    error('error 2 on pattern1')
  end)

  it('is a test with pattern2', function()
    -- works by counting failure
    error('error on pattern2')
  end)

  it('is a test with pattern3', function()
    -- nothing here, makes it succeed
  end)

  it('is a test with two pattern3 and pattern4', function ()
    -- Always succeed
  end)
end)

describe('Tests describe with patt1', function()
  before_each(function()
    error('error in before_each on patt1')
  end)

  after_each(function()
    error('error in after_each on patt1')
  end)

  it('is a test inside describe', function()
  end)

  it('is another test inside describe', function()
  end)
end)

context('Tests context with patt2', function()
  setup(function()
    error('error in setup on patt2')
  end)
end)
