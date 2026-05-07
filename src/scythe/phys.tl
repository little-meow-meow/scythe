(makeRequireCompat or function() end)()

local type BSPData = require("scythe.bsp")
local TraceInfo = require("scythe.trace")

local DIST_EPSILON = 0.03125

-- local interface Box
--     mins: {number}
--     maxs: {number}
--     surfaceIndices: {integer}
-- end

local record BSPPhys
    bspData: BSPData
end

function BSPPhys.new(bspData: BSPData): BSPPhys
    local phys: BSPPhys = setmetatable({}, {__index = BSPPhys})
    phys.bspData = bspData
    return phys
end

function BSPPhys:recurseTree(nodeIndex: integer, p1: GVector, p2: GVector, trace: S_HullTrace, result: S_TraceResult): boolean
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

-- function BSPPhys:traceLine(input: S_HullTrace): S_TraceResult
--     local trace = TraceInfo.new(input)

--     if self:recurseTree(0, input.start, input.endpos, input, trace.output) then
--         trace.output.Fraction = math.sqrt((trace.output.HitPos - input.start):LengthSqr() / (input.endpos - input.start):LengthSqr())
--         trace.output.Normal = (trace.output.HitPos - trace.output.StartPos):GetNormalized()
--     end

--     return trace.output
-- end

-- function BSPPhys:IntersectRayWithBoxBrush(traceInfo: TraceInfo, brush: BSPData.Brush)
-- end

local NUM_SIDES_BOX = 6
local NEVER_UPDATED = -99999
function BSPPhys:CM_ClipBoxToBrush(traceInfo: TraceInfo, brush: BSPData.Brush)
    -- if brush.sideCount == NUM_SIDES_BOX then
    --     -- TODO: IntersectRayWithBoxBrush
    --     return
    -- end

    if brush.sideCount <= 0 then
        return
    end

    local p1 = traceInfo.input.start
    local p2 = traceInfo.input.endpos
    local brushContents = brush.contents

    local enterFraction: number = NEVER_UPDATED
    local leaveFraction: number = 1

    local getOut = false
    local startOut = false
    local leadSide: BSPData.BrushSide = nil

    local distance: number = nil

    for _, brushSide in ipairs(brush.sides) do
        local plane = brushSide.plane

        if not traceInfo:isRay() then
            -- "general box case"
            -- "push the plane out apropriately for mins/maxs"
            distance = math.abs(plane.normal:Dot(traceInfo:extents()))
            distance = plane.distance + distance
        else
            -- "special point case"
            distance = plane.distance
            -- "don't trace rays against bevel planes"
            if brushSide.bevel then
                goto _continue
            end
        end

        local d1 = p1:Dot(plane.normal) - distance
        local d2 = p2:Dot(plane.normal) - distance

        -- "if completely in front of face, no intersection"
        if (d1 > 0) then
            startOut = true

            -- "d1 > 0.f && d2 > 0.f"
            if d2 > 0 then
                return
            end
        else
            -- "d1 <= 0.f && d2 <= 0.f"
            if d2 <= 0 then
                goto _continue
            end

            -- "d2 > 0.f"
            getOut = true
        end

        -- "crosses face"
        if d1 > d2 then
            -- "enter"
            -- "NOTE: This could be negative if d1 is less than the epsilon."
            -- "If the trace is short (d1-d2 is small) then it could produce a large negative fraction."
            local f = d1 - DIST_EPSILON
            if f < 0 then f = 0 end
            f = f / (d1 - d2)

            if f > enterFraction then
                enterFraction = f
                leadSide = brushSide
            end
        else
            -- "leave"
            local f = (d1 + DIST_EPSILON) / (d1 - d2)
            if f < leaveFraction then
                leaveFraction = f
            end
        end

        ::_continue::
    end

    -- "when this happens, we entered the brush *after* leaving the previous brush."
    -- "Therefore, we're still outside!"

    -- "NOTE: We only do this test against points because fractionleftsolid is"
    -- "not possible to compute for brush sweeps without a *lot* more computation"
    -- "So, client code will never get fractionleftsolid for box sweeps"
    if traceInfo:isRay() and startOut then
        -- "Add a little sludge.  The sludge should already be in the fractionleftsolid"
        if (traceInfo.output.FractionLeftSolid - enterFraction) > 0 then
            startOut = false
        end
    end

    if not startOut then
        -- "original point was inside brush"
        traceInfo.output.StartSolid = true
        traceInfo.output.Contents = brushContents

        if not getOut then
            traceInfo.output.Hit = true
            traceInfo.output.AllSolid = true
            traceInfo.output.Fraction = 0
            traceInfo.output.FractionLeftSolid = 1
        else
            if leaveFraction ~= 1 and leaveFraction > traceInfo.output.FractionLeftSolid then
                traceInfo.output.FractionLeftSolid = leaveFraction

                -- "This could occur if a previous trace didn't start us in solid"
                if traceInfo.output.Fraction <= leaveFraction then
                    traceInfo.output.Fraction = 1
                end
            end
        end

        return
    end

    -- "We haven't hit anything at all until we've left..."
    if enterFraction >= leaveFraction then return end
    if enterFraction <= NEVER_UPDATED or enterFraction >= traceInfo.output.Fraction then return end

    if enterFraction < 0 then
        enterFraction = 0
    end

    traceInfo.output.Hit = true
    traceInfo.output.Fraction = enterFraction
    -- TODO: pTraceInfo->m_bDispHit = false
    -- TODO: traceInfo.output.SurfaceFlags =
    -- TODO: traceInfo.output.SurfaceProps =
    traceInfo.output.Contents = brushContents
    traceInfo.output.HitNormal = leadSide.plane.normal
