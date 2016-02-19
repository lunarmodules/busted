describe('Config Loader', function()
  local configLoader = require 'busted.modules.configuration_loader'()
  local testConfig, cliArgs, defaults

  before_each(function()
    testConfig = {
      _all = {
        other = 'stuff',
      },
      default = {
        output = 'utfTerminal'
      },
      windows = {
        output = 'plainTerminal'
      }
    }

    cliArgs = { }
    defaults = { }
  end)

  it('returns a valid config with no config file', function()
    local testConfig = { }
    local config, err = configLoader(testConfig, cliArgs)

    assert.are.same({}, config)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with default config', function()
    local config, err = configLoader(testConfig, cliArgs)

    assert.are.same(testConfig.default.output, config.output)
    assert.are.same(testConfig._all.other, config.other)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with specified config', function()
    cliArgs.run = 'windows'
    local config, err = configLoader(testConfig, cliArgs)

    assert.are.same(testConfig.windows.output, config.output)
    assert.are.same(testConfig._all.other, config.other)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with specified config and defaults specified', function()
    defaults = { output = 'TAP' }
    cliArgs.run = 'windows'
    local config, err = configLoader(testConfig, cliArgs, defaults)

    assert.are.same(testConfig.windows.output, config.output)
    assert.are.same(testConfig._all.other, config.other)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with cliArgs and defaults specified', function()
    cliArgs = { output = 'TAP' }
    local config, err = configLoader(testConfig, cliArgs, defaults)

    assert.are.same(cliArgs.output, config.output)
    assert.are.same(testConfig._all.other, config.other)
    assert.are.equal(nil, err)
  end)

  it('returns a valid config with defaults if no configs present', function()
    defaults = { output = 'TAP' }
    local config, err = configLoader({}, {}, defaults)

    assert.are.same(defaults, config)
    assert.are.equal(nil, err)
  end)

  it('returns an error with an invalid config', function()
    local config, err = configLoader('invalid', cliArgs)
    assert.is_nil(config)
    assert.are.equal('.busted file does not return a table.', err)
  end)

  it('returns an error with an invalid run', function()
    cliArgs.run = 'invalid'
    local config, err = configLoader(testConfig, cliArgs)
    assert.is_nil(config)
    assert.are.equal('Task `invalid` not found, or not a table.', err)
  end)
end)
