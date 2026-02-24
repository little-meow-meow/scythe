(makeRequireCompat or function() end)()

local Floating = require("lib.floating")

local macroexp shl(value: integer, bits: integer): integer
    return value * math.pow(2, bits)
end

local macroexp shr(value: integer, bits: integer): integer
    return math.floor(value / math.pow(2, bits))
end

local macroexp low(value: integer, bits: integer): integer
    return value % math.pow(2, bits)
end

local function hexDump(str: string): string
    local chunks = {}
    for byte = 1, #str, 16 do
        local slice = str:sub(byte, byte + 15)
        slice:gsub(".", function(char: string)
            table.insert(chunks, string.format("%02x", string.byte(char)))
        end)
    end
    return table.concat(chunks)
end

local record ByteWriter
    _buffer: {string}

    write: function(self: ByteWriter, chunk: string) = macroexp(self: ByteWriter, chunk: string)
        return table.insert(self._buffer, chunk)
    end

    write8: function(self: ByteWriter, value: integer) = macroexp(self: ByteWriter, value: integer)
        return self:write(string.char(value % 0x100))
    end

    writeString: function(self: ByteWriter, str: string) = macroexp(self: ByteWriter, str: string)
        return self:write(str .. "\x00")
    end
end

function ByteWriter.new(): ByteWriter
    return setmetatable({
        _buffer = {},
    }, {__index = ByteWriter})
end

function ByteWriter:build(): string
    return table.concat(self._buffer)
end

function ByteWriter:hex(): string
    return hexDump(self:build())
end

-- function ByteWriter:write8(value: integer)

function ByteWriter:write16(value: integer)
    self:write(string.char(shr(value, 8), low(value, 8)))
end

function ByteWriter:write16LE(value: integer)
    self:write(string.char(shr(value, 8), low(value, 8)))
end

function ByteWriter:write32(value: integer)
    self:write(
        string.char(
            low(shr(value, 24), 8),
            low(shr(value, 16), 8),
            low(shr(value, 8), 8),
            low(value, 8)
        )
    )
end

function ByteWriter:write32LE(value: integer)
    self:write(
        string.char(
            low(value, 8),
            low(shr(value, 8), 8),
            low(shr(value, 16), 8),
            low(shr(value, 24), 8)
        )
    )
end

-- function ByteWriter:writeString(value: string)

return ByteWriter
