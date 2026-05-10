
local type BSPData = require("scythe.bsp_sh")

local record TraceInfo
    input: S_HullTrace
    output: S_TraceResult

    _brushes: {BSPData.Brush: boolean}
end

local vector_origin = Vector(0, 0, 0)
local function MakeTraceResult(startPos: GVector, endPos: GVector): S_TraceResult
    return {
        Entity = Entity(-1),
        Fraction = 1,
        FractionLeftSolid = 0,
        Hit = false,
        HitBox = 0,
        HitGroup = 0,
        HitNoDraw = false,
        HitNonWorld = false,
        HitNormal = vector_origin,
        HitPos = endPos,
        HitSky = false,
        HitTexture = "**empty**",
        HitWorld = false,
        MatType = nil,
        Normal = (endPos - startPos):GetNormalized(),
        PhysicsBone = 0,
        StartPos = startPos,
        SurfaceProps = 0,
        StartSolid = false,
        AllSolid = false,
        SurfaceFlags = 0,
        DispFlags = 0,
        Contents = 0,
        HitBoxBone = nil,
    }
end

function TraceInfo.new(trace: S_HullTrace): TraceInfo
    return setmetatable({
        input = trace,
        output = MakeTraceResult(trace.start, trace.endpos),
        _brushes = {},
    }, {__index = TraceInfo})
end

function TraceInfo:isRay(): boolean
    return self.input.mins == nil
end

function TraceInfo:isSwept(): boolean
    return self.input.endpos:DistToSqr(self.input.start) ~= 0
end

function TraceInfo:extents(): GVector
    return self.input.maxs
end

function TraceInfo:visitBrush(brush: BSPData.Brush): boolean
    if self._brushes[brush] then
        return false
    end

    self._brushes[brush] = true
    return true
end

-- function TraceInfo:clearBrushVisits()
--     self._brushes = {}
-- end

return TraceInfo
