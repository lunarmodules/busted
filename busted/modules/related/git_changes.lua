local path = require 'pl.path'

local GitChanges = {}

-- Normalize paths to forward slashes for cross-platform consistency
local function normalize(p)
  return p:gsub('\\', '/')
end

local function default_run_command(cmd, cwd)
  local full_cmd
  if cwd then
    full_cmd = string.format('cd %q && %s 2>&1', cwd, cmd)
  else
    full_cmd = cmd .. ' 2>&1'
  end

  local handle = io.popen(full_cmd)
  if not handle then
    return nil, 'Failed to execute command'
  end

  local lines = {}
  local has_error = false
  for line in handle:lines() do
    if line:match('^fatal:') or line:match('^error:') then
      has_error = true
    end
    lines[#lines + 1] = line
  end

  local _, _, exit_code = handle:close()

  if has_error or (exit_code and exit_code ~= 0) then
    local err_msg = table.concat(lines, '\n')
    return nil, err_msg ~= '' and err_msg or 'Git command failed'
  end

  return lines
end

-- Injectable for testing
GitChanges._run_command = default_run_command

local function run_git_command(cmd, cwd)
  return GitChanges._run_command(cmd, cwd)
end

function GitChanges.is_git_repo(cwd)
  local lines = run_git_command('git rev-parse --is-inside-work-tree', cwd)
  return lines and #lines > 0 and lines[1] == 'true'
end

function GitChanges.get_git_root(cwd)
  local lines = run_git_command('git rev-parse --show-toplevel', cwd)
  return lines and lines[1]
end

function GitChanges.get_changed_files(cwd)
  if not GitChanges.is_git_repo(cwd) then
    return nil, 'Not a git repository'
  end

  local files = {}

  local unstaged = run_git_command('git diff --name-only', cwd)
  if unstaged then
    for _, file in ipairs(unstaged) do
      files[normalize(path.normpath(path.join(cwd, file)))] = true
    end
  end

  local staged = run_git_command('git diff --cached --name-only', cwd)
  if staged then
    for _, file in ipairs(staged) do
      files[normalize(path.normpath(path.join(cwd, file)))] = true
    end
  end

  local untracked = run_git_command('git ls-files --others --exclude-standard', cwd)
  if untracked then
    for _, file in ipairs(untracked) do
      files[normalize(path.normpath(path.join(cwd, file)))] = true
    end
  end

  local result = {}
  for file in pairs(files) do
    result[#result + 1] = file
  end
  table.sort(result)

  return result
end

function GitChanges.get_changes_since(cwd, base_ref)
  if not GitChanges.is_git_repo(cwd) then
    return nil, 'Not a git repository'
  end

  local files = {}

  local cmd = string.format('git diff --name-only %q', base_ref)
  local diff = run_git_command(cmd, cwd)
  if diff then
    for _, file in ipairs(diff) do
      files[normalize(path.normpath(path.join(cwd, file)))] = true
    end
  end

  local uncommitted = GitChanges.get_changed_files(cwd)
  if uncommitted then
    for _, file in ipairs(uncommitted) do
      files[file] = true
    end
  end

  local result = {}
  for file in pairs(files) do
    result[#result + 1] = file
  end
  table.sort(result)

  return result
end

function GitChanges.filter_lua_files(files)
  local result = {}
  for _, file in ipairs(files) do
    if file:match('%.lua$') then
      result[#result + 1] = file
    end
  end
  return result
end

return GitChanges
