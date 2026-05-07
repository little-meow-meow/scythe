(makeRequireCompat or function() end)()

local type BSPData = require("scythe.bsp")

local record BSPPhys
    bspData: BSPData
end

function BSPPhys.new(bspData: BSPData): BSPPhys
    local phys: BSPPhys = setmetatable({}, {__index = BSPPhys})
    phys.bspData = bspData
    return phys
end

function BSPPhys:recurseTree(nodeIndex: integer, p1: GVector, p2: GVector, trace: S_Trace, result: S_TraceResult): boolean
    if nodeIndex < 0 then
        local leaf = self.bspData.leaves[-1 - nodeIndex]
        if bit.band(leaf.contents, CONTENTS_SOLID) == CONTENTS_SOLID then
            result.Hit = true
            result.HitWorld = true
            result.HitPos = p1
            result.Entity = Entity(0)
            result.Contents = leaf.contents
            return true
        else
            return false
        end
    end

    local node = self.bspData.nodes[nodeIndex]
    local plane = node.plane
    local t1 = plane.normal:Dot(p1) - plane.distance
    local t2 = plane.normal:Dot(p2) - plane.distance

    -- Handle cases where the line segment lies entirely within a single child.
    if t1 >= 0 and t2 >= 0 then
        return self:recurseTree(node.childIndices[1], p1, p2, trace, result)
    end
    if t1 < 0 and t2 < 0 then
        return self:recurseTree(node.childIndices[2], p1, p2, trace, result)
    end

    -- Find the point of intersection with the split plane
    local fraction = t1 / (t1 - t2)
    local midpoint = Vector(0, 0, 0)
    midpoint.x = p1.x + fraction * (p2.x - p1.x)
    midpoint.y = p1.y + fraction * (p2.y - p1.y)
    midpoint.z = p1.z + fraction * (p2.z - p1.z)

    local side = t1 >= 0 and 1 or 2

    -- Trace through child nodes in order.
    result.HitNormal = plane.normal
    if self:recurseTree(node.childIndices[side], p1, midpoint, trace, result) then
        return true
    end

    return self:recurseTree(node.childIndices[3 - side], midpoint, p2, trace, result)
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
        HitTexture = "** empty **",
        HitWorld = false,
        MatType = nil,
        Normal = vector_origin,
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

function BSPPhys:traceLine(trace: S_Trace): S_TraceResult
    local result = MakeTraceResult(trace.start, trace.endpos)

    if self:recurseTree(0, trace.start, trace.endpos, trace, result) then
        result.Fraction = math.sqrt((result.HitPos - trace.start):LengthSqr() / (trace.endpos - trace.start):LengthSqr())
        result.Normal = (result.HitPos - result.StartPos):GetNormalized()
    end

    return result
end

function BSPPhys:traceHull(trace: S_HullTrace): S_TraceResult
    local result = MakeTraceResult(trace.start, trace.endpos)

    -- TODO: trace ray/box sweep against all brushes in this leaf

    -- TODO: Hull tracing against displacements; need to query displacements by leaf
end

return BSPPhys
