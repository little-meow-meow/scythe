--- Convert binary flag combinations into a comma-separated string of constants

local FlagsToString = {}

local function CollateEnum(keyPrefix: string, exclude: {string: boolean}): {string: number}
    local results: {string: number} = {}
    for key, value in pairs(_G as table) do
        if type(value) ~= "number" then
            goto _continue
        end

        if exclude[key as string] then
            goto _continue
        end

        if (key as string):sub(1, #keyPrefix) ~= keyPrefix then
            goto _continue
        end

        results[key as string] = value as number

        ::_continue::
    end
    return results
end

local function MapFlagsToStrings(valueFlags: number, map: {string: number}): string
    local flags: {string} = {}
    for key, value in pairs(map) do
        if bit.band(value, valueFlags) == value then
            table.insert(flags, key)
        end
    end
    return table.concat(flags, ", ")
end

local MapContents = CollateEnum("CONTENTS_", {
    ["CONTENTS_EMPTY"] = true,
})
function FlagsToString.contents(value: E_CONTENTS|E_MASK): string
    return MapFlagsToStrings(value as number, MapContents)
end

return FlagsToString
