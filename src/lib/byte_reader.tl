
local Floating = require("lib.floating")

local macroexp shl(value: integer, bits: integer): integer
    return value * math.pow(2, bits)
end

local record ByteReader
    new: function(byteString: string): ByteReader

    _index: integer
    _buffer: string

    tell: function(self: ByteReader): integer =
        macroexp(self: ByteReader): integer
            return self._index
        end
    seek: function(self: ByteReader, position: integer)
    skip: function(self: ByteReader, count: integer)

    pop: function(self: ByteReader, count: integer): integer...

    readU8: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return self:pop(1)
    end
    readS8: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return ((self:readU8() + 0x80) % 0x100) - 0x80
    end

    readU16: function(self: ByteReader): integer
    readU16LE: function(self: ByteReader): integer
    readS16: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return ((self:readU16() + 0x8000) % 0x10000) - 0x8000
    end
    readS16LE: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return ((self:readU16LE() + 0x8000) % 0x10000) - 0x8000
    end

    readU32: function(self: ByteReader): integer
    readU32LE: function(self: ByteReader): integer
    readS32: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return ((self:readU32() + 0x80000000) % 0x100000000) - 0x80000000
    end
    readS32LE: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return ((self:readU32LE() + 0x80000000) % 0x100000000) - 0x80000000
    end

    readSingle: function(self: ByteReader): number = macroexp(self: ByteReader): number
        return Floating.toSingle(self:readU32())
    end
    readSingleLE: function(self: ByteReader): number = macroexp(self: ByteReader): number
        return Floating.toSingle(self:readU32LE())
    end

    readChars: function(self: ByteReader, length: integer): string = macroexp(self: ByteReader, length: integer): string
        return string.char(self:pop(length))
    end
    readUtf8Chars: function(self: ByteReader, length: integer): string = macroexp(self: ByteReader, length: integer): string
        return utf8.char(self:pop(length))
    end
    readString: function(self: ByteReader): string
end

function ByteReader.new(byteString: string): ByteReader
    return setmetatable({
        _buffer = byteString,
        _index = 0
    }, { __index = ByteReader })
end

-- function ByteReader:tell(): integer

function ByteReader:seek(position: integer)
    self._index = position
end

function ByteReader:skip(count: integer)
    self._index = self._index + count
end

function ByteReader:pop(count: integer): integer...
    local values = { string.byte( self._buffer, self._index + 1, self._index + count) }
    self._index = self._index + count
    return unpack( values ) as integer
end

-- function ByteReader:readU8(): integer

-- function ByteReader:readS8(): integer

function ByteReader:readU16(): integer
    local b1, b2 = self:pop(2)
    return shl(b1, 8) + b2
end

function ByteReader:readU16LE(): integer
    local b1, b2 = self:pop(2)
    return shl(b2, 8) + b1
end

-- function ByteReader:readS16(): integer

-- function ByteReader:readS16LE(): integer

function ByteReader:readU32(): integer
    local b1, b2, b3, b4 = self:pop(4)
    local value = shl(b1, 24)
    value = value + shl(b2, 16)
    value = value + shl(b3, 8)
    value = value + b4
    return value
end

function ByteReader:readU32LE(): integer
    local b1, b2, b3, b4 = self:pop(4)
    local value = shl(b4, 24)
    value = value + shl(b3, 16)
    value = value + shl(b2, 8)
    value = value + b1
    return value
end

-- function ByteReader:readS32(): integer

-- function ByteReader:readS32LE(): integer

-- function ByteReader:readSingle(): number

-- function ByteReader:readSingleLE(): number

-- function ByteReader:readChars(length: integer): string

-- function ByteReader:readUtf8Chars(length: integer): string

function ByteReader:readString(): string
    local index = self:tell()
    local bufferLength = #self._buffer
    repeat
        local char = string.byte(self._buffer, index, index)
        if char == 0 then
            break
        end
        index = index + 1
    until index > bufferLength

    if index > bufferLength then
        error("read null-terminated string to end of file")
    end

    local size = index - self:tell() + 1
    return self:readChars(size)
end

return ByteReader
