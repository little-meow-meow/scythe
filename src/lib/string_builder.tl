(makeRequireCompat or function() end)()

local record StringBuilder
end

function StringBuilder.new(): StringBuilder
    return setmetatable({}, {__index=StringBuilder})
end

function StringBuilder:add(str: string): StringBuilder
    table.insert(self as table, str)
    return self
end

function StringBuilder:build(): string
    return table.concat(self as {string})
end

return StringBuilder
