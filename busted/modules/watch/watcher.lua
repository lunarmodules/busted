-- Watcher abstraction for watch mode
-- Provides a tiered fallback chain: native → lfs → git

local path = require 'pl.path'

local Watcher = {}

-- Detect the current platform
local function detect_platform()
  if path.is_windows then
    return 'win32'
  end

  -- Check for macOS
  local handle = io.popen('uname -s 2>/dev/null', 'r')
  if handle then
    local result = handle:read('*a')
    handle:close()
    if result and result:match('Darwin') then
      return 'fsevents'
    end
  end

  -- Default to Linux/inotify
  return 'inotify'
end

-- Try to load a watcher module
local function try_load_watcher(name, options)
  local ok, watcher_module = pcall(require, 'busted.modules.watch.watchers.' .. name)
  if not ok then
    return nil, 'module not found: ' .. tostring(watcher_module)
  end

  -- Try to create the watcher (this may fail if native deps are missing)
  local success, watcher = pcall(function()
    return watcher_module.new(options)
  end)

  if not success then
    return nil, 'failed to initialize: ' .. tostring(watcher)
  end

  return watcher, nil
end

-- Create a watcher with automatic fallback
function Watcher.create(options)
  options = options or {}
  local warnings = {}

  -- Try native watcher first
  local platform = detect_platform()
  local watcher, err = try_load_watcher(platform, options)

  if watcher then
    return watcher, warnings
  end

  table.insert(warnings, platform .. ' watcher unavailable: ' .. (err or 'unknown error'))

  -- Try lfs polling as first fallback
  watcher, err = try_load_watcher('lfs', options)
  if watcher then
    table.insert(warnings, 'using lfs polling fallback')
    return watcher, warnings
  end

  table.insert(warnings, 'lfs watcher unavailable: ' .. (err or 'unknown error'))

  -- Try git polling as last fallback
  watcher, err = try_load_watcher('git', options)
  if watcher then
    table.insert(warnings, 'using git polling fallback')
    return watcher, warnings
  end

  -- No watcher available
  return nil, { 'no file watcher available - git fallback failed: ' .. (err or 'unknown error') }
end

-- Get list of available watchers (for diagnostics)
function Watcher.available()
  local available = {}

  local watchers = { 'inotify', 'fsevents', 'win32', 'lfs', 'git' }
  for _, name in ipairs(watchers) do
    local ok = pcall(require, 'busted.modules.watch.watchers.' .. name)
    if ok then
      table.insert(available, name)
    end
  end

  return available
end

-- Get the recommended watcher for this platform
function Watcher.recommended()
  return detect_platform()
end

return Watcher
