(makeRequireCompat or function() end)()

local Bit = require("scythe.lib.bit_sh")
local bit = Bit.bit

local SINGLE_MANTISSA_BITS = 23
local SINGLE_MANTISSA_RATIO = 1 / bit.lshift( 1, SINGLE_MANTISSA_BITS )

local SINGLE_EXPONENT_BITS = 8
local SINGLE_EXPONENT_MAXIMUM = bit.lshift( 1, SINGLE_EXPONENT_BITS ) - 1
local SINGLE_EXPONENT_BIAS = bit.lshift( 1, SINGLE_EXPONENT_BITS - 1 ) - 1

local record Floating
end

function Floating.toSingle( int: integer ): number
    local sign = math.floor( int / 0x80000000 ) -- >> 31
    local mantissa: number = bit.band( int, 0x7FFFFF ) -- low 23 bits
    local exponent = bit.band( math.floor( int / 0x800000 ), 0xFF )  -- (>> 23) & 0xFF

    if exponent == SINGLE_EXPONENT_MAXIMUM then
		if mantissa == 0 then
			return sign and -math.huge or math.huge  -- inf
		else
			return 0 / 0  -- nan
		end
	elseif exponent == 0 then
		exponent = 1 - SINGLE_EXPONENT_BIAS
		mantissa = mantissa * SINGLE_MANTISSA_RATIO
	else
		exponent = exponent - SINGLE_EXPONENT_BIAS
		mantissa = 1 + mantissa * SINGLE_MANTISSA_RATIO
	end

	local value = math.ldexp( mantissa, exponent as integer )
	return sign == 1 and value * -1 or value
end

-- function Floating.fromSingle(single: number): integer
--     local mantissa, exponent = math.frexp(math.abs(single))

--     if exponent == SINGLE_EXPONENT_MAXIMUM then
--         if mantissa == 0 / 0 then
--             mantissa = 1
--         end
--     elseif exponent == 1 - SINGLE_EXPONENT_BIAS then
--         exponent = 0
--         mantissa = mantissa / SINGLE_MANTISSA_RATIO
--     else
--         exponent = exponent + SINGLE_EXPONENT_BIAS
--         mantissa = (mantissa * 2 - 1) * math.pow(2, SINGLE_MANTISSA_BITS)
--     end

--     local value: integer = 0
--     if single < 0 then
--         value = math.pow(2, 31) as integer -- 1 << 31
--     end

--     value = value + bit.lshift(exponent, SINGLE_MANTISSA_BITS)
--     value = value + bit.band(mantissa, 0x7FFFFF)
--     return value
-- end

-- print(Floating.fromSingle(4.5))
-- print(Floating.fromSingle(0.265625))

-- --local DOUBLE_MANTISSA_BITS = 52
-- local DOUBLE_MANTISSA_RATIO = 2.220446049E-16 -- 1 / (1 << 52)

-- local DOUBLE_EXPONENT_BITS = 11
-- local DOUBLE_EXPONENT_MAXIMUM = bit.lshift( 1, DOUBLE_EXPONENT_BITS ) - 1
-- local DOUBLE_EXPONENT_BIAS = bit.lshift( 1, DOUBLE_EXPONENT_BITS - 1 ) - 1

-- function Float.toDouble( int: number ): number
--     local sign = math.floor( int / 0x8000000000000000 ) -- >> 63
--     local mantissa: number = bit.band( int, 0x1FFFFFFFFFFFFF ) -- low 52 bits
--     local exponent = bit.band( math.floor( int / 0x20000000000000 ), DOUBLE_EXPONENT_MAXIMUM )  -- (>> 52) & ((1 << 1) - 1)

--     if exponent == DOUBLE_EXPONENT_MAXIMUM then
-- 		if mantissa == 0 then
-- 			return sign and -math.huge or math.huge  -- inf
-- 		else
-- 			return 0 / 0  -- nan
-- 		end
-- 	elseif exponent == 0 then
-- 		exponent = 1 - DOUBLE_EXPONENT_BIAS
-- 		mantissa = mantissa * DOUBLE_MANTISSA_RATIO
-- 	else
-- 		exponent = exponent - DOUBLE_EXPONENT_BIAS
-- 		mantissa = 1 + mantissa * DOUBLE_MANTISSA_RATIO
-- 	end

-- 	local value = math.ldexp( mantissa, exponent as integer )
-- 	return sign == 1 and value * -1 or value
-- end

return Floating
