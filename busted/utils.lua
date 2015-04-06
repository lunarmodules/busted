local path = require 'pl.path'

math.randomseed(os.time())

return {
  split = require 'pl.utils'.split,

  shuffle = function(t, seed)
    if seed then math.randomseed(seed) end
    local n = #t
    while n >= 2 do
      local k = math.random(n)
      t[n], t[k] = t[k], t[n]
      n = n - 1
    end
    return t
  end
}
