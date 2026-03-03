(makeRequireCompat or function() end)()

local type Types = require("scythe.types")
local BSPData = require("scythe.bsp")

local SURFDRAW_NOLIGHT      = 0x0001
local SURFDRAW_NODE         = 0x0002
local SURFDRAW_SKY          = 0x0004
local SURFDRAW_TRANS        = 0x0008
local SURFDRAW_PLANEBACK    = 0x0010
local SURFDRAW_DYNAMIC      = 0x0020
local SURFDRAW_TANGENTSPACE = 0x0040

local interface Renderable
    interface Vertex
        position: GVector
        normal: GVector
        tangentS: GVector | nil
        tangentT: GVector | nil
        color: Types.ColorRGBA | nil
        baseTextureU: number | nil
        baseTextureV: number | nil
        lightmapU: number | nil
        lightmapV: number | nil
    end

    mesh: GIMesh
    material: GIMaterial
    lightmapTexture: GITexture | nil
end

local record BSPRenderer
    bspData: BSPData
    renderables: {Renderable}
    faceToRenderableMap: {BSPData.Face: Renderable}

    buildRenderables: function(self: BSPRenderer)
end

function BSPRenderer.new(bspData: BSPData): BSPRenderer
    local renderer: BSPRenderer = setmetatable({}, {__index = BSPRenderer})
    renderer.bspData = bspData
    renderer.renderables = {}
    renderer.faceToRenderableMap = {}
    renderer:buildRenderables()
    return renderer
end

local function assemble(vertices: {Renderable.Vertex}, primitiveType: number, primitiveCount: number, material: GIMaterial): Renderable
    local _mesh = Mesh(material)
    mesh.Begin(_mesh, primitiveType, primitiveCount)
        for _, vertex in ipairs(vertices) do
            mesh.Position(vertex.position.x, vertex.position.y, vertex.position.z)

            if vertex.baseTextureU and vertex.baseTextureV then
                mesh.TexCoord(0, vertex.baseTextureU, vertex.baseTextureV)
            end

            if vertex.lightmapU and vertex.lightmapV then
                mesh.TexCoord(1, vertex.lightmapU, vertex.lightmapV, 0, 0)
            end

            if vertex.normal then
                mesh.Normal(vertex.normal.x, vertex.normal.y, vertex.normal.z)
            end

            local tangentS = vertex.tangentS
            local tangentT = vertex.tangentT
            if tangentS is GVector and tangentT is GVector then
                mesh.TangentS(tangentS.x, tangentS.y, tangentS.z)
                mesh.TangentT(tangentT.x, tangentT.y, tangentT.z)
            end

            local color = vertex.color
            if color is Types.ColorRGBA then
                mesh.Color(color.r, color.g, color.b, color.a)
            end

            mesh.AdvanceVertex()
        end
    mesh.End()

    return {
        mesh = _mesh,
        material = material,
    }
end

