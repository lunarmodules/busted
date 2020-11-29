local pl_path = require 'pl.path'

return {
  -- returns an absolute path to where the current test file is located.
  -- @param sub_path [optional] a relative path to a file to be appended
  fixture_path = function(sub_path)
    local info = debug.getinfo(2)
    path = info.source
    if path:sub(1,1) == "@" then
      path = path:sub(2, -1)
    end
    path = pl_path.abspath(path) -- based on PWD
    path = pl_path.splitpath(path) -- drop filename, keep path only
    path = pl_path.join(path, sub_path)
    return pl_path.normpath(path, sub_path)
  end,
}
