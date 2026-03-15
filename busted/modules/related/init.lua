local path = require 'pl.path'
local dir = require 'pl.dir'

return function()
  local PathResolver = require 'busted.modules.related.path_resolver'
  local DependencyGraph = require 'busted.modules.related.dependency_graph'
  local GitChanges = require 'busted.modules.related.git_changes'

  -- Normalize paths to forward slashes for cross-platform consistency
  local function normalize(p)
    return p:gsub('\\', '/')
  end

  local function parse_file_list(files_str, cwd)
    local files = {}
    for file in files_str:gmatch('[^,]+') do
      file = file:match('^%s*(.-)%s*$')
      if file ~= '' then
        if not path.isabs(file) then
          file = path.join(cwd, file)
        end
        file = normalize(path.normpath(file))
        if path.isfile(file) then
          files[#files + 1] = file
        end
      end
    end
    return files
  end

  return function(rootFiles, patterns, options)
    if type(rootFiles) ~= 'table' then
      return nil, 'rootFiles must be a table'
    end
    if type(patterns) ~= 'table' then
      return nil, 'patterns must be a table'
    end

    options = options or {}
    local cwd = normalize(path.normpath(options.directory or './'))
    local verbose = options.verbose

    local changed_files, err
    local explicit_files = options.files

    if explicit_files and type(explicit_files) == 'string' and explicit_files ~= '' then
      changed_files = parse_file_list(explicit_files, cwd)

      if #changed_files == 0 then
        if verbose then
          io.stdout:write('No valid files found in --related list.\n')
        end
        return {}
      end

      if verbose then
        io.stdout:write('Using explicit file list:\n')
        for _, f in ipairs(changed_files) do
          io.stdout:write('  ' .. f .. '\n')
        end
      end
    else
      if not GitChanges.is_git_repo(cwd) then
        return nil, 'Not a git repository. Use --related=file1,file2,... to specify files directly.'
      end

      if options.base and options.base ~= 'HEAD' then
        changed_files, err = GitChanges.get_changes_since(cwd, options.base)
      else
        changed_files, err = GitChanges.get_changed_files(cwd)
      end

      if not changed_files then
        return nil, err
      end

      changed_files = GitChanges.filter_lua_files(changed_files)

      if #changed_files == 0 then
        if verbose then
          io.stdout:write('No Lua files changed.\n')
        end
        return {}
      end

      if verbose then
        io.stdout:write('Changed Lua files:\n')
        for _, f in ipairs(changed_files) do
          io.stdout:write('  ' .. f .. '\n')
        end
      end
    end

    local exclude_dirs = {
      ['.git'] = true, ['node_modules'] = true, ['vendor'] = true,
      ['.luarocks'] = true, ['luarocks'] = true, ['.cache'] = true,
    }

    local function is_test_file(filepath, test_patterns)
      local basename = path.basename(filepath)
      for _, patt in ipairs(test_patterns) do
        if basename:find(patt) then
          return true
        end
      end
      return false
    end

    local function is_excluded(filepath, excludes)
      if not excludes then return false end
      local basename = path.basename(filepath)
      for _, patt in ipairs(excludes) do
        if patt ~= '' and basename:find(patt) then
          return true
        end
      end
      return false
    end

    local all_files = {}
    local all_files_set = {}
    local test_files = {}

    local function add_file(normalized)
      if all_files_set[normalized] then
        return
      end

      all_files_set[normalized] = true
      all_files[#all_files + 1] = normalized

      if not is_excluded(normalized, options.excludes) and is_test_file(normalized, patterns) then
        test_files[normalized] = true
      end
    end

    local function collect_from_path(root)
      if path.isfile(root) then
        if root:match('%.lua$') then
          add_file(normalize(path.normpath(root)))
        end
      elseif path.isdir(root) then
        local getfiles = options.recursive ~= false and dir.getallfiles or dir.getfiles
        local files = getfiles(root)
        for _, file in ipairs(files) do
          if file:match('%.lua$') then
            add_file(normalize(path.normpath(file)))
          end
        end
      end
    end

    for _, root in ipairs(rootFiles) do
      collect_from_path(root)
    end

    local entries = dir.getdirectories(cwd)
    for _, entry in ipairs(entries) do
      local dirname = path.basename(entry)
      if not exclude_dirs[dirname] then
        collect_from_path(entry)
      end
    end

    local cwd_files = dir.getfiles(cwd)
    for _, file in ipairs(cwd_files) do
      if file:match('%.lua$') then
        add_file(normalize(path.normpath(file)))
      end
    end

    local lpath = options.lpath or package.path
    local path_resolver = PathResolver.new(lpath, cwd)
    path_resolver:set_known_files(all_files)

    local graph = DependencyGraph.new()
    graph:build(all_files, path_resolver, { verbose = verbose })

    if verbose then
      local stats = graph:stats()
      io.stdout:write(string.format('Dependency graph: %d files, %d edges\n',
        stats.files, stats.edges))
    end

    local affected = graph:get_affected_tests(changed_files, test_files)

    for _, file in ipairs(changed_files) do
      if test_files[file] then
        affected[file] = true
      end
    end

    local result = {}
    for file in pairs(affected) do
      result[#result + 1] = file
    end
    table.sort(result)

    if verbose then
      io.stdout:write(string.format('Found %d related test files:\n', #result))
      for _, f in ipairs(result) do
        io.stdout:write('  ' .. f .. '\n')
      end
    end

    return result
  end
end
