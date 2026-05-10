(makeRequireCompat or function() end)()

local Floating = require("lib.floating_sh")

local macroexp shl(value: integer, bits: integer): integer
    return value * math.pow(2, bits)
end

local macroexp shl8(value: integer): integer
    return value * 0x100
end

local macroexp shl16(value: integer): integer
    return value * 0x10000
end

local macroexp shl24(value: integer): integer
    return value * 0x1000000
end

local MAX_SLICE = 8000
local function sliceString(str: string, count: integer, offset?: integer): string
    offset = offset or 0
    local chunks = {}
    local maxLength = math.min(count, #str)
    for i = 1, maxLength, MAX_SLICE do
        local sliceSize = math.min(maxLength - i + 1, MAX_SLICE)
        table.insert(chunks, str:sub(i + offset, i + offset + sliceSize - 1))
    end
    return table.concat(chunks)
end

local record ByteReader
    new: function(byteString: string): ByteReader

    _index: integer
    _buffer: string

    tell: function(self: ByteReader): integer = macroexp(self: ByteReader): integer
        return self._index
    end
    seek: function(self: ByteReader, position: integer)
    skip: function(self: ByteReader, count: integer)
    length: function(self: ByteReader): integer

    pop: function(self: ByteReader, count: integer): integer...

    read: function(self: ByteReader, length: integer): string

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

function ByteReader:length(): integer
    return #self._buffer
end

function ByteReader:pop(count: integer): integer...
    local values: {number}
    if count > MAX_SLICE then
        values = { string.byte( self._buffer, self._index + 1, self._index + count) }
        self._index = self._index + count
    else
        local slice = sliceString(self._buffer, count, self._index)
        values = { string.byte(slice, 1, #slice) }
        self._index = self._index + #slice
    end
    return unpack( values ) as integer
end

function ByteReader:read(length: integer): string
    local result = sliceString(self._buffer, length, self._index)
    self._index = self._index + #result
    return result
end

-- function ByteReader:readU8(): integer
function ByteReader:readU8(): integer
    return self:pop(1)
end

-- function ByteReader:readS8(): integer
function ByteReader:readS8(): integer
    return self:readS8()
end

function ByteReader:readU16(): integer
    local b1, b2 = self:pop(2)
    return shl8(b1) + b2
end

function ByteReader:readU16LE(): integer
    local b1, b2 = self:pop(2)
    return shl8(b2) + b1
end

-- function ByteReader:readS16(): integer

-- function ByteReader:readS16LE(): integer
function ByteReader:readS16LE(): integer
    return self:readS16LE()
end

function ByteReader:readU32(): integer
    local b1, b2, b3, b4 = self:pop(4)
    local value = shl24(b1)
    value = value + shl16(b2)
    value = value + shl8(b3)
    value = value + b4
    return value
end

function ByteReader:readU32LE(): integer
    local b1, b2, b3, b4 = self:pop(4)
    local value = shl24(b4)
    value = value + shl16(b3)
    value = value + shl8(b2)
    value = value + b1
    return value
end

-- function ByteReader:readS32(): integer

-- function ByteReader:readS32LE(): integer
function ByteReader:readS32LE(): integer
    return self:readS32LE()
end

-- function ByteReader:readSingle(): number

-- function ByteReader:readSingleLE(): number
function ByteReader:readSingleLE(): number
    return self:readSingleLE()
end

-- function ByteReader:readChars(length: integer): string

-- function ByteReader:readUtf8Chars(length: integer): string

function ByteReader:readString(): string
    local index = self:tell() + 1
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

    local size = index - self:tell() - 1
    return self:read(size)
end

-- local reader = ByteReader.new("\x41\x41\x41\x41\x9f\x00\x12\x34\x56\x78\x91\x23\x45\x67\x89\xab\xcd\xef")
-- print(reader:read(4))
-- print(reader:pop(4))

return ByteReader