end

function BSPPhys:CM_TraceToLeaf(traceInfo: TraceInfo, leafIndex: integer, startFraction: number, endFraction: number)
    -- trace ray/box sweep against all brushes in this leaf
    local brushes = self.bspData:brushesInLeaf(leafIndex)
    for _, brush in ipairs(brushes) do
        if not traceInfo:visitBrush(brush) then
            goto _continue
        end

        -- only collide with objects you are interested in
        local relevantContents = bit.band(brush.contents, traceInfo.input.mask)
        if relevantContents == 0 then
            goto _continue
        end

        -- TODO?: A bunch of allegedly obsolete crap about CONTENTS_OPAQUE

        -- trace against the brush and find impact point -- if any?
        -- NOTE: pTraceInfo->m_trace.fraction == 0.0f only when trace starts inside of a brush!
        self:CM_ClipBoxToBrush(traceInfo, brush)
        if traceInfo.output.Fraction <= 0 then
            return
        end

        ::_continue::
    end

    -- TODO: Hull tracing against displacements; need to query displacements by leaf
end

function BSPPhys:CM_RecursiveHullCheckImpl(traceInfo: TraceInfo, nodeIndex: integer, p1fraction: number, p2fraction: number, p1: GVector, p2: GVector)
    local node: BSPData.PartitionNode
    local t1: number = 0
    local t2: number = 0
    local offset: number = 0

    -- Recurse through nodes to find relevant leaves
    while nodeIndex >= 0 do
        node = self.bspData.nodes[nodeIndex]
        local plane = node.plane

        t1 = plane.normal:Dot(p1) - plane.distance
        t2 = plane.normal:Dot(p2) - plane.distance

        offset = 0
        if not traceInfo:isRay() then
            local extents = traceInfo:extents()
            offset = offset + math.abs(extents.x * plane.normal.x)
            offset = offset + math.abs(extents.y * plane.normal.y)
            offset = offset + math.abs(extents.z * plane.normal.z)
        end

        -- Handle cases where the line segment lies entirely within a single child.
        if t1 > offset and t2 > offset then
            nodeIndex = node.childIndices[1]
        elseif t1 < -offset and t2 < -offset then
            nodeIndex = node.childIndices[2]
        else
            break
        end
    end

    if nodeIndex < 0 then
        self:CM_TraceToLeaf(traceInfo, -1 - nodeIndex, p1fraction, p2fraction)
        return
    end

    -- "put the crosspoint DIST_EPSILON pixels on the near side"
    local fraction = 0.0
    local fraction2 = 0.0
    local side = 0
    local dist = 1 / (t1 - t2)
    if t1 < t2 then
        side = 2
        fraction2 = (t1 + offset + DIST_EPSILON) * dist
        fraction = (t1 - offset - DIST_EPSILON) * dist
    elseif t1 > t2 then
        side = 1
        fraction2 = (t1 - offset - DIST_EPSILON) * dist
        fraction = (t1 + offset + DIST_EPSILON) * dist
    else
        side = 1
        fraction = 1
        fraction2 = 0
    end

    -- "move up to the node"
    fraction = math.min(math.max(fraction, 0), 1)
    local midfraction = p1fraction + (p2fraction - p1fraction) * fraction
    local midpoint = LerpVector(midfraction, p1, p2)

    self:CM_RecursiveHullCheckImpl(traceInfo, node.childIndices[side], p1fraction, midfraction, p1, midpoint)

    -- "go past the node"
    fraction2 = math.min(math.max(fraction2, 0), 1)
    midfraction = p1fraction + (p2fraction - p1fraction) * fraction2
    midpoint = LerpVector(midfraction, p1, p2)

    self:CM_RecursiveHullCheckImpl(traceInfo, node.childIndices[3 - side], midfraction, p2fraction, midpoint, p2)
