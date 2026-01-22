-- State module for watch mode
-- Handles module cache invalidation between test runs

local path = require 'pl.path'

local State = {}
State.__index = State

function State.new(options)
  local self = setmetatable({}, State)
  self.project_paths = options.project_paths or { '.' }
  self.tracked_modules = {}
  return self
end

-- Normalize a path for comparison
local function normalize_path(filepath)
  return path.normpath(path.abspath(filepath))
end

-- Check if a module path is within the project
function State:is_project_module(module_path)
  if not module_path then
    return false
  end

  local normalized = normalize_path(module_path)

  for _, project_path in ipairs(self.project_paths) do
    local project_normalized = normalize_path(project_path)
    if normalized:sub(1, #project_normalized) == project_normalized then
      return true
    end
  end

  return false
end

-- Track which modules are loaded from the project
function State:snapshot()
  self.tracked_modules = {}

  for name, _ in pairs(package.loaded) do
    local info = self:get_module_info(name)
    if info and self:is_project_module(info.path) then
      self.tracked_modules[name] = info.path
    end
  end

  return self.tracked_modules
end

-- Get module info (path) from package.loaded
function State:get_module_info(name)
  -- Try to find the source file for a loaded module
  local searchers = package.searchers or package.loaders
  if not searchers then
    return nil
  end

  for _, searcher in ipairs(searchers) do
    local result = searcher(name)
    if type(result) == 'function' then
      -- Get the path from debug info
      local info = debug.getinfo(result, 'S')
      if info and info.source and info.source:sub(1, 1) == '@' then
        return { path = info.source:sub(2) }
      end
    end
  end

  return nil
end

-- Invalidate modules that were loaded from changed files
function State:invalidate(changed_files)
  local invalidated = {}

  -- Normalize changed file paths
  local changed_set = {}
  for _, filepath in ipairs(changed_files) do
    changed_set[normalize_path(filepath)] = true
  end

  -- Find all modules to invalidate
  for name, module_path in pairs(self.tracked_modules) do
    local normalized = normalize_path(module_path)
    if changed_set[normalized] then
      table.insert(invalidated, name)
    end
  end

  -- Clear from package.loaded
  for _, name in ipairs(invalidated) do
    package.loaded[name] = nil
    self.tracked_modules[name] = nil
  end

  return invalidated
end

-- Clear all project modules from package.loaded
function State:clear_all()
  local cleared = {}

  for name, _ in pairs(self.tracked_modules) do
    package.loaded[name] = nil
    table.insert(cleared, name)
  end

  self.tracked_modules = {}
  return cleared
end

-- Get list of currently tracked modules
function State:get_tracked()
  local modules = {}
  for name, module_path in pairs(self.tracked_modules) do
    table.insert(modules, { name = name, path = module_path })
  end
  return modules
end

return State
