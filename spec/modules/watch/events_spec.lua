-- Tests for Events module (watch mode file change polling)

local Events = require 'busted.modules.watch.events'

describe('Events', function()
  -- Mock watcher module
  local function create_mock_watcher(opts)
    opts = opts or {}
    return {
      poll = function()
        if opts.poll_error then
          error(opts.poll_error)
        end
        return opts.changes or {}
      end,
    }
  end

  describe('new', function()
    it('creates an events instance', function()
      local watcher = create_mock_watcher()

      local events = Events.new(watcher)
      assert.is_not_nil(events)
      assert.equal(watcher, events.watcher)
      assert.is_nil(events.debouncer)  -- No debouncer by default
    end)
  end)

  describe('poll', function()
    it('returns timeout event when no events', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      local evts = events:poll({ timeout = 0.001 })
      assert.equal(1, #evts)
      assert.equal('timeout', evts[1].type)
    end)

    it('emits file events immediately without debounce option', function()
      local watcher = create_mock_watcher({
        changes = {
          { path = 'test.lua', event = 'modified' }
        }
      })
      local events = Events.new(watcher)

      -- Without debounce, events are emitted immediately
      local evts = events:poll({ timeout = 0.001 })
      assert.equal(1, #evts)
      assert.equal('file', evts[1].type)
      assert.equal('test.lua', evts[1].path)
      assert.is_nil(evts[1].change)  -- No 'change' field
    end)

    it('adds file changes to debouncer when debounce option set', function()
      local watcher = create_mock_watcher({
        changes = {
          { path = 'test.lua', event = 'modified' }
        }
      })
      local events = Events.new(watcher)

      -- First poll with debounce adds to debouncer but doesn't emit (not ready yet)
      local evts = events:poll({ timeout = 0.001, debounce = 100 })
      assert.equal(1, #evts)
      assert.equal('timeout', evts[1].type)
      assert.is_true(events:has_pending_changes())
    end)

    it('emits debounced events after delay', function()
      local call_count = 0
      local watcher = {
        poll = function()
          call_count = call_count + 1
          if call_count == 1 then
            return {{ path = 'test.lua', event = 'modified' }}
          end
          return {}
        end,
      }
      local events = Events.new(watcher)

      -- First poll - adds to debouncer
      events:poll({ timeout = 0.001, debounce = 1 })  -- 1ms debounce
      assert.is_true(events:has_pending_changes())

      -- Wait for debounce
      local system = require 'system'
      system.sleep(0.01)  -- 10ms should be enough

      -- Second poll - should emit
      local evts = events:poll({ timeout = 0.001, debounce = 1 })
      local file_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'file' then
          file_found = true
          assert.equal('test.lua', evt.path)
        end
      end
      assert.is_true(file_found)
    end)

    it('returns error event on watcher error', function()
      local watcher = create_mock_watcher({
        poll_error = 'watcher failed'
      })
      local events = Events.new(watcher)

      local evts = events:poll({ timeout = 0.001 })
      assert.is_true(#evts >= 1)

      local error_found = false
      for _, evt in ipairs(evts) do
        if evt.type == 'error' then
          error_found = true
          assert.equal('watcher', evt.source)
          assert.is_truthy(evt.msg:match('watcher failed'))
        end
      end
      assert.is_true(error_found)
    end)

    it('handles nil watcher gracefully', function()
      local events = Events.new(nil)

      local evts = events:poll({ timeout = 0.001 })
      assert.equal(1, #evts)
      assert.equal('timeout', evts[1].type)
    end)

    it('creates debouncer lazily when debounce option provided', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      assert.is_nil(events.debouncer)

      -- Poll without debounce - no debouncer created
      events:poll({ timeout = 0.001 })
      assert.is_nil(events.debouncer)

      -- Poll with debounce - debouncer created
      events:poll({ timeout = 0.001, debounce = 100 })
      assert.is_not_nil(events.debouncer)
    end)

    it('removes debouncer when debounce option removed', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      -- Poll with debounce
      events:poll({ timeout = 0.001, debounce = 100 })
      assert.is_not_nil(events.debouncer)

      -- Poll without debounce - debouncer removed
      events:poll({ timeout = 0.001 })
      assert.is_nil(events.debouncer)
    end)
  end)

  describe('poll_files', function()
    it('returns empty array when no changes', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      local file_events = events:poll_files()
      assert.same({}, file_events)
    end)

    it('emits file events immediately without debouncer', function()
      local watcher = create_mock_watcher({
        changes = {
          { path = 'file1.lua', event = 'modified' },
          { path = 'file2.lua', event = 'created' },
        }
      })
      local events = Events.new(watcher)

      local file_events = events:poll_files()
      assert.equal(2, #file_events)
      assert.equal('file', file_events[1].type)
      assert.equal('file1.lua', file_events[1].path)
      assert.equal('file', file_events[2].type)
      assert.equal('file2.lua', file_events[2].path)
    end)
  end)

  describe('has_pending_changes', function()
    it('returns false when no debouncer', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      assert.is_false(events:has_pending_changes())
    end)

    it('returns false when debouncer has no pending', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      -- Create debouncer by polling with debounce option
      events:poll({ timeout = 0.001, debounce = 100 })

      assert.is_false(events:has_pending_changes())
    end)

    it('returns true when debouncer has pending', function()
      local watcher = create_mock_watcher({
        changes = {{ path = 'test.lua' }}
      })
      local events = Events.new(watcher)

      -- Create debouncer and add changes
      events:poll({ timeout = 0.001, debounce = 100 })

      assert.is_true(events:has_pending_changes())
    end)
  end)

  describe('time_until_ready', function()
    it('returns nil when no debouncer', function()
      local watcher = create_mock_watcher()
      local events = Events.new(watcher)

      assert.is_nil(events:time_until_ready())
    end)

    it('returns time remaining when debouncer has pending', function()
      local watcher = create_mock_watcher({
        changes = {{ path = 'test.lua' }}
      })
      local events = Events.new(watcher)

      -- Create debouncer and add changes
      events:poll({ timeout = 0.001, debounce = 1000 })  -- 1 second delay

      local time = events:time_until_ready()
      assert.is_number(time)
      assert.is_true(time > 0)
    end)
  end)
end)
