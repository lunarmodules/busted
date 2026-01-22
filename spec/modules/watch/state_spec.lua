local State = require 'busted.modules.watch.state'
local path = require 'pl.path'

describe('State', function()
  local state
  local cwd = path.currentdir()

  before_each(function()
    state = State.new({ project_paths = { cwd } })
  end)

  describe('new', function()
    it('creates a state with default options', function()
      local s = State.new({})
      assert.is_table(s.project_paths)
      assert.is_table(s.tracked_modules)
    end)

    it('creates a state with custom project paths', function()
      local s = State.new({ project_paths = { '/custom/path' } })
      assert.equals('/custom/path', s.project_paths[1])
    end)
  end)

  describe('is_project_module', function()
    it('returns false for nil path', function()
      assert.is_false(state:is_project_module(nil))
    end)

    it('returns true for path within project', function()
      local test_path = path.join(cwd, 'some', 'file.lua')
      assert.is_true(state:is_project_module(test_path))
    end)

    it('returns false for path outside project', function()
      assert.is_false(state:is_project_module('/completely/different/path.lua'))
    end)
  end)

  describe('get_tracked', function()
    it('returns empty list initially', function()
      local tracked = state:get_tracked()
      assert.equals(0, #tracked)
    end)
  end)

  describe('clear_all', function()
    it('clears tracked modules', function()
      -- Manually add some tracked modules for testing
      state.tracked_modules['test.module'] = '/path/to/test/module.lua'
      package.loaded['test.module'] = {}

      local cleared = state:clear_all()
      assert.equals(1, #cleared)
      assert.equals('test.module', cleared[1])
      assert.is_nil(package.loaded['test.module'])
    end)

    it('returns empty list when nothing tracked', function()
      local cleared = state:clear_all()
      assert.equals(0, #cleared)
    end)
  end)

  describe('invalidate', function()
    it('removes modules from package.loaded', function()
      -- Setup a tracked module
      local test_path = path.join(cwd, 'test_module.lua')
      state.tracked_modules['test.module'] = test_path
      package.loaded['test.module'] = {}

      local invalidated = state:invalidate({ test_path })
      assert.equals(1, #invalidated)
      assert.is_nil(package.loaded['test.module'])
    end)

    it('only invalidates matching files', function()
      local test_path1 = path.join(cwd, 'module1.lua')
      local test_path2 = path.join(cwd, 'module2.lua')

      state.tracked_modules['module1'] = test_path1
      state.tracked_modules['module2'] = test_path2
      package.loaded['module1'] = {}
      package.loaded['module2'] = {}

      local invalidated = state:invalidate({ test_path1 })
      assert.equals(1, #invalidated)
      assert.is_nil(package.loaded['module1'])
      assert.is_not_nil(package.loaded['module2'])

      -- Cleanup
      package.loaded['module2'] = nil
    end)
  end)
end)
