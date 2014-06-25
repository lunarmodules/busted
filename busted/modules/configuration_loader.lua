return function()
  local path = require 'pl.path'
  local tablex = require 'pl.tablex'

  -- Function to load the .busted configuration file if available
  local loadBustedConfigurationFile = function(configFile, config, run)
    if run and run ~= '' then
      if type(configFile) ~= 'table' then
        return config, '.busted file does not return a table.'
      end

      local runConfig = configFile[run]

      if type(runConfig) == 'table' then
        config = tablex.merge(config, runConfig, true)
        return config
      else
        return config, 'Task `' .. run .. '` not found, or not a table.'
      end
    end

    if configFile and type(configFile.default) == 'table' then
      return tablex.merge(config, configFile.default, true)
    end

    return config
  end

  return loadBustedConfigurationFile
end

