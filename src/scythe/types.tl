
local interface Types
    interface Vector3 is GVector
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

return Types
