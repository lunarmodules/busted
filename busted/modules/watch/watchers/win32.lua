-- Windows ReadDirectoryChangesW watcher
-- Uses the winapi binding for native file watching on Windows

local winapi = require 'winapi'  -- luarocks: luawinapi
local path = require 'pl.path'

local Win32Watcher = {}
Win32Watcher.__index = Win32Watcher

-- Change notification flags
local FILE_NOTIFY_CHANGE_FILE_NAME = 0x00000001
local FILE_NOTIFY_CHANGE_DIR_NAME = 0x00000002
local FILE_NOTIFY_CHANGE_LAST_WRITE = 0x00000010

-- Action types
local FILE_ACTION_ADDED = 1
local FILE_ACTION_REMOVED = 2
local FILE_ACTION_MODIFIED = 3
local FILE_ACTION_RENAMED_OLD_NAME = 4
local FILE_ACTION_RENAMED_NEW_NAME = 5

function Win32Watcher.new(options)
  local self = setmetatable({}, Win32Watcher)
  self.follow_symlinks = options.follow_symlinks or false
  self.extensions = options.extensions or { '.lua' }
  self.include_patterns = options.include_patterns or {}
  self.exclude_patterns = options.exclude_patterns or {}
  self.recursive = options.recursive ~= false
  self.directories = {}
  self.handles = {}
  self.callback = nil
  self.running = false
  return self
end

-- Check if a file matches the extension filter
function Win32Watcher:matches_extension(filepath)
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
      :gsub('%*', '[^/\\]*')
      :gsub('.__DOUBLE_STAR__.', '.*')
      :gsub('%?', '.')

    if filepath:match(lua_pattern) then
      return true
    end
  end

  return false
end

-- Check if a file should be watched
function Win32Watcher:should_watch(filepath)
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

-- Create a directory watch handle
function Win32Watcher:create_watch(dir)
  local flags = FILE_NOTIFY_CHANGE_FILE_NAME + FILE_NOTIFY_CHANGE_DIR_NAME + FILE_NOTIFY_CHANGE_LAST_WRITE

  local handle = winapi.CreateFile(
    dir,
    winapi.FILE_LIST_DIRECTORY,
    winapi.FILE_SHARE_READ + winapi.FILE_SHARE_WRITE + winapi.FILE_SHARE_DELETE,
    nil,
    winapi.OPEN_EXISTING,
    winapi.FILE_FLAG_BACKUP_SEMANTICS + winapi.FILE_FLAG_OVERLAPPED,
    nil
  )

  if handle and handle ~= winapi.INVALID_HANDLE_VALUE then
    return { handle = handle, dir = dir, flags = flags }
  end

  return nil
end

-- Watch a directory
function Win32Watcher:watch(dir)
  local watch = self:create_watch(path.abspath(dir))
  if watch then
    table.insert(self.directories, dir)
    table.insert(self.handles, watch)
  end
end

-- Watch multiple directories
function Win32Watcher:watch_all(dirs)
  for _, dir in ipairs(dirs) do
    self:watch(dir)
  end
end

-- Set the callback for file changes
function Win32Watcher:on_change(callback)
  self.callback = callback
end

-- Convert action to event type
local function event_type(action)
  if action == FILE_ACTION_ADDED or action == FILE_ACTION_RENAMED_NEW_NAME then
    return 'created'
  elseif action == FILE_ACTION_REMOVED or action == FILE_ACTION_RENAMED_OLD_NAME then
    return 'deleted'
  else
    return 'modified'
  end
end

-- Start watching (blocking loop)
function Win32Watcher:start()
  if #self.handles == 0 then
    return
  end

  self.running = true

  while self.running do
    for _, watch in ipairs(self.handles) do
      -- Read directory changes
      local changes = winapi.ReadDirectoryChangesW(
        watch.handle,
        self.recursive,
        watch.flags
      )

      if changes and #changes > 0 then
        local changed = {}

        for _, change in ipairs(changes) do
          local filepath = path.join(watch.dir, change.filename)

          if self:should_watch(filepath) then
            table.insert(changed, {
              path = filepath,
              event = event_type(change.action)
            })
          end
        end

        if #changed > 0 and self.callback then
          self.callback(changed)
        end
      end
    end

    -- Small sleep to prevent busy loop
    local ok, socket = pcall(require, 'socket')
    if ok and socket.sleep then
      socket.sleep(0.05)
    else
      local start = os.clock()
      while os.clock() - start < 0.05 do end
    end
  end
end

-- Stop watching
function Win32Watcher:stop()
  self.running = false
  for _, watch in ipairs(self.handles) do
    winapi.CloseHandle(watch.handle)
  end
  self.handles = {}
end

-- Get watcher type
function Win32Watcher:type()
  return 'win32'
end

return Win32Watcher
