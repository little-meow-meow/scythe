
local record bit
    record bit
        -- bit.tobit(x) --> y
        tobit: function(x: number|integer): integer
        -- bit.tohex(x [,n]) --> y
        tohex: function(...: number|integer): string
        -- bit.bnot(x) --> y
        bnot: function(x: number|integer): integer
        -- bit.bor(x1 [,x2...]) --> y
        bor: function(...: number|integer): integer
        -- bit.band(x1 [,x2...]) --> y
        band: function(...: number|integer): integer
        -- bit.bxor(x1 [,x2...]) --> y
        bxor: function(...: number|integer): integer
        -- bit.lshift(x, n) --> y
        lshift: function(x: number|integer, n: number|integer): integer
        -- bit.rshift(x, n) --> y
        rshift: function(x: number|integer, n: number|integer): integer
        -- bit.arshift(x, n) --> y
        arshift: function(x: number|integer, n: number|integer): integer
        -- bit.rol(x, n) --> y
        rol: function(x: number, n: number): integer
        -- bit.ror(x, n) --> y
        ror: function(x: number, n: number): integer
        -- bit.bswap(x) --> y
        bswap: function(x: number): integer
    end

    record bit32
        -- bit32.arshift (x, disp) --> z
        arshift: function(x: number, disp: number): integer
        -- bit32.band (...) --> z
        band: function(...: number): integer
        -- bit32.bnot (x) --> z
        bnot: function(x: number): integer
        -- bit32.bor (...) --> z
        bor: function(...: number): integer
        -- bit32.btest (...) --> true | false
        btest: function(...: number): boolean
        -- bit32.bxor (...) --> z
        bxor: function(...: number): integer
        -- bit32.extract (x, field [, width]) --> z
        extract: function(x: number, field: number, width?: number): integer
        -- bit32.replace (x, v, field [, width]) --> z
        replace: function(x: number, v: number, field: number, width?: number)
        -- bit32.lrotate (x, disp) --> z
        lrotate: function(x: number, disp: number): integer
        -- bit32.lshift (x, disp) --> z
        lshift: function(x: number, disp: number): integer
        -- bit32.rrotate (x, disp) --> z
        rrotate: function(x: number, disp: number): integer
        -- bit32.rshift (x, disp) --> z
        rshift: function(x: number, disp: number): integer
    end
end

return bit
