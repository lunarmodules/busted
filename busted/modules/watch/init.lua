-- Watch mode orchestrator for Busted
-- Main entry point for watch mode functionality

local path = require 'pl.path'

local Watcher = require 'busted.modules.watch.watcher'
local State = require 'busted.modules.watch.state'
local Events = require 'busted.modules.watch.events'

local WatchMode = {}
WatchMode.__index = WatchMode

-- ANSI escape codes
local CLEAR_SCREEN = '\27[2J\27[H'

function WatchMode.new(busted, options)
  local self = setmetatable({}, WatchMode)

  self.busted = busted
  self.options = options or {}

  -- Configuration
  self.delay_ms = tonumber(options['watch-delay']) or 300
  self.extensions = self:build_extensions(options)
  self.include_patterns = options['watch-include'] or {}
  self.exclude_patterns = options['watch-exclude'] or {}
  self.follow_symlinks = options['watch-follow-symlinks'] or false
  self.directories = options.ROOT or { '.' }

  -- Components
  self.state = State.new({ project_paths = self.directories })
  self.watcher = nil
  self.events = nil  -- Initialized in start()

  -- State
  self.running = false
  self.last_exit_code = 0

  return self
end

-- Build list of extensions to watch based on options
function WatchMode:build_extensions(options)
  local extensions = { '.lua' }

  -- Add extensions from --watch-ext
  if options['watch-ext'] then
    for _, ext in ipairs(options['watch-ext']) do
      if ext:sub(1, 1) ~= '.' then
        ext = '.' .. ext
      end
      table.insert(extensions, ext)
    end
  end

  -- Add extensions from loaders
  local loaders = options.loaders or {}
  if type(loaders) == 'string' then
    loaders = { loaders }
  end

  for _, loader in ipairs(loaders) do
    if loader == 'moonscript' then
      table.insert(extensions, '.moon')
    elseif loader == 'fennel' then
      table.insert(extensions, '.fnl')
    elseif loader == 'terra' then
      table.insert(extensions, '.t')
    end
  end

  return extensions
end

-- Initialize the file watcher
function WatchMode:init_watcher()
  local watcher, warnings = Watcher.create({
    extensions = self.extensions,
    include_patterns = self.include_patterns,
    exclude_patterns = self.exclude_patterns,
    follow_symlinks = self.follow_symlinks,
    recursive = self.options.recursive ~= false,
    poll_interval = self.delay_ms,
  })

  if not watcher then
    for _, warning in ipairs(warnings) do
      io.stderr:write('watch: warning: ' .. warning .. '\n')
    end
    return nil, 'failed to initialize file watcher'
  end

  -- Print warnings about fallback
  for _, warning in ipairs(warnings) do
    io.stderr:write('watch: ' .. warning .. '\n')
  end

  self.watcher = watcher
  return true
end

-- Set up directories to watch
function WatchMode:setup_watches()
  -- Watch the root directories
  for _, dir in ipairs(self.directories) do
    if path.isdir(dir) then
      self.watcher:watch(dir)
    elseif path.isfile(dir) then
      -- If a specific file is given, watch its directory
      self.watcher:watch(path.dirname(dir))
    end
  end

  -- Also watch src/ if it exists
  if path.isdir('src') then
    self.watcher:watch('src')
  end
end

-- Clear the screen
function WatchMode:clear_screen()
  io.stdout:write(CLEAR_SCREEN)
  io.stdout:flush()
end

-- Run the test suite
function WatchMode:run_tests(files_filter)
  -- Clear project modules from cache
  self.state:clear_all()

  -- Reset abort flag
  self.busted.abortRequested = false

  -- Run the execute function
  local execute = require 'busted.execute'(self.busted)

  -- Take a snapshot of loaded modules after test run
  self.state:snapshot()

  return self.last_exit_code
end

-- Handle file change events from events module
function WatchMode:handle_file_event(evt)
  -- Invalidate changed modules
  self.state:invalidate({ evt.path })
  return true  -- Signal that tests should be run
end

-- Main watch loop
function WatchMode:start(run_tests_fn)
  self.running = true

  -- Initialize watcher
  local ok, err = self:init_watcher()
  if not ok then
    io.stderr:write('watch: error: ' .. err .. '\n')
    return 1
  end

  -- Set up directories to watch
  self:setup_watches()

  -- Create unified event poller
  self.events = Events.new(self.watcher)

  -- Initial test run
  self:clear_screen()
  self.last_exit_code = run_tests_fn()

  -- Take initial module snapshot
  self.state:snapshot()

  -- Print watching message
  io.stdout:write('\nWatching for file changes... (Ctrl+C to exit)\n')
  io.stdout:flush()

  -- Main loop using unified event polling
  while self.running do
    local evts = self.events:poll({ timeout = 0.1, debounce = self.delay_ms })

    local should_run_tests = false

    for _, evt in ipairs(evts) do
      if evt.type == 'file' then
        if self:handle_file_event(evt) then
          should_run_tests = true
        end
      elseif evt.type == 'error' then
        io.stderr:write('watch: ' .. evt.source .. ': ' .. evt.msg .. '\n')
      end
      -- 'timeout' events are ignored
    end

    -- Run tests if needed
    if self.running and should_run_tests then
      -- Signal abort if test is running
      self.busted.abortRequested = true
      self:clear_screen()
      self.last_exit_code = run_tests_fn()
      io.stdout:write('\nWatching for file changes... (Ctrl+C to exit)\n')
      io.stdout:flush()
    end
  end

  -- Cleanup: stop watcher
  self.watcher:stop()

  return self.last_exit_code
end

-- Stop the watch loop
function WatchMode:stop()
  self.running = false
end

-- Set the last exit code
function WatchMode:set_exit_code(code)
  self.last_exit_code = code
end

return WatchMode
