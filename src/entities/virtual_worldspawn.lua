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
        -- TODO: Uh oh, I don't think we have access to the real mins/maxs of the trace!
        mins = isbox and -extents or nil,
        maxs = isbox and extents or nil,
        whitelist = true, -- DEBUG!
    }

    return map.bspPhys:traceHull(trace)
end
