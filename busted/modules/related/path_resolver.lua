local path = require 'pl.path'

local PathResolver = {}
PathResolver.__index = PathResolver

-- Normalize paths to forward slashes for cross-platform consistency
local function normalize(p)
  return p:gsub('\\', '/')
end

function PathResolver.new(package_path, cwd)
  local self = setmetatable({}, PathResolver)
  self.templates = {}
  self.cwd = cwd or './'
  self.known_files = {}

  package_path = package_path or package.path
  for template in package_path:gmatch('[^;]+') do
    local prefix, suffix = template:match('^(.-)%?(.*)$')
    if prefix then
      self.templates[#self.templates + 1] = {
        prefix = prefix,
        suffix = suffix,
      }
    end
  end

  return self
end

function PathResolver:set_known_files(files)
  self.known_files = files or {}
end

function PathResolver:resolve(module_name)
  -- Always use forward slashes (all paths are normalized)
  local path_name = module_name:gsub('%.', '/')

  for _, template in ipairs(self.templates) do
    local candidate = template.prefix .. path_name .. template.suffix
    candidate = path.normpath(path.join(self.cwd, candidate))

    if path.isfile(candidate) then
      return normalize(candidate)
    end
  end

  for _, template in ipairs(self.templates) do
    if template.suffix == '.lua' then
      local candidate = template.prefix .. path_name .. '/init' .. template.suffix
      candidate = path.normpath(path.join(self.cwd, candidate))

      if path.isfile(candidate) then
        return normalize(candidate)
      end
    end
  end

  -- Fallback: match against known files (all normalized to forward slashes)
  if #self.known_files > 0 then
    local suffix = '/' .. path_name .. '.lua'
    local init_suffix = '/' .. path_name .. '/init.lua'

    for _, filepath in ipairs(self.known_files) do
      if filepath:sub(-#suffix) == suffix then
        return filepath
      end
      if filepath:sub(-#init_suffix) == init_suffix then
        return filepath
      end
      if filepath == path_name .. '.lua' then
        return filepath
      end
    end
  end

  return nil
end

function PathResolver:resolve_file(file_path)
  if path.isabs(file_path) then
    return normalize(path.normpath(file_path))
  end

  local candidate = path.normpath(path.join(self.cwd, file_path))
  if path.isfile(candidate) then
    return normalize(candidate)
  end

  return nil
end

function PathResolver:get_templates()
  return self.templates
end

return PathResolver
