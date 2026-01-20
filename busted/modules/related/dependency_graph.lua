local RequireParser = require 'busted.modules.related.require_parser'

local DependencyGraph = {}
DependencyGraph.__index = DependencyGraph

function DependencyGraph.new()
  local self = setmetatable({}, DependencyGraph)
  self.forward = {}
  self.reverse = {}
  self.module_to_path = {}
  return self
end

function DependencyGraph:build(files, path_resolver)
  for _, filepath in ipairs(files) do
    local parsed = RequireParser.parse_file(filepath)
    if parsed then
      self.forward[filepath] = {}

      for _, module_name in ipairs(parsed.requires) do
        local resolved = self.module_to_path[module_name]
        if not resolved then
          resolved = path_resolver:resolve(module_name)
          self.module_to_path[module_name] = resolved
        end

        if resolved then
          self.forward[filepath][#self.forward[filepath] + 1] = resolved
        end
      end

      for _, file_path in ipairs(parsed.loadfiles) do
        local resolved = path_resolver:resolve_file(file_path)
        if resolved then
          self.forward[filepath][#self.forward[filepath] + 1] = resolved
        end
      end
    end
  end

  for filepath, deps in pairs(self.forward) do
    for _, dep in ipairs(deps) do
      if not self.reverse[dep] then
        self.reverse[dep] = {}
      end
      self.reverse[dep][#self.reverse[dep] + 1] = filepath
    end
  end
end

function DependencyGraph:get_direct_dependents(filepath)
  return self.reverse[filepath] or {}
end

function DependencyGraph:get_direct_dependencies(filepath)
  return self.forward[filepath] or {}
end

function DependencyGraph:get_affected_files(changed_files)
  local affected = {}
  local visited = {}
  local queue = {}

  for _, filepath in ipairs(changed_files) do
    queue[#queue + 1] = filepath
  end

  local queue_start = 1
  while queue_start <= #queue do
    local current = queue[queue_start]
    queue_start = queue_start + 1

    if not visited[current] then
      visited[current] = true
      affected[current] = true

      local dependents = self.reverse[current] or {}
      for _, dependent in ipairs(dependents) do
        if not visited[dependent] then
          queue[#queue + 1] = dependent
        end
      end
    end
  end

  return affected
end

function DependencyGraph:get_affected_tests(changed_files, test_files)
  local affected = self:get_affected_files(changed_files)
  local affected_tests = {}

  for filepath in pairs(affected) do
    if test_files[filepath] then
      affected_tests[filepath] = true
    end
  end

  return affected_tests
end

function DependencyGraph:stats()
  local num_files = 0
  local num_edges = 0

  for _, deps in pairs(self.forward) do
    num_files = num_files + 1
    num_edges = num_edges + #deps
  end

  return {
    files = num_files,
    edges = num_edges,
  }
end

function DependencyGraph:dump()
  print("=== Forward edges (file -> dependencies) ===")
  for filepath, deps in pairs(self.forward) do
    print(filepath)
    for _, dep in ipairs(deps) do
      print("  -> " .. dep)
    end
  end

  print("\n=== Reverse edges (file -> dependents) ===")
  for filepath, deps in pairs(self.reverse) do
    print(filepath)
    for _, dep in ipairs(deps) do
      print("  <- " .. dep)
    end
  end
end

return DependencyGraph
