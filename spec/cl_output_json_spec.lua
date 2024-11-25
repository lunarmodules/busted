local utils = require 'pl.utils'
local path = require 'pl.path'
local busted_cmd = path.is_windows and 'lua bin/busted' or 'eval $(luarocks path) && bin/busted'

-- if exitcode >256, then take MSB as exit code
local modexit = function(exitcode)
  if exitcode > 255 then
    return math.floor(exitcode / 256), exitcode - math.floor(exitcode / 256) * 256
  else
    return exitcode
  end
end

local execute = function(cmd)
  local success, exitcode, out, err = utils.executeex(cmd)
  return not not success, modexit(exitcode), out, err
end

describe('Tests the busted json output', function()
  it('encodes pending tests', function()
    local success, exit_code, out, err = execute(busted_cmd .. ' ' .. '--pattern=cl_pending.lua$ --output=busted/outputHandlers/json.lua')

    assert.is_true(success)
    assert.is.equal(exit_code, 0)
    assert.is.equal(err, '')
  end)

  it('notifies with error if results cannot be encoded', function()
    local success, exit_code, out, err = execute(busted_cmd .. ' --helper=spec/cl_output_json_helper.lua spec/cl_output_json.lua --output=busted/outputHandlers/json.lua')

    assert.is_false(success)
    assert.is_not.equal(exit_code, 0)
    assert.is_truthy(err:find("type 'function' is not supported by JSON"))
  end)
end)
