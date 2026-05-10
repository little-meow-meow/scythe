
local record Types
    record Vector3
        x: number
        y: number
        z: number

        -- Dot: function(self: Vector3, other: Vector3): Vector3
    end

    interface Vector4
        w: number
        x: number
        y: number
        z: number
    end

    interface ColorRGBExp32
        r: number
        g: number
        b: number
        exponent: number
    end

    interface ColorRGBA
        r: number
        g: number
        b: number
        a: number
    end
end

function Types.Vector3.new(x: number, y: number, z: number): Types.Vector3
    return setmetatable({
        x = x,
        y = y,
        z = z,
    }, {__index = Types.Vector3})
end

function Types.Vector3:dot(other: Types.Vector3): number
    return (self.x * other.x) + (self.y * other.y) + (self.z * other.z)
end

function Types.Vector3:cross(other: Types.Vector3): Types.Vector3
    local x = (self.y * other.z) - (self.z * other.y)
    local y = (self.z * other.x) - (self.x * other.z)
    local z = (self.x * other.y) - (self.y * other.x)
    return Types.Vector3.new(x, y, z)
end

function Types.Vector3:distToSqr(other: Types.Vector3): number
    return math.pow(self.x - other.x, 2) + math.pow(self.y - other.y, 2) + math.pow(self.z - other.z, 2)
end

function Types.Vector3:normalize()
    local max = math.max(self.x, self.y, self.z)
    self.x = self.x / max
    self.y = self.y / max
    self.z = self.z / max
end

function Types.Vector3:mul(value: number)
    self.x = self.x * value
    self.y = self.y * value
    self.z = self.z * value
end

return Types
