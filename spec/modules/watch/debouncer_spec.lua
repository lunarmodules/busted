local Debouncer = require 'busted.modules.watch.debouncer'

describe('Debouncer', function()
  local debouncer

  before_each(function()
    debouncer = Debouncer.new(100)  -- 100ms delay
  end)

  describe('new', function()
    it('creates a debouncer with default delay', function()
      local d = Debouncer.new()
      assert.equals(300, d.delay_ms)
      assert.equals(0.3, d.delay_sec)
    end)

    it('creates a debouncer with custom delay', function()
      local d = Debouncer.new(500)
      assert.equals(500, d.delay_ms)
      assert.equals(0.5, d.delay_sec)
    end)
  end)

  describe('add', function()
    it('adds a file to pending set', function()
      debouncer:add('/path/to/file.lua')
      assert.is_true(debouncer:has_pending())
    end)

    it('deduplicates files', function()
      debouncer:add('/path/to/file.lua')
      debouncer:add('/path/to/file.lua')
      local files = debouncer:flush()
      assert.equals(1, #files)
    end)

    it('tracks multiple files', function()
      debouncer:add('/path/to/file1.lua')
      debouncer:add('/path/to/file2.lua')
      local files = debouncer:flush()
      assert.equals(2, #files)
    end)
  end)

  describe('has_pending', function()
    it('returns false when no files pending', function()
      assert.is_false(debouncer:has_pending())
    end)

    it('returns true when files are pending', function()
      debouncer:add('/path/to/file.lua')
      assert.is_true(debouncer:has_pending())
    end)
  end)

  describe('ready', function()
    it('returns false when no events', function()
      assert.is_false(debouncer:ready())
    end)

    it('returns false immediately after adding', function()
      debouncer:add('/path/to/file.lua')
      assert.is_false(debouncer:ready())
    end)
  end)

  describe('flush', function()
    it('returns empty list when no pending files', function()
      local files = debouncer:flush()
      assert.equals(0, #files)
    end)

    it('returns list of pending files', function()
      debouncer:add('/path/to/file1.lua')
      debouncer:add('/path/to/file2.lua')
      local files = debouncer:flush()
      assert.equals(2, #files)
    end)

    it('clears pending files after flush', function()
      debouncer:add('/path/to/file.lua')
      debouncer:flush()
      assert.is_false(debouncer:has_pending())
    end)
  end)

  describe('reset', function()
    it('clears all pending files', function()
      debouncer:add('/path/to/file.lua')
      debouncer:reset()
      assert.is_false(debouncer:has_pending())
    end)
  end)

  describe('time_remaining', function()
    it('returns nil when no events', function()
      assert.is_nil(debouncer:time_remaining())
    end)

    it('returns remaining time after adding', function()
      debouncer:add('/path/to/file.lua')
      local remaining = debouncer:time_remaining()
      assert.is_not_nil(remaining)
      assert.is_true(remaining >= 0)
      assert.is_true(remaining <= 0.1)  -- Should be close to delay_sec
    end)
  end)
end)
