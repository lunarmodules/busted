-- fork of the lua-term's colors.lua, check it out: https://github.com/hoelzro/lua-term/blob/master/term/colors.lua

local pairs = pairs
local tostring = tostring
local setmetatable = setmetatable
local schar = string.char

local colors = {}

local colormt = {}

function colormt:__tostring()
    return self.value
end

function colormt:__concat(other)
    return tostring(self) .. tostring(other)
end

function colormt:__call(s)
    return self .. s .. colors.reset
end

local function makecolor(value)
    return setmetatable({ value = schar(27) .. '[' .. tostring(value) .. 'm' }, colormt)
end

local colorvalues = {
    -- attributes
    reset      = 0,
    clear      = 0,
    default    = 0,
    bright     = 1,
    dim        = 2,
    underscore = 4,
    blink      = 5,
    reverse    = 7,
    hidden     = 8,

    -- foreground
    black   = 30,
    red     = 31,
    green   = 32,
    yellow  = 33,
    blue    = 34,
    magenta = 35,
    cyan    = 36,
    white   = 37,

    -- background
    onblack   = 40,
    onred     = 41,
    ongreen   = 42,
    onyellow  = 43,
    onblue    = 44,
    onmagenta = 45,
    oncyan    = 46,
    onwhite   = 47,
}

for c, v in pairs(colorvalues) do
    colors[c] = makecolor(v)
end

return colors
