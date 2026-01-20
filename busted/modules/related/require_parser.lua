local RequireParser = {}

local MAX_FILE_SIZE = 1024 * 1024

local require_patterns = {
  'require%s*%(%s*["\']([^"\']+)["\']%s*%)',
  'require%s+["\']([^"\']+)["\']',
}

local load_patterns = {
  'loadfile%s*%(%s*["\']([^"\']+)["\']%s*%)',
  'dofile%s*%(%s*["\']([^"\']+)["\']%s*%)',
}

local function update_multiline_string_state(line, in_string, string_delim)
  if in_string then
    local close_pattern = '%]' .. string_delim .. '%]'
    if line:find(close_pattern) then
      return false, nil
    end
    return true, string_delim
  else
    local open_start, open_end, equals = line:find('%[(%=*)%[')
    if open_start then
      local close_pattern = '%]' .. equals .. '%]'
      if not line:find(close_pattern, open_end + 1) then
        return true, equals
      end
    end
    return false, nil
  end
end

local function update_multiline_comment_state(line, in_comment, comment_delim)
  if in_comment then
    local close_pattern = '%]' .. comment_delim .. '%]'
    if line:find(close_pattern) then
      return false, nil
    end
    return true, comment_delim
  else
    local open_start, open_end, equals = line:find('%-%-%[(%=*)%[')
    if open_start then
      local close_pattern = '%]' .. equals .. '%]'
      if not line:find(close_pattern, open_end + 1) then
        return true, equals
      end
    end
    return false, nil
  end
end

local function strip_single_line_comment(line)
  local pos = 1
  while true do
    local dash_start = line:find('%-%-', pos)
    if not dash_start then
      return line
    end
    if line:sub(dash_start, dash_start + 3):match('%-%-%[%=*%[') then
      pos = dash_start + 2
    else
      return line:sub(1, dash_start - 1)
    end
  end
end

local function get_file_size(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return nil
  end
  local size = file:seek('end')
  file:close()
  return size
end

local function extract_requires_from_line(line, patterns)
  local requires = {}
  for _, pattern in ipairs(patterns) do
    for module_name in line:gmatch(pattern) do
      requires[module_name] = true
    end
  end
  return requires
end

function RequireParser.parse_file(filepath)
  local size = get_file_size(filepath)
  if size and size > MAX_FILE_SIZE then
    return {
      requires = {},
      loadfiles = {},
      skipped = true,
      reason = 'File exceeds size limit (' .. size .. ' bytes > ' .. MAX_FILE_SIZE .. ' bytes)',
    }
  end

  local requires = {}
  local loadfiles = {}

  local file = io.open(filepath, 'r')
  if not file then
    return nil, 'Cannot open file: ' .. filepath
  end

  local in_multiline_string = false
  local string_delim = nil
  local in_multiline_comment = false
  local comment_delim = nil

  for line in file:lines() do
    in_multiline_comment, comment_delim = update_multiline_comment_state(
      line, in_multiline_comment, comment_delim
    )

    if not in_multiline_comment then
      in_multiline_string, string_delim = update_multiline_string_state(
        line, in_multiline_string, string_delim
      )

      if not in_multiline_string then
        local processed = strip_single_line_comment(line)

        local req = extract_requires_from_line(processed, require_patterns)
        for module_name in pairs(req) do
          requires[module_name] = true
        end

        local load = extract_requires_from_line(processed, load_patterns)
        for module_name in pairs(load) do
          loadfiles[module_name] = true
        end
      end
    end
  end

  file:close()

  local require_list = {}
  for module_name in pairs(requires) do
    require_list[#require_list + 1] = module_name
  end
  table.sort(require_list)

  local loadfile_list = {}
  for module_name in pairs(loadfiles) do
    loadfile_list[#loadfile_list + 1] = module_name
  end
  table.sort(loadfile_list)

  return {
    requires = require_list,
    loadfiles = loadfile_list,
  }
end

function RequireParser.parse_files(filepaths)
  local results = {}
  for _, filepath in ipairs(filepaths) do
    local parsed = RequireParser.parse_file(filepath)
    if parsed then
      results[filepath] = parsed
    end
  end
  return results
end

return RequireParser
