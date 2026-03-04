(makeRequireCompat or function() end)()

local type BSPData = require("scythe.bsp")

local record BSPOcclusion
    bspData: BSPData
end

function BSPOcclusion.new(bspData: BSPData): BSPOcclusion
    local occlusion: BSPOcclusion = setmetatable({}, {__index = BSPOcclusion})
    occlusion.bspData = bspData
    return occlusion
end

function BSPOcclusion:getLeafIndexForPoint(point: GVector, nodeIndex: integer): integer
    local node = self.bspData.nodes[nodeIndex]
    local plane = node.plane

    local direction: number = nil
    if plane.type < 3 then
        direction = point[plane.type + 1] - plane.distance
    else
        direction = plane.normal:Dot(point) - plane.distance
    end

    local childIndex = direction >= 0 and 1 or 2
    local nextNodeIndex = node.childIndices[childIndex]

    if nextNodeIndex < 0 then
        return -1 - nextNodeIndex
    else
        return self:getLeafIndexForPoint(point, nextNodeIndex)
    end
end

return BSPOcclusion
