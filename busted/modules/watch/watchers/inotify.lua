-- Linux inotify watcher
-- Uses the inotify binding for native file watching on Linux

local inotify = require 'inotify'  -- luarocks: luainotify
local path = require 'pl.path'

local InotifyWatcher = {}
InotifyWatcher.__index = InotifyWatcher

-- inotify event flags
local IN_MODIFY = inotify.IN_MODIFY
local IN_CREATE = inotify.IN_CREATE
local IN_DELETE = inotify.IN_DELETE
local IN_MOVED_TO = inotify.IN_MOVED_TO
local IN_MOVED_FROM = inotify.IN_MOVED_FROM
local IN_CLOSE_WRITE = inotify.IN_CLOSE_WRITE

function InotifyWatcher.new(options)
  local self = setmetatable({}, InotifyWatcher)
  self.follow_symlinks = options.follow_symlinks or false
  self.extensions = options.extensions or { '.lua' }
  self.include_patterns = options.include_patterns or {}
  self.exclude_patterns = options.exclude_patterns or {}
  self.recursive = options.recursive ~= false
  self.handle = inotify.init()
  self.watches = {}  -- wd -> directory path
  self.callback = nil
  self.running = false
  return self
end

-- Check if a file matches the extension filter
function InotifyWatcher:matches_extension(filepath)
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
function InotifyWatcher:should_watch(filepath)
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

-- Add a watch on a directory
function InotifyWatcher:add_watch(dir)
  local flags = IN_MODIFY + IN_CREATE + IN_DELETE + IN_MOVED_TO + IN_MOVED_FROM + IN_CLOSE_WRITE
  local wd = self.handle:addwatch(dir, flags)
  if wd then
    self.watches[wd] = dir
  end
  return wd
end

-- Recursively add watches for all subdirectories
local function scan_directories(dir, callback)
  local ok, lfs = pcall(require, 'lfs')
  if not ok then
    return
  end

  callback(dir)

  for entry in lfs.dir(dir) do
    if entry ~= '.' and entry ~= '..' then
      local full_path = path.join(dir, entry)
      local attr = lfs.attributes(full_path)
      if attr and attr.mode == 'directory' then
        scan_directories(full_path, callback)
      end
    end
  end
end

-- Watch a directory
function InotifyWatcher:watch(dir)
  if self.recursive then
    scan_directories(dir, function(d)
      self:add_watch(d)
    end)
  else
    self:add_watch(dir)
  end
end

-- Watch multiple directories
function InotifyWatcher:watch_all(dirs)
  for _, dir in ipairs(dirs) do
    self:watch(dir)
  end
end

-- Set the callback for file changes
function InotifyWatcher:on_change(callback)
  self.callback = callback
end

-- Convert inotify event to our event format
local function event_type(mask)
  if mask:match('CREATE') or mask:match('MOVED_TO') then
    return 'created'
  elseif mask:match('DELETE') or mask:match('MOVED_FROM') then
    return 'deleted'
  else
    return 'modified'
  end
end

-- Start watching (blocking loop)
function InotifyWatcher:start()
  self.running = true

  while self.running do
    local events = self.handle:read()
    if events then
      local changed = {}

      for _, event in ipairs(events) do
        local dir = self.watches[event.wd]
        if dir and event.name then
          local filepath = path.join(dir, event.name)

          -- Handle new directory creation
          if event.mask:match('ISDIR') and event.mask:match('CREATE') then
            if self.recursive then
              self:add_watch(filepath)
            end
          end

          if self:should_watch(filepath) then
            table.insert(changed, {
              path = filepath,
              event = event_type(event.mask)
            })
          end
        end
      end

      if #changed > 0 and self.callback then
        self.callback(changed)
      end
    end
  end
end

-- Stop watching
function InotifyWatcher:stop()
  self.running = false
  -- Close all watches
  for wd, _ in pairs(self.watches) do
    self.handle:rmwatch(wd)
  end
  self.handle:close()
end

-- Get watcher type
function InotifyWatcher:type()
  return 'inotify'
end

return InotifyWatcher
