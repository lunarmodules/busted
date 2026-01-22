-- LuaFileSystem polling watcher
-- Uses mtime polling as a fallback when native watchers are unavailable

local lfs = require 'lfs'
local path = require 'pl.path'

local LfsWatcher = {}
LfsWatcher.__index = LfsWatcher

function LfsWatcher.new(options)
  local self = setmetatable({}, LfsWatcher)
  self.poll_interval = (options.poll_interval or 500) / 1000  -- Convert ms to seconds
  self.follow_symlinks = options.follow_symlinks or false
  self.watched_files = {}  -- filepath -> { mtime, ... }
  self.directories = {}
  self.extensions = options.extensions or { '.lua' }
  self.include_patterns = options.include_patterns or {}
  self.exclude_patterns = options.exclude_patterns or {}
  self.recursive = options.recursive ~= false
  self.callback = nil
  self.running = false
  return self
end

-- Check if a file matches the extension filter
function LfsWatcher:matches_extension(filepath)
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
    -- Simple glob-to-pattern conversion
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
function LfsWatcher:should_watch(filepath)
  -- Check extension
  if not self:matches_extension(filepath) then
    return false
  end

  -- Check exclude patterns
  if matches_patterns(filepath, self.exclude_patterns) then
    return false
  end

  -- Check include patterns (if specified, file must match)
  if #self.include_patterns > 0 then
    return matches_patterns(filepath, self.include_patterns)
  end

  return true
end

-- Get file modification time
local function get_mtime(filepath, follow_symlinks)
  local attr
  if follow_symlinks then
    attr = lfs.attributes(filepath)
  else
    attr = lfs.symlinkattributes(filepath)
  end
  return attr and attr.modification
end

-- Scan a directory and collect files to watch
function LfsWatcher:scan_directory(dir)
  local files = {}

  local function scan(current_dir)
    local ok, iter, dir_obj = pcall(lfs.dir, current_dir)
    if not ok then
      return
    end

    for entry in iter, dir_obj do
      if entry ~= '.' and entry ~= '..' then
        local full_path = path.join(current_dir, entry)
        local attr = lfs.attributes(full_path)

        if attr then
          if attr.mode == 'file' then
            if self:should_watch(full_path) then
              files[full_path] = get_mtime(full_path, self.follow_symlinks)
            end
          elseif attr.mode == 'directory' and self.recursive then
            scan(full_path)
          end
        end
      end
    end
  end

  scan(dir)
  return files
end

-- Add a directory to watch
function LfsWatcher:watch(dir)
  table.insert(self.directories, dir)

  -- Initial scan
  local files = self:scan_directory(dir)
  for filepath, mtime in pairs(files) do
    self.watched_files[filepath] = mtime
  end
end

-- Add multiple directories
function LfsWatcher:watch_all(dirs)
  for _, dir in ipairs(dirs) do
    self:watch(dir)
  end
end

-- Check for changes (single poll)
function LfsWatcher:poll()
  local changed = {}

  -- Check existing files for changes
  for filepath, old_mtime in pairs(self.watched_files) do
    local new_mtime = get_mtime(filepath, self.follow_symlinks)

    if not new_mtime then
      -- File was deleted
      table.insert(changed, { path = filepath, event = 'deleted' })
      self.watched_files[filepath] = nil
    elseif new_mtime ~= old_mtime then
      -- File was modified
      table.insert(changed, { path = filepath, event = 'modified' })
      self.watched_files[filepath] = new_mtime
    end
  end

  -- Scan for new files
  for _, dir in ipairs(self.directories) do
    local files = self:scan_directory(dir)
    for filepath, mtime in pairs(files) do
      if not self.watched_files[filepath] then
        -- New file
        table.insert(changed, { path = filepath, event = 'created' })
        self.watched_files[filepath] = mtime
      end
    end
  end

  return changed
end

-- Set the callback for file changes
function LfsWatcher:on_change(callback)
  self.callback = callback
end

-- Start watching (blocking loop)
function LfsWatcher:start()
  self.running = true

  while self.running do
    local changed = self:poll()

    if #changed > 0 and self.callback then
      self.callback(changed)
    end

    -- Sleep for poll interval
    local ok, socket = pcall(require, 'socket')
    if ok and socket.sleep then
      socket.sleep(self.poll_interval)
    else
      -- Fallback: busy wait (not ideal)
      local start = os.clock()
      while os.clock() - start < self.poll_interval do end
    end
  end
end

-- Stop watching
function LfsWatcher:stop()
  self.running = false
end

-- Get watcher type
function LfsWatcher:type()
  return 'lfs'
end

return LfsWatcher
