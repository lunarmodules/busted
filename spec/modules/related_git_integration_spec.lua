local path = require 'pl.path'
local dir = require 'pl.dir'
local GitChanges = require 'busted.modules.related.git_changes'

describe('GitChanges integration', function()
  local test_dir

  local function run(cmd)
    os.execute('cd ' .. test_dir .. ' && ' .. cmd .. ' 2>/dev/null')
  end

  local function write_file(name, content)
    local f = io.open(path.join(test_dir, name), 'w')
    f:write(content or '')
    f:close()
  end

  before_each(function()
    test_dir = os.tmpname() .. '_git_test'
    os.remove(test_dir)
    dir.makepath(test_dir)
    run('git init')
    run('git config user.email "test@test.com"')
    run('git config user.name "Test"')
  end)

  after_each(function()
    dir.rmtree(test_dir)
  end)

  it('detects no changes in clean repo', function()
    write_file('init.lua', 'return {}')
    run('git add . && git commit -m "init"')

    local files = GitChanges.get_changed_files(test_dir)
    assert.are.equal(0, #files)
  end)

  it('detects unstaged changes', function()
    write_file('foo.lua', 'return 1')
    run('git add . && git commit -m "init"')
    write_file('foo.lua', 'return 2')

    local files = GitChanges.get_changed_files(test_dir)
    assert.are.equal(1, #files)
    assert.matches('foo%.lua$', files[1])
  end)

  it('detects staged changes', function()
    write_file('foo.lua', 'return 1')
    run('git add . && git commit -m "init"')
    write_file('foo.lua', 'return 2')
    run('git add foo.lua')

    local files = GitChanges.get_changed_files(test_dir)
    assert.are.equal(1, #files)
  end)

  it('detects untracked files', function()
    write_file('tracked.lua', '')
    run('git add . && git commit -m "init"')
    write_file('untracked.lua', '')

    local files = GitChanges.get_changed_files(test_dir)
    assert.are.equal(1, #files)
    assert.matches('untracked%.lua$', files[1])
  end)

  it('detects changes since commit', function()
    write_file('old.lua', '')
    run('git add . && git commit -m "old"')
    write_file('new.lua', '')
    run('git add . && git commit -m "new"')

    local files = GitChanges.get_changes_since(test_dir, 'HEAD~1')
    assert.are.equal(1, #files)
    assert.matches('new%.lua$', files[1])
  end)

  it('handles multiple changes at once', function()
    write_file('existing.lua', 'return 1')
    run('git add . && git commit -m "init"')

    -- Make various types of changes
    write_file('existing.lua', 'return 2')  -- Modified (unstaged)
    write_file('staged.lua', 'return {}')
    run('git add staged.lua')  -- Staged new file
    write_file('untracked.lua', '')  -- Untracked

    local files = GitChanges.get_changed_files(test_dir)
    assert.are.equal(3, #files)
  end)

  it('returns paths normalized to forward slashes', function()
    dir.makepath(path.join(test_dir, 'src', 'nested'))
    write_file('src/nested/file.lua', 'return 1')
    run('git add . && git commit -m "init"')
    write_file('src/nested/file.lua', 'return 2')

    local files = GitChanges.get_changed_files(test_dir)
    assert.are.equal(1, #files)
    -- Should contain forward slashes, not backslashes
    assert.truthy(files[1]:match('src/nested/file%.lua$'))
    assert.falsy(files[1]:match('\\'))
  end)
end)
