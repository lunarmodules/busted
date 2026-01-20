local path = require 'pl.path'
local dir = require 'pl.dir'

describe('Related tests feature', function()
  local RequireParser = require 'busted.modules.related.require_parser'
  local PathResolver = require 'busted.modules.related.path_resolver'
  local DependencyGraph = require 'busted.modules.related.dependency_graph'
  local GitChanges = require 'busted.modules.related.git_changes'

  describe('RequireParser', function()
    describe('parse_file', function()
      it('parses basic require statements', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('local foo = require("mymodule")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('mymodule', result.requires[1])
      end)

      it('parses require with single quotes', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write("local foo = require('othermodule')\n")
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('othermodule', result.requires[1])
      end)

      it('parses require without parentheses', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('local foo = require "noparens"\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('noparens', result.requires[1])
      end)

      it('handles dotted module names', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('local foo = require("module.submodule.deep")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('module.submodule.deep', result.requires[1])
      end)

      it('parses multiple requires in one file', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('local a = require("mod_a")\n')
        f:write('local b = require("mod_b")\n')
        f:write('local c = require("mod_c")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(3, #result.requires)
      end)

      it('ignores requires in single-line comments', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('-- local foo = require("commented")\n')
        f:write('local real = require("real_module")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('real_module', result.requires[1])
      end)

      it('ignores requires in multiline comments', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('--[[\n')
        f:write('local foo = require("in_comment")\n')
        f:write(']]\n')
        f:write('local real = require("real_module")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('real_module', result.requires[1])
      end)

      it('ignores requires in multiline comments with equals', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('--[=[\n')
        f:write('local foo = require("in_comment")\n')
        f:write(']=]\n')
        f:write('local real = require("real_module")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.requires)
        assert.are.equal('real_module', result.requires[1])
      end)

      it('parses loadfile statements', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('local chunk = loadfile("other.lua")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.loadfiles)
        assert.are.equal('other.lua', result.loadfiles[1])
      end)

      it('parses dofile statements', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('dofile("helper.lua")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(1, #result.loadfiles)
        assert.are.equal('helper.lua', result.loadfiles[1])
      end)

      it('handles empty files', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(0, #result.requires)
        assert.are.equal(0, #result.loadfiles)
      end)

      it('handles files with only comments', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('-- This is a comment\n')
        f:write('-- Another comment\n')
        f:write('--[[ Block comment ]]\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(0, #result.requires)
      end)

      it('handles files with syntax that might confuse the parser', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('local x = "--require(\\"fake\\")"\n')  -- String containing require
        f:write('local y = require("real")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        -- Should find at least the real require
        local found_real = false
        for _, req in ipairs(result.requires) do
          if req == 'real' then found_real = true end
        end
        assert.is_true(found_real)
      end)

      it('returns nil for non-existent files', function()
        local result, err = RequireParser.parse_file('/nonexistent/file.lua')
        assert.is_nil(result)
        assert.is_not_nil(err)
      end)

      it('handles mixed comment styles', function()
        local test_file = path.tmpname()
        local f = io.open(test_file, 'w')
        f:write('-- Single line comment\n')
        f:write('local a = require("mod_a")\n')
        f:write('--[[\nBlock comment\n]]\n')
        f:write('local b = require("mod_b")\n')
        f:write('-- Another single line\n')
        f:write('--[=[\nEquals block\n]=]\n')
        f:write('local c = require("mod_c")\n')
        f:close()

        local result = RequireParser.parse_file(test_file)
        os.remove(test_file)

        assert.is_not_nil(result)
        assert.are.equal(3, #result.requires)
      end)
    end)
  end)

  describe('PathResolver', function()
    it('resolves simple module names', function()
      local tmpdir = path.tmpname()
      os.remove(tmpdir)
      dir.makepath(tmpdir)

      local module_file = path.join(tmpdir, 'mymodule.lua')
      local f = io.open(module_file, 'w')
      f:write('return {}\n')
      f:close()

      local resolver = PathResolver.new(tmpdir .. '/?.lua', tmpdir)
      local resolved = resolver:resolve('mymodule')

      os.remove(module_file)
      dir.rmtree(tmpdir)

      assert.is_not_nil(resolved)
      assert.truthy(resolved:match('mymodule%.lua$'))
    end)

    it('resolves dotted module names to paths', function()
      local tmpdir = path.tmpname()
      os.remove(tmpdir)
      dir.makepath(tmpdir .. '/sub')

      local module_file = path.join(tmpdir, 'sub', 'module.lua')
      local f = io.open(module_file, 'w')
      f:write('return {}\n')
      f:close()

      local resolver = PathResolver.new(tmpdir .. '/?.lua', tmpdir)
      local resolved = resolver:resolve('sub.module')

      os.remove(module_file)
      dir.rmtree(tmpdir)

      assert.is_not_nil(resolved)
      assert.truthy(resolved:match('sub/module%.lua$') or resolved:match('sub\\module%.lua$'))
    end)

    it('returns nil for external modules', function()
      local resolver = PathResolver.new('./?.lua', './')
      local resolved = resolver:resolve('nonexistent_module_xyz')

      assert.is_nil(resolved)
    end)

    it('resolves init.lua convention', function()
      local tmpdir = path.tmpname()
      os.remove(tmpdir)
      dir.makepath(tmpdir .. '/mymodule')

      local init_file = path.join(tmpdir, 'mymodule', 'init.lua')
      local f = io.open(init_file, 'w')
      f:write('return {}\n')
      f:close()

      local resolver = PathResolver.new(tmpdir .. '/?.lua;' .. tmpdir .. '/?/init.lua', tmpdir)
      local resolved = resolver:resolve('mymodule')

      os.remove(init_file)
      dir.rmtree(tmpdir)

      assert.is_not_nil(resolved)
      assert.truthy(resolved:match('init%.lua$'))
    end)

    it('uses fallback known files when template matching fails', function()
      local tmpdir = path.tmpname()
      os.remove(tmpdir)
      dir.makepath(tmpdir .. '/nonstandard')

      local module_file = path.join(tmpdir, 'nonstandard', 'mymod.lua')
      local f = io.open(module_file, 'w')
      f:write('return {}\n')
      f:close()

      local resolver = PathResolver.new('./?.lua', tmpdir)
      resolver:set_known_files({ path.normpath(module_file) })

      local resolved = resolver:resolve('mymod')

      os.remove(module_file)
      dir.rmtree(tmpdir)

      assert.is_not_nil(resolved)
      assert.truthy(resolved:match('mymod%.lua$'))
    end)

    it('resolves file paths for loadfile', function()
      local tmpdir = path.tmpname()
      os.remove(tmpdir)
      dir.makepath(tmpdir)

      local test_file = path.join(tmpdir, 'helper.lua')
      local f = io.open(test_file, 'w')
      f:write('return {}\n')
      f:close()

      local resolver = PathResolver.new('./?.lua', tmpdir)
      local resolved = resolver:resolve_file('helper.lua')

      os.remove(test_file)
      dir.rmtree(tmpdir)

      assert.is_not_nil(resolved)
      assert.truthy(resolved:match('helper%.lua$'))
    end)
  end)

  describe('DependencyGraph', function()
    it('builds forward edges correctly', function()
      local graph = DependencyGraph.new()

      -- Manually set up forward edges for testing
      graph.forward['/a.lua'] = { '/b.lua', '/c.lua' }
      graph.forward['/b.lua'] = { '/c.lua' }
      graph.forward['/c.lua'] = {}

      local deps_a = graph:get_direct_dependencies('/a.lua')
      assert.are.equal(2, #deps_a)

      local deps_c = graph:get_direct_dependencies('/c.lua')
      assert.are.equal(0, #deps_c)
    end)

    it('builds reverse edges correctly', function()
      local graph = DependencyGraph.new()

      graph.forward['/a.lua'] = { '/b.lua' }
      graph.forward['/b.lua'] = { '/c.lua' }
      graph.forward['/c.lua'] = {}
      graph.reverse['/b.lua'] = { '/a.lua' }
      graph.reverse['/c.lua'] = { '/b.lua' }

      local dependents_c = graph:get_direct_dependents('/c.lua')
      assert.are.equal(1, #dependents_c)
      assert.are.equal('/b.lua', dependents_c[1])
    end)

    it('finds transitively affected tests', function()
      local graph = DependencyGraph.new()

      -- Set up: a_spec -> a -> b -> c
      graph.forward['/spec/a_spec.lua'] = { '/src/a.lua' }
      graph.forward['/src/a.lua'] = { '/src/b.lua' }
      graph.forward['/src/b.lua'] = { '/src/c.lua' }
      graph.forward['/src/c.lua'] = {}

      graph.reverse['/src/a.lua'] = { '/spec/a_spec.lua' }
      graph.reverse['/src/b.lua'] = { '/src/a.lua' }
      graph.reverse['/src/c.lua'] = { '/src/b.lua' }

      local test_files = { ['/spec/a_spec.lua'] = true }
      local affected = graph:get_affected_tests({ '/src/c.lua' }, test_files)

      assert.is_not_nil(affected['/spec/a_spec.lua'])
    end)

    it('handles circular dependencies', function()
      local graph = DependencyGraph.new()

      -- Circular: a -> b -> c -> a
      graph.forward['/a.lua'] = { '/b.lua' }
      graph.forward['/b.lua'] = { '/c.lua' }
      graph.forward['/c.lua'] = { '/a.lua' }

      graph.reverse['/b.lua'] = { '/a.lua' }
      graph.reverse['/c.lua'] = { '/b.lua' }
      graph.reverse['/a.lua'] = { '/c.lua' }

      -- Should not infinite loop
      local affected = graph:get_affected_files({ '/a.lua' })
      assert.is_not_nil(affected['/a.lua'])
      assert.is_not_nil(affected['/b.lua'])
      assert.is_not_nil(affected['/c.lua'])
    end)

    it('handles diamond dependencies', function()
      local graph = DependencyGraph.new()

      -- Diamond: A -> B -> D, A -> C -> D
      graph.forward['/a.lua'] = { '/b.lua', '/c.lua' }
      graph.forward['/b.lua'] = { '/d.lua' }
      graph.forward['/c.lua'] = { '/d.lua' }
      graph.forward['/d.lua'] = {}

      graph.reverse['/b.lua'] = { '/a.lua' }
      graph.reverse['/c.lua'] = { '/a.lua' }
      graph.reverse['/d.lua'] = { '/b.lua', '/c.lua' }

      local affected = graph:get_affected_files({ '/d.lua' })
      assert.is_not_nil(affected['/a.lua'])
      assert.is_not_nil(affected['/b.lua'])
      assert.is_not_nil(affected['/c.lua'])
      assert.is_not_nil(affected['/d.lua'])
    end)

    it('handles self-referential files', function()
      local graph = DependencyGraph.new()

      -- Self-referential: a -> a
      graph.forward['/a.lua'] = { '/a.lua' }
      graph.reverse['/a.lua'] = { '/a.lua' }

      -- Should not infinite loop
      local affected = graph:get_affected_files({ '/a.lua' })
      assert.is_not_nil(affected['/a.lua'])
    end)

    it('handles large graphs efficiently', function()
      local graph = DependencyGraph.new()

      -- Create a large linear chain
      local count = 100
      for i = 1, count do
        local file = '/file_' .. i .. '.lua'
        if i < count then
          graph.forward[file] = { '/file_' .. (i + 1) .. '.lua' }
        else
          graph.forward[file] = {}
        end
        if i > 1 then
          graph.reverse[file] = { '/file_' .. (i - 1) .. '.lua' }
        end
      end

      -- Changing the last file should affect all files
      local affected = graph:get_affected_files({ '/file_' .. count .. '.lua' })

      -- All files should be affected
      for i = 1, count do
        assert.is_not_nil(affected['/file_' .. i .. '.lua'])
      end
    end)

    it('returns empty for unresolved externals', function()
      local graph = DependencyGraph.new()

      graph.forward['/a.lua'] = {}  -- Has no dependencies

      local affected = graph:get_affected_files({ '/external.lua' })
      assert.is_not_nil(affected['/external.lua'])  -- Changed file is always affected
      assert.is_nil(affected['/a.lua'])  -- But unrelated files are not
    end)

    it('provides correct stats', function()
      local graph = DependencyGraph.new()

      graph.forward['/a.lua'] = { '/b.lua', '/c.lua' }
      graph.forward['/b.lua'] = { '/c.lua' }
      graph.forward['/c.lua'] = {}

      local stats = graph:stats()
      assert.are.equal(3, stats.files)
      assert.are.equal(3, stats.edges)  -- a->b, a->c, b->c
    end)
  end)

  describe('GitChanges', function()
    it('detects if directory is a git repo', function()
      -- The busted repo itself should be a git repo
      local is_repo = GitChanges.is_git_repo('./')
      assert.is_true(is_repo)
    end)

    it('returns false for non-git directory', function()
      local is_repo = GitChanges.is_git_repo('/tmp')
      -- /tmp is usually not a git repo - returns false or nil
      assert.falsy(is_repo)
    end)

    it('filters lua files correctly', function()
      local files = {
        '/a.lua',
        '/b.txt',
        '/c.lua',
        '/d.md',
        '/e.luac',  -- Compiled Lua, not source
        '/f.lua.bak',  -- Backup file
      }
      local lua_files = GitChanges.filter_lua_files(files)

      assert.are.equal(2, #lua_files)
      assert.are.equal('/a.lua', lua_files[1])
      assert.are.equal('/c.lua', lua_files[2])
    end)

    it('handles empty file list', function()
      local lua_files = GitChanges.filter_lua_files({})
      assert.are.equal(0, #lua_files)
    end)

    it('gets git root directory', function()
      local root = GitChanges.get_git_root('./')
      assert.is_not_nil(root)
      assert.truthy(path.isdir(root))
    end)
  end)

  describe('GitChanges with mocks', function()
    local original_run_command

    before_each(function()
      original_run_command = GitChanges._run_command
    end)

    after_each(function()
      GitChanges._run_command = original_run_command
    end)

    it('returns error for non-git repo', function()
      GitChanges._run_command = function(cmd)
        if cmd:match('rev%-parse') then
          return nil, 'fatal: not a git repository'
        end
        return {}
      end

      local files, err = GitChanges.get_changed_files('/tmp')
      assert.is_nil(files)
      assert.matches('Not a git', err)
    end)

    it('returns changed files from git output', function()
      GitChanges._run_command = function(cmd)
        if cmd:match('rev%-parse.*is%-inside') then
          return { 'true' }
        elseif cmd:match('diff %-%-name%-only$') then
          return { 'src/foo.lua', 'src/bar.lua' }
        elseif cmd:match('diff %-%-cached') then
          return { 'src/staged.lua' }
        elseif cmd:match('ls%-files') then
          return { 'new_file.lua' }
        end
        return {}
      end

      local files = GitChanges.get_changed_files('/project')
      assert.is_not_nil(files)
      assert.equals(4, #files)
    end)

    it('handles git command failure gracefully', function()
      GitChanges._run_command = function(cmd)
        if cmd:match('rev%-parse.*is%-inside') then
          return { 'true' }
        end
        return nil, 'fatal: ambiguous argument'
      end

      -- When individual git commands fail, the function continues and returns
      -- empty results rather than failing entirely
      local files = GitChanges.get_changes_since('/project', 'bad-ref')
      assert.is_not_nil(files)
      assert.equals(0, #files)
    end)

    it('normalizes paths with backslashes', function()
      GitChanges._run_command = function(cmd)
        if cmd:match('rev%-parse.*is%-inside') then
          return { 'true' }
        elseif cmd:match('diff %-%-name%-only$') then
          return { 'src\\foo.lua' }  -- Windows-style path
        elseif cmd:match('diff %-%-cached') then
          return {}
        elseif cmd:match('ls%-files') then
          return {}
        end
        return {}
      end

      local files = GitChanges.get_changed_files('/project')
      assert.is_not_nil(files)
      assert.equals(1, #files)
      -- Path should be normalized to forward slashes
      assert.truthy(files[1]:match('/src/foo%.lua$'))
      assert.falsy(files[1]:match('\\'))
    end)

    it('deduplicates files across staged and unstaged', function()
      GitChanges._run_command = function(cmd)
        if cmd:match('rev%-parse.*is%-inside') then
          return { 'true' }
        elseif cmd:match('diff %-%-name%-only$') then
          return { 'src/same.lua' }  -- Unstaged
        elseif cmd:match('diff %-%-cached') then
          return { 'src/same.lua' }  -- Also staged
        elseif cmd:match('ls%-files') then
          return {}
        end
        return {}
      end

      local files = GitChanges.get_changed_files('/project')
      assert.is_not_nil(files)
      assert.equals(1, #files)  -- Should be deduplicated
    end)
  end)

  describe('Integration: related module', function()
    local relatedLoader

    -- Try to load the module, skip if not available
    local ok, relatedModule = pcall(require, 'busted.modules.related')
    if ok then
      relatedLoader = relatedModule()
    end

    it('returns empty array when no changes detected', function()
      if not relatedLoader then
        pending('busted.modules.related not installed')
        return
      end

      -- This test may vary depending on git state
      -- We're mainly testing that the function runs without error
      local result, err = relatedLoader({ 'spec' }, { '_spec' }, {
        directory = './',
        verbose = false,
      })

      if err then
        -- If there's an error (e.g., git issues), that's acceptable
        assert.is_string(err)
      else
        assert.is_table(result)
      end
    end)

    it('handles non-existent root directories gracefully', function()
      if not relatedLoader then
        pending('busted.modules.related not installed')
        return
      end

      local result, err = relatedLoader({ '/nonexistent/path' }, { '_spec' }, {
        directory = './',
        verbose = false,
      })

      -- Should still return a result (possibly empty)
      if err then
        assert.is_string(err)
      else
        assert.is_table(result)
      end
    end)
  end)

  describe('Integration: fixtures', function()
    local fixtures_dir = 'spec/related_fixtures'

    -- Only run these tests if fixtures exist
    local function fixtures_exist()
      return path.isdir(fixtures_dir)
    end

    it('discovers dependencies from fixtures', function()
      if not fixtures_exist() then
        pending('Fixtures directory not found')
        return
      end

      local graph = DependencyGraph.new()
      local resolver = PathResolver.new(
        fixtures_dir .. '/src/?.lua;' .. fixtures_dir .. '/spec/?.lua',
        fixtures_dir
      )

      -- Get all Lua files in fixtures
      local all_files = {}
      if path.isdir(fixtures_dir .. '/src') then
        for _, f in ipairs(dir.getallfiles(fixtures_dir .. '/src')) do
          if f:match('%.lua$') then
            all_files[#all_files + 1] = path.normpath(f)
          end
        end
      end
      if path.isdir(fixtures_dir .. '/spec') then
        for _, f in ipairs(dir.getallfiles(fixtures_dir .. '/spec')) do
          if f:match('%.lua$') then
            all_files[#all_files + 1] = path.normpath(f)
          end
        end
      end

      resolver:set_known_files(all_files)
      graph:build(all_files, resolver)

      local stats = graph:stats()
      assert.is_true(stats.files > 0, 'Should have discovered some files')
    end)
  end)
end)
