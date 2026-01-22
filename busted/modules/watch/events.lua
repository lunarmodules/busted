-- Events module for watch mode
-- File change polling with debouncing

local system = require 'system'
local Debouncer = require 'busted.modules.watch.debouncer'

local Events = {}
Events.__index = Events

-- Create a new events poller
-- @param watcher: Watcher module instance
function Events.new(watcher)
  local self = setmetatable({}, Events)
  self.watcher = watcher
  self.debouncer = nil  -- Created lazily when debounce option is used
  self.debounce_delay = nil  -- Current debounce delay (nil = no debouncing)
  return self
end

-- Poll for events with optional timeout and debouncing
-- @param opts.timeout: poll timeout in seconds (default 0.1)
-- @param opts.debounce: debounce delay in ms (nil = no debouncing)
-- @return array of events, each: {type='file'|'error'|'timeout', ...}
function Events:poll(opts)
  opts = opts or {}
  local timeout = opts.timeout or 0.1
  local debounce = opts.debounce
  local events = {}

  -- Configure debouncer if debounce option changed
  if debounce ~= self.debounce_delay then
    self.debounce_delay = debounce
    if debounce and debounce > 0 then
      self.debouncer = Debouncer.new(debounce)
    else
      self.debouncer = nil
    end
  end

  -- Sleep for the poll timeout
  system.sleep(timeout)

  -- Poll for file changes
  local file_events = self:poll_files()
  for _, evt in ipairs(file_events) do
    table.insert(events, evt)
  end

  -- If no events, return timeout event
  if #events == 0 then
    table.insert(events, { type = 'timeout' })
  end

  return events
end

-- Poll for file changes and handle debouncing
-- @return array of file events
function Events:poll_files()
  local events = {}

  if not self.watcher then
    return events
  end

  -- Poll the watcher for changes
  local ok, changes = pcall(function()
    return self.watcher:poll()
  end)

  if not ok then
    -- Watcher error
    table.insert(events, {
      type = 'error',
      source = 'watcher',
      msg = tostring(changes)
    })
    return events
  end

  -- If no debouncer, emit changes immediately
  if not self.debouncer then
    if changes then
      for _, change in ipairs(changes) do
        table.insert(events, {
          type = 'file',
          path = change.path
        })
      end
    end
    return events
  end

  -- Add changes to debouncer
  if changes and #changes > 0 then
    for _, change in ipairs(changes) do
      self.debouncer:add(change.path)
    end
  end

  -- Check if debouncer is ready to emit
  if self.debouncer:ready() then
    local changed_files = self.debouncer:flush()
    for _, filepath in ipairs(changed_files) do
      table.insert(events, {
        type = 'file',
        path = filepath
      })
    end
  end

  return events
end

-- Check if there are pending file changes (not yet debounced)
function Events:has_pending_changes()
  if not self.debouncer then
    return false
  end
  return self.debouncer:has_pending()
end

-- Get time until debouncer is ready
function Events:time_until_ready()
  return self.debouncer and self.debouncer:time_remaining()
end

return Events
