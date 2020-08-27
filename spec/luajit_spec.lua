local isJit = (tostring(getmetatable):match('builtin') ~= nil)

local it = it
if not isJit then
  it = pending
end

describe("LuaJIT FFI patching:", function()

  local _, ffi = pcall(require, "ffi")

  it("ffi.cdef", function()
    local def =[[
      typedef struct foo { int a, b; } foo_t;  // Declare a struct and typedef.
      int dofoo(foo_t *f, int n);  /* Declare an external C function. */
    ]]

    ffi.cdef(def)
    assert.has.no.error(function()
      ffi.cdef(def)
    end)
  end)

  it("ffi.typeof", function()
    local ct = "struct { int top, max; }"

    ffi.typeof(ct)
    assert.has.no.error(function()
      ffi.typeof(ct)
    end)
  end)

  it("ffi.metatype", function()
    local name = "brinevector"
    local mt = {}
    ffi.cdef([[
      typedef struct {
        double x;
        double y;
      } ]] .. name .. [[;
    ]])

    ffi.metatype(name, mt)
    assert.has.no.error(function()
      ffi.metatype(name, mt)
    end)
  end)

end)