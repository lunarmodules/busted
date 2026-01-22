-- macOS FSEvents watcher
-- Uses the fsevents binding for native file watching on macOS

local fsevents = require 'fsevents'  -- luarocks: luafsevents
local path = require 'pl.path'

local FSEventsWatcher = {}
FSEventsWatcher.__index = FSEventsWatcher

function FSEventsWatcher.new(options)
  local self = setmetatable({}, FSEventsWatcher)
  self.follow_symlinks = options.follow_symlinks or false
  self.extensions = options.extensions or { '.lua' }
  self.include_patterns = options.include_patterns or {}
  self.exclude_patterns = options.exclude_patterns or {}
  self.recursive = options.recursive ~= false
  self.directories = {}
  self.stream = nil
  self.callback = nil
  self.running = false
  return self
end

-- Check if a file matches the extension filter
function FSEventsWatcher:matches_extension(filepath)
  for _, ext in ipairs(self.extensions) do
    if filepath:sub(-#ext) == ext then
      return true
    end
  end
  return false
end

-- Check if a path matches any of the patterns
local function matches_patterns(filepath, patterns)
  if not patterns or #patterns == 0 then
    return false
  end

  for _, pattern in ipairs(patterns) do
    local lua_pattern = pattern
      :gsub('%.', '%%.')
      :gsub('%*%*', '.__DOUBLE_STAR__.')
      :gsub('%*', '[^/]*')
      :gsub('.__DOUBLE_STAR__.', '.*')
      :gsub('%?', '.')

    if filepath:match(lua_pattern) then
      return true
    end
  end

  return false
end

-- Check if a file should be watched
function FSEventsWatcher:should_watch(filepath)
  if not self:matches_extension(filepath) then
    return false
  end

  if matches_patterns(filepath, self.exclude_patterns) then
    return false
  end

  if #self.include_patterns > 0 then
    return matches_patterns(filepath, self.include_patterns)
  end

  return true
end

-- Watch a directory
function FSEventsWatcher:watch(dir)
  table.insert(self.directories, path.abspath(dir))
end

-- Watch multiple directories
function FSEventsWatcher:watch_all(dirs)
  for _, dir in ipairs(dirs) do
    self:watch(dir)
  end
end

-- Set the callback for file changes
function FSEventsWatcher:on_change(callback)
  self.callback = callback
end

-- Determine event type from FSEvents flags
local function event_type(flags)
  if flags.itemCreated then
    return 'created'
  elseif flags.itemRemoved then
    return 'deleted'
  elseif flags.itemRenamed then
    return 'renamed'
  else
    return 'modified'
  end
end

-- FSEvents callback handler
local function create_event_handler(watcher)
  return function(events)
    local changed = {}

    for _, event in ipairs(events) do
      local filepath = event.path

      -- Skip directories unless they were created/deleted
      if not event.flags.itemIsDir or event.flags.itemCreated or event.flags.itemRemoved then
        if watcher:should_watch(filepath) then
          table.insert(changed, {
            path = filepath,
            event = event_type(event.flags)
          })
        end
      end
    end

    if #changed > 0 and watcher.callback then
      watcher.callback(changed)
    end
  end
end

-- Start watching (blocking loop)
function FSEventsWatcher:start()
  if #self.directories == 0 then
    return
  end

  self.running = true

  -- Create FSEvents stream
  self.stream = fsevents.create(self.directories, {
    latency = 0.3,  -- 300ms debounce built into FSEvents
    noDefer = true,
    fileEvents = true,  -- Get file-level events (requires macOS 10.7+)
  }, create_event_handler(self))

  -- Start the event loop
  self.stream:start()

  -- Run the event loop
  while self.running do
    -- FSEvents runs on its own thread, we just need to wait
    local ok, socket = pcall(require, 'socket')
    if ok and socket.sleep then
      socket.sleep(0.1)
    else
      local start = os.clock()
      while os.clock() - start < 0.1 do end
    end
  end
end

-- Stop watching
function FSEventsWatcher:stop()
  self.running = false
  if self.stream then
    self.stream:stop()
    self.stream = nil
  end
end

-- Get watcher type
function FSEventsWatcher:type()
  return 'fsevents'
end

return FSEventsWatcher
