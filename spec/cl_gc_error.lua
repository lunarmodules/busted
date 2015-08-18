-- supporting testfile; belongs to 'cl_spec.lua'

describe('Runs test with garbage collection failure', function()
  it('throws error in __gc metamethod', function()
    setmetatable({}, { __gc = function() error('gc error') end})
    collectgarbage()
    collectgarbage()
  end)
end)
