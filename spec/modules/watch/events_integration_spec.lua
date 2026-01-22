-- Integration tests for Events module with real file watcher
-- These tests create actual files and verify file change detection works

local lfs = require 'lfs'
local path = require 'pl.path'
local file = require 'pl.file'
local dir = require 'pl.dir'
local Events = require 'busted.modules.watch.events'
local LfsWatcher = require 'busted.modules.watch.watchers.lfs'

describe('Events integration', function()
  local temp_dir
  local test_file

  -- Create temp directory before each test
  before_each(function()
    -- Use os.tmpname() for portable temp file name, then make it a directory
    local tmpname = os.tmpname()
    -- On some systems, os.tmpname creates the file, so remove it first
    os.remove(tmpname)
    temp_dir = tmpname .. '_events_test'
    lfs.mkdir(temp_dir)
    test_file = path.join(temp_dir, 'test.lua')
    file.write(test_file, '-- initial content')
  end)

  -- Clean up temp directory after each test
  after_each(function()
    if temp_dir and path.exists(temp_dir) then
      dir.rmtree(temp_dir)
    end
  end)

  describe('with real LFS watcher', function()
    it('detects file modifications', function()
      -- Create watcher watching the temp directory
      local watcher = LfsWatcher.new({
        extensions = { '.lua' },
        recursive = true,
        poll_interval = 10  -- Fast polling for tests
      })
      watcher:watch(temp_dir)

      -- Create events with the real watcher
      local events = Events.new(watcher)

      -- First poll should show no changes (initial state captured)
      local evts = events:poll({ timeout = 0.001 })
      assert.equal(1, #evts)
      assert.equal('timeout', evts[1].type)

      -- Wait for file system mtime to change (some systems have 1s resolution)
      local system = require 'system'
      system.sleep(1.1)

      -- Modify the file
      file.write(test_file, '-- modified content ' .. os.time())

      -- Poll again - should detect the change
      evts = events:poll({ timeout = 0.001 })
      local file_event_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'file' and evt.path:match('test%.lua$') then
          file_event_found = true
          assert.is_nil(evt.change)  -- No 'change' field in new API
        end
      end
      assert.is_true(file_event_found, 'Expected to detect file modification')
    end)

    it('detects new file creation', function()
      -- Create watcher watching the temp directory
      local watcher = LfsWatcher.new({
        extensions = { '.lua' },
        recursive = true,
        poll_interval = 10
      })
      watcher:watch(temp_dir)

      -- Create events with the real watcher
      local events = Events.new(watcher)

      -- Initial poll
      events:poll({ timeout = 0.001 })

      -- Create a new file
      local new_file = path.join(temp_dir, 'new_test.lua')
      file.write(new_file, '-- new file')

      -- Poll - should detect the new file
      local evts = events:poll({ timeout = 0.001 })
      local new_file_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'file' and evt.path:match('new_test%.lua$') then
          new_file_found = true
        end
      end
      assert.is_true(new_file_found, 'Expected to detect new file creation')
    end)

    it('respects debounce option', function()
      -- Create watcher
      local watcher = LfsWatcher.new({
        extensions = { '.lua' },
        recursive = true,
        poll_interval = 10
      })
      watcher:watch(temp_dir)

      local events = Events.new(watcher)

      -- Initial poll
      events:poll({ timeout = 0.001, debounce = 100 })

      -- Wait for mtime resolution and modify file
      local system = require 'system'
      system.sleep(1.1)  -- Wait for mtime resolution
      file.write(test_file, '-- modified again ' .. os.time())

      -- Poll immediately with debounce - should not emit yet (change goes to debouncer)
      local evts = events:poll({ timeout = 0.001, debounce = 100 })
      local immediate_file_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'file' then
          immediate_file_found = true
        end
      end
      assert.is_false(immediate_file_found, 'Should not emit immediately with debounce')
      assert.is_true(events:has_pending_changes())

      -- Wait for debounce period
      system.sleep(0.15)  -- 150ms > 100ms debounce

      -- Poll again - should emit now
      evts = events:poll({ timeout = 0.001, debounce = 100 })
      local debounced_file_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'file' and evt.path:match('test%.lua$') then
          debounced_file_found = true
        end
      end
      assert.is_true(debounced_file_found, 'Expected to emit after debounce period')
    end)

    it('filters by extension', function()
      -- Create watcher that only watches .lua files
      local watcher = LfsWatcher.new({
        extensions = { '.lua' },
        recursive = true,
        poll_interval = 10
      })
      watcher:watch(temp_dir)

      local events = Events.new(watcher)

      -- Initial poll
      events:poll({ timeout = 0.001 })

      -- Create a .txt file (should be ignored)
      local txt_file = path.join(temp_dir, 'test.txt')
      file.write(txt_file, 'text content')

      -- Create a .lua file (should be detected)
      local lua_file = path.join(temp_dir, 'test2.lua')
      file.write(lua_file, '-- lua content')

      -- Poll
      local evts = events:poll({ timeout = 0.001 })
      local txt_found = false
      local lua_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'file' then
          if evt.path:match('%.txt$') then txt_found = true end
          if evt.path:match('test2%.lua$') then lua_found = true end
        end
      end
      assert.is_false(txt_found, 'Should not detect .txt file')
      assert.is_true(lua_found, 'Should detect .lua file')
    end)
  end)
end)
