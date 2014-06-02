describe('Config Loader', function()
  local configLoader = require 'busted.modules.configuration_loader'()
  local testConfig, cliArgs

  before_each(function()
    testConfig = {
      default = {
        output = { 'utfTerminal' }
      },
      windows = {
        output = { 'plainTerminal' }
      }
    }

    cliArgs = { }
  end)

  it('returns a valid config with no config file', function()
    local testConfig = { }
    local config, err = configLoader(testConfig, cliArgs)

    assert.are.same({}, config)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with default config', function()
    local config, err = configLoader(testConfig, cliArgs)

    assert.are.same(testConfig.default, config)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with specified config', function()
    local config, err = configLoader(testConfig, cliArgs, 'windows')

    assert.are.same(testConfig.windows, config)
    assert.are.equal(nil, err)
  end)

  it('returns an error with an invalid config', function()
    local config, err = configLoader('invalid', cliArgs, 'run')
    assert.are_not.equal(nil, err)
  end)

  it('returns an error with an invalid run', function()
    local config, err = configLoader(testConfig, cliArgs, 'run')
    assert.are_not.equal(nil, err)
  end)
end)
