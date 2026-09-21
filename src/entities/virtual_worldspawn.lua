AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Spawnable = false

ENT.Model = Model( "models/props_junk/wood_crate002a.mdl" )

local HAMMER_MAX_MAP_LENGTH = 32767
local HAMMER_MAX_MAP_VECTOR = Vector( HAMMER_MAX_MAP_LENGTH, HAMMER_MAX_MAP_LENGTH, HAMMER_MAX_MAP_LENGTH )

function ENT:Initialize()
    self:SetModel( self.Model )

    self:PhysicsInit( SOLID_BBOX )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_BBOX )

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    self:EnableCustomCollisions()
    self:SetCollisionBounds( HAMMER_MAX_MAP_VECTOR * -1, HAMMER_MAX_MAP_VECTOR )
end

function ENT:BuildFromTriangles( soup )
    self:PhysicsFromMesh( soup )
    self:GetPhysicsObject():EnableMotion( false )
    self:EnableCustomCollisions()

    if CLIENT then
        self.mesh = Mesh()
        self.mesh:BuildFromTriangles( soup )
    end
end

function ENT:Draw()
end

function ENT:TestCollision( startpos, delta, isbox, extents, mask )
    if not Scythe then return end
    if not Scythe.loadedMaps[1] then return end

    local map = Scythe.loadedMaps[1]
    local trace = {
        start = startpos,
        endpos = startpos + delta,
        mask = mask,
        mins = isbox and -extents or nil,
        maxs = isbox and extents or nil,
        whitelist = true, -- DEBUG!
    }

    -- IMPORTANT: TestCollision's `startpos` argument has `Ray_t.m_StartOffset` reversed.
    -- The `extents` argument is still centered (as in `Ray_t::Init`).
    -- The hook needs an API change for accurate player movement with `CGameMovement::TryTouchGroundInQuadrants`

    -- IMPORTANT: This hook is only called for traces that hit entities and do not filter this entity.
    -- A more general-purpose hook is needed for overriding *all* CEngineTrace::TraceRay calls.

    if isbox then
        -- This is a hack to make player movement (somewhat) precise.
        -- The original hull bounding box is lost in `Ray_t::Init` and we need it to accurately perform hull traces.
        trace.startOffset = Vector(0, 0, extents.z)
        trace.start = trace.start + trace.startOffset
        trace.endpos = trace.start + delta
    end

    -- TODO: Once the needed GLua API changes are available, `Ray_t::Init`'s hull
    -- trace centering behavior should be moved to `BSPPhys:traceHull`.

    local tr = map.bspPhys:traceHull(trace)

    -- IMPORTANT: TestCollision's `Normal` is E_TraceResult's `HitNormal`
    tr.Normal = tr.HitNormal

    return tr
end
