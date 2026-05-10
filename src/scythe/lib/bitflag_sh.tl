(makeRequireCompat or function() end)()

local _bit = require("scythe.lib.bit_sh")

local band = _bit.bit.band
local bor = _bit.bit.bor
local bnot = _bit.bit.bnot

local record Bitflag<T>
    new: function(): Bitflag<T>

    _flags: number

    test: function(self, flags: integer|number): boolean
    set: function(self, flags: integer|number)
    unset: function(self, flags: integer|number)
end

function Bitflag.new(): Bitflag<T>
    local self: Bitflag<T> = setmetatable({}, { __index = Bitflag })
    self._flags = 0
    return self
end

function Bitflag:test(flags: integer|number): boolean
    return band(self._flags, flags) == flags
end

function Bitflag:set(flags: integer|number)
    self._flags = bor(self._flags, flags)
end

function Bitflag:unset(flags: integer|number)
    self._flags = band(self._flags, bnot(flags))
end

return Bitflag