local function buildDisplacement(face: BSPData.Face, bspData: BSPData): Renderable
    local s = face.texture.textureVecs[1]
    local t = face.texture.textureVecs[2]

    local sVector = Vector(s.x, s.y, s.z)
    local tVector = Vector(t.x, t.y, t.z)
    local surfaceTangent = sVector:Cross(tVector)
    local negateTangentS = face.plane.normal:Dot(surfaceTangent) > 0.0 and -1 or 1
    local wantsTangents = bit.band(face.texture.flags, SURFDRAW_TANGENTSPACE)

    local vertices: {Renderable.Vertex} = {}

    local displacementInfo = face.displacementInfo as BSPData.DisplacementInfo

    local corners = {}
    local startDist = math.huge
    local startCorner = -1
    for i = 0, 3 do
        local corner = face.edges[i][1]
        corners[i] = corner
        local dist = corner:DistToSqr(displacementInfo.startPosition)
        if dist < startDist then
            startCorner = i
            startDist = dist
        end
    end

    -- rotate corners so start corner is first
    if startCorner ~= 0 then
        local rotatedCorners = {}
        for i = 0, 3 do
            local index = (i + startCorner) % 4
            rotatedCorners[i] = corners[index]
        end
        corners = rotatedCorners
    end

    -- TODO: Displacement construction
    -- TODO: Displacement vertex lightmap coordinates
    -- TODO: Fan triangles

    local material = Material(face.texture.data.name)
    return assemble(vertices, MATERIAL_TRIANGLES, #vertices / 3, material)
end

local function buildBrushFace(face: BSPData.Face, bspData: BSPData): Renderable
    local s = face.texture.textureVecs[1]
    local t = face.texture.textureVecs[2]

    local sVector = Vector(s.x, s.y, s.z)
    local tVector = Vector(t.x, t.y, t.z)
    local surfaceTangent = sVector:Cross(tVector)
    local negateTangentS = face.plane.normal:Dot(surfaceTangent) > 0.0 and -1 or 1
    local wantsTangents = bit.band(face.texture.flags, SURFDRAW_TANGENTSPACE)

    local vertices: {Renderable.Vertex} = {}
    for edgeIndexOffset, edge in pairs(face.edges) do
        local vertex: Renderable.Vertex = {}
        local vertexPosition = edge[1]

        vertex.position = vertexPosition

        vertex.baseTextureU = (vertexPosition:Dot(sVector) + s.w) / face.texture.data.width
        vertex.baseTextureV = (vertexPosition:Dot(tVector) + t.w) / face.texture.data.height

        if wantsTangents then
            local vertexIndex = bspData.vertexIndices[face.firstEdgeIndex + edgeIndexOffset]
            local vertNormal = bspData.vertexNormals[bspData.vertexNormalIndices[vertexIndex]]
            local tangentS = vertNormal:Cross(tVector)
            tangentS:Normalize()
            local tangentT = tangentS:Cross(vertNormal)
            tangentT:Normalize()

            tangentS:Mul(negateTangentS as number)

            vertex.tangentS = tangentS
            vertex.tangentT = tangentT
        end

        -- TODO: Needs to know lightmap texture coordinates to fill these out. This can be deferred but it will require rebuilding the mesh.
        -- vertex.lightmapU = vertexPosition.x * face.texture.lightmapVecs[1].x + vertexPosition.y * face.texture.lightmapVecs[1].y + vertexPosition.z * face.texture.lightmapVecs[1].z + face.texture.lightmapVecs[1].w
        -- vertex.lightmapV = vertexPosition.x * face.texture.lightmapVecs[2].x + vertexPosition.y * face.texture.lightmapVecs[2].y + vertexPosition.z * face.texture.lightmapVecs[2].z + face.texture.lightmapVecs[2].w
        -- vertex.lightmapU = (vertex.lightmapU + 0.5 - face.lightmapLuxelMins[1]) / lightmapData.pow2Width
        -- vertex.lightmapV = (vertex.lightmapV + 0.5 - face.lightmapLuxelMins[2]) / lightmapData.pow2Height

        vertex.normal = face.plane.normal

        table.insert(vertices, vertex)
    end

    local material = Material(face.texture.data.name)
    return assemble(vertices, MATERIAL_POLYGON, face.edgeCount, material)
end

function BSPRenderer:buildRenderables()
    for faceIndex, face in pairs(self.bspData.faces) do
        local renderable: Renderable = nil
        if face.displacementInfoIndex == -1 then
            renderable = buildBrushFace(face, self.bspData)
        else
            -- renderable = buildDisplacement(face, self.bspData)
        end
        self.faceToRenderableMap[face] = renderable
        table.insert(self.renderables, renderable)
    end

    -- TODO: Iterate static props ...
    -- TODO: Iterate overlays ...
    -- TODO: Iterate decals ...
end

local MAT_WIREFRAME = Material("editor/wireframe")
function BSPRenderer:drawLeaf(leafIndex: integer)
    local leaf = self.bspData.leaves[leafIndex]
    for i = 0, leaf.leafFaceCount - 1 do
        local face = self.bspData.leafFaces[leaf.leafFaceIndexOffset + i]
        local renderable = self.faceToRenderableMap[face]
        render.SetMaterial(renderable.material or MAT_WIREFRAME)
        renderable.mesh:Draw()
    end
end

function BSPRenderer:draw()
    self:drawLeaf(4053)
    -- for _, renderable in ipairs(self.renderables) do

    --     render.SetMaterial(renderable.material or MAT_WIREFRAME)
    --     -- render.SetMaterial( matWireframe )
    --     -- render.SetLightmapTexture(meshEntry.lightmap and meshEntry.lightmap or TEX_WHITE)

    --     renderable.mesh:Draw()

    --     -- render.RenderFlashlights( function()
    --     --     renderable.mesh:Draw()
    --     -- end )
    -- end
end

return BSPRenderer
