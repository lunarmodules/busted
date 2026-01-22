-- Debouncer module for watch mode
-- Collects file change events and emits them after a delay

local system = require 'system'

local Debouncer = {}
Debouncer.__index = Debouncer

function Debouncer.new(delay_ms)
  local self = setmetatable({}, Debouncer)
  self.delay_ms = delay_ms or 300
  self.delay_sec = self.delay_ms / 1000
  self.pending_files = {}
  self.last_event_time = nil
  return self
end

-- Add a file change event to the pending set
function Debouncer:add(filepath)
  self.pending_files[filepath] = true
  self.last_event_time = system.gettime()
end

-- Check if we have pending files and debounce period has elapsed
function Debouncer:ready()
  if not self.last_event_time then
    return false
  end
  local elapsed = system.gettime() - self.last_event_time
  return elapsed >= self.delay_sec
end

-- Get the list of changed files and reset
function Debouncer:flush()
  local files = {}
  for filepath, _ in pairs(self.pending_files) do
    table.insert(files, filepath)
  end
  self.pending_files = {}
  self.last_event_time = nil
  return files
end

-- Check if there are any pending changes
function Debouncer:has_pending()
  return next(self.pending_files) ~= nil
end

-- Get time remaining until ready (in seconds)
function Debouncer:time_remaining()
  if not self.last_event_time then
    return nil
  end
  local elapsed = system.gettime() - self.last_event_time
  local remaining = self.delay_sec - elapsed
  return remaining > 0 and remaining or 0
end

-- Reset the debouncer
function Debouncer:reset()
  self.pending_files = {}
  self.last_event_time = nil
end

return Debouncer
