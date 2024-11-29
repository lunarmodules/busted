-- supporting testfile; belongs to 'cl_output_json_spec.lua'

describe("spec with non string attributes", function()
  non_string_spec('throws an error when encoded into json')
end)