end

function BSPPhys:CM_BoxTrace(traceInfo: TraceInfo, headNodeIndex: integer)
    local traceInput = traceInfo.input
    local traceOutput = traceInfo.output

    if not traceInfo:isSwept() then
        -- TODO: CM_UnsweptBoxTrace
    else
        self:CM_RecursiveHullCheckImpl(traceInfo, headNodeIndex, 0, 1, traceInput.start, traceInput.endpos)
    end

    -- CM_ComputeTraceEndpoints below

    -- "The ray start is the center of the extents; compute the actual start"
    -- TODO: We don't have Ray_t.m_StartOffset from TestCollision :(

    traceOutput.HitPos = LerpVector(traceOutput.Fraction, traceInput.start, traceInput.endpos)

    if traceOutput.FractionLeftSolid == 0 then
        -- traceOutput.StartPos = traceInput.start
    else
        if traceOutput.FractionLeftSolid == 1 then
            traceInfo.output.Hit = true
            traceOutput.StartSolid = true
            traceOutput.AllSolid = true
            traceOutput.Fraction = 0
        end

        -- TODO: VectorMA? ...
    end
end

function BSPPhys:trace(traceInfo: TraceInfo)
    if not traceInfo.input.ignoreworld then
        self:CM_BoxTrace(traceInfo, 0)

        if traceInfo.output.Hit then
            traceInfo.output.Entity = Entity(0)
            traceInfo.output.HitWorld = true
        end

        -- "inside world, no need to check being inside anything else"
        if traceInfo.output.StartSolid then return end

        -- "Early out if we only trace against the world"
        -- TODO: Collision groups seem to be the only way to check this
    end

    local worldFraction = traceInfo.output.Fraction
    local worldFractionLeftSolidScale = worldFraction

    -- "Create a ray that extends only until we hit the world and adjust the trace accordingly"
    -- TODO: Collide with entities

    -- traceInfo.output.Normal = (traceInfo.output.HitPos - traceInfo.output.StartPos):GetNormalized()
end

function BSPPhys:traceHull(input: S_HullTrace): S_TraceResult
    local traceInfo = TraceInfo.new(input)
    self:trace(traceInfo)
    return traceInfo.output
end

return BSPPhys
