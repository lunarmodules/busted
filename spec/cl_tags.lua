-- supporting testfile; belongs to 'cl_spec.lua'

describe("Tests the busted command-line options", function()

  it("is a test with a tag #tag1", function()
    -- works by counting failure
    error("error 1 on tag1")
  end)
  
  it("is a test with a tag #tag1", function()
    -- works by counting failure
    error("error 2 on tag1")
  end)
  
  it("is a test with a tag #tag2", function()
    -- works by counting failure
    error("error on tag2")
  end)
  
  it("is a test with a tag #tag3", function()
    -- nothing here, makes it succeed
  end)
  
end)
