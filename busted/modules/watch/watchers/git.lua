-- Git status polling watcher
-- Uses git status --porcelain as a fallback when lfs is unavailable

local path = require 'pl.path'

local GitWatcher = {}
GitWatcher.__index = GitWatcher

function GitWatcher.new(options)
  local self = setmetatable({}, GitWatcher)
  self.poll_interval = (options.poll_interval or 1000) / 1000  -- Convert ms to seconds
  self.directories = {}
  self.extensions = options.extensions or { '.lua' }
  self.include_patterns = options.include_patterns or {}
  self.exclude_patterns = options.exclude_patterns or {}
  self.last_status = {}
  self.callback = nil
  self.running = false
  return self
end

-- Check if a file matches the extension filter
function GitWatcher:matches_extension(filepath)
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
function GitWatcher:should_watch(filepath)
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

-- Execute a command and capture output
local function execute_command(cmd)
  local handle = io.popen(cmd .. ' 2>/dev/null', 'r')
  if not handle then
    return nil
  end
  local result = handle:read('*a')
  handle:close()
  return result
end

-- Check if we're in a git repository
function GitWatcher:is_git_repo()
  local result = execute_command('git rev-parse --is-inside-work-tree')
  return result and result:match('true')
end

-- Get git status for tracked and untracked files
function GitWatcher:get_git_status()
  local status = {}

  -- Get modified and untracked files
  local result = execute_command('git status --porcelain')
  if not result then
    return status
  end

  for line in result:gmatch('[^\n]+') do
    -- Parse git status output: XY filename
    local state = line:sub(1, 2)
    local filepath = line:sub(4)

    -- Handle renamed files (R -> source -> dest)
    if filepath:match(' %-> ') then
      filepath = filepath:match(' %-> (.+)$')
    end

    if self:should_watch(filepath) then
      status[filepath] = state
    end
  end

  return status
end

-- Get list of all tracked files with their hashes
function GitWatcher:get_tracked_files()
  local files = {}

  local result = execute_command('git ls-files -s')
  if not result then
    return files
  end

  for line in result:gmatch('[^\n]+') do
    -- Parse: mode hash stage\tfilepath
    local hash, filepath = line:match('^%d+ (%x+) %d+\t(.+)$')
    if hash and filepath and self:should_watch(filepath) then
      files[filepath] = hash
    end
  end

  return files
end

-- Add a directory to watch
function GitWatcher:watch(dir)
  table.insert(self.directories, dir)
end

-- Add multiple directories
function GitWatcher:watch_all(dirs)
  for _, dir in ipairs(dirs) do
    self:watch(dir)
  end
end

-- Check for changes (single poll)
function GitWatcher:poll()
  local changed = {}
  local current_status = self:get_git_status()

  -- Check for new or changed files
  for filepath, state in pairs(current_status) do
    local old_state = self.last_status[filepath]
    if not old_state or old_state ~= state then
      local event = 'modified'
      if state:match('^%?') then
        event = 'created'
      elseif state:match('^D') or state:match('^.D') then
        event = 'deleted'
      end
      table.insert(changed, { path = filepath, event = event })
    end
  end

  -- Check for files that are no longer in status (reverted)
  for filepath, _ in pairs(self.last_status) do
    if not current_status[filepath] then
      table.insert(changed, { path = filepath, event = 'reverted' })
    end
  end

  self.last_status = current_status
  return changed
end

-- Set the callback for file changes
function GitWatcher:on_change(callback)
  self.callback = callback
end

-- Start watching (blocking loop)
function GitWatcher:start()
  -- Initial status capture
  self.last_status = self:get_git_status()
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
function GitWatcher:stop()
  self.running = false
end

-- Get watcher type
function GitWatcher:type()
  return 'git'
end

return GitWatcher
