local cases = {
    {
        -- Hull trace; gm_construct; down onto displacement
        name = "Physics Test #1",
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(0, 0, 0),
                endpos = Vector(0, 0, -500),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            expect(result.AllSolid).to.beFalse()
            expect(result.Contents).to.equal(1)
            -- expect(result.DispFlags).to.equal(23)
            expect(result.Entity).to.equal(Entity(0))
            expect(result.Fraction).to.aboutEqual(0.28993758559227)
            expect(result.FractionLeftSolid).to.aboutEqual(0.0)
            expect(result.Hit).to.beTrue()
            expect(result.HitBox).to.equal(0)
            expect(result.HitGroup).to.equal(0)
            expect(result.HitNoDraw).to.beFalse()
            expect(result.HitNonWorld).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(1.0)
            expect(result.HitPos.x).to.aboutEqual(0.0)
            expect(result.HitPos.y).to.aboutEqual(0.0)
            expect(result.HitPos.z).to.aboutEqual(-144.968796)
            expect(result.HitSky).to.beFalse()
            -- expect(result.HitTexture).to.equal("**displacement**")
            expect(result.HitWorld).to.beTrue()
            -- expect(result.MatType).to.equal(85)
            expect(result.Normal.x).to.aboutEqual(0.0)
            expect(result.Normal.y).to.aboutEqual(0.0)
            expect(result.Normal.z).to.aboutEqual(-1.0)
            expect(result.PhysicsBone).to.equal(0)
            expect(result.StartPos.x).to.aboutEqual(0.0)
            expect(result.StartPos.y).to.aboutEqual(0.0)
            expect(result.StartPos.z).to.aboutEqual(0.0)
            expect(result.StartSolid).to.beFalse()
            expect(result.SurfaceFlags).to.equal(0)
            -- expect(result.SurfaceProps).to.equal(12)
        end,
    },

    {
        -- Hull trace; gm_construct; down onto brush surface
        name = "Physics Test #2",
        func = function()
            local Scythe = require("scythe.scythe_sh")
            local map = Scythe.loadedMaps[1]

            expect(map.name).to.equal("maps/gm_construct.bsp")

            local result = map.bspPhys:traceHull({
                start = Vector(0, 0, 0),
                endpos = Vector(0, 0, -500),
                mask = MASK_SOLID,
                mins = Vector(-3, -3, -3),
                maxs = Vector(3, 3, 3),
            })

            expect(result).to.exist()
            expect(result).to.beA("table")

            --[[

            ["AllSolid"]	=	false
            ["Contents"]	=	1
            ["DispFlags"]	=	0
            ["Entity"]	=	Entity [0][worldspawn]
            ["Fraction"]	=	0.28193750977516
            ["FractionLeftSolid"]	=	0
            ["Hit"]	=	true
            ["HitBox"]	=	0
            ["HitGroup"]	=	0
            ["HitNoDraw"]	=	false
            ["HitNonWorld"]	=	false
            ["HitNormal"]	=	0.000000 0.000000 1.000000
            ["HitPos"]	=	865.000000 0.000000 -140.968750
            ["HitSky"]	=	false
            ["HitTexture"]	=	GM_CONSTRUCT/CONSTRUCT_CONCRETE_FLOOR
            ["HitWorld"]	=	true
            ["MatType"]	=	67
            ["Normal"]	=	0.000000 0.000000 -1.000000
            ["PhysicsBone"]	=	0
            ["StartPos"]	=	865.000000 0.000000 0.000000
            ["StartSolid"]	=	false
            ["SurfaceFlags"]	=	2048
            ["SurfaceProps"]	=	30

            ]]

            expect(result.AllSolid).to.beFalse()
            expect(result.Contents).to.equal(1)
            expect(result.DispFlags).to.equal(0)
            expect(result.Entity).to.equal(Entity(0))
            expect(result.Fraction).to.aboutEqual(0.28193750977516)
            expect(result.FractionLeftSolid).to.aboutEqual(0.0)
            expect(result.Hit).to.beTrue()
            expect(result.HitBox).to.equal(0)
            expect(result.HitGroup).to.equal(0)
            expect(result.HitNoDraw).to.beFalse()
            expect(result.HitNonWorld).to.beFalse()
            expect(result.HitNormal.x).to.aboutEqual(0.0)
            expect(result.HitNormal.y).to.aboutEqual(0.0)
            expect(result.HitNormal.z).to.aboutEqual(1.0)
            expect(result.HitPos.x).to.aboutEqual(865.0)
            expect(result.HitPos.y).to.aboutEqual(0.0)
            expect(result.HitPos.z).to.aboutEqual(-144.968796)
            expect(result.HitSky).to.beFalse()
            expect(result.HitTexture).to.equal("GM_CONSTRUCT/CONSTRUCT_CONCRETE_FLOOR")
            expect(result.HitWorld).to.beTrue()
            -- expect(result.MatType).to.equal(67)
            expect(result.Normal.x).to.aboutEqual(0.0)
            expect(result.Normal.y).to.aboutEqual(0.0)
            expect(result.Normal.z).to.aboutEqual(-1.0)
            expect(result.PhysicsBone).to.equal(0)
            expect(result.StartPos.x).to.aboutEqual(865.0)
            expect(result.StartPos.y).to.aboutEqual(0.0)
            expect(result.StartPos.z).to.aboutEqual(0.0)
            expect(result.StartSolid).to.beFalse()
            expect(result.SurfaceFlags).to.equal(2048)
            -- expect(result.SurfaceProps).to.equal(30)
        end,
    },
}

return {
    groupName = "FlagsToString",
    cases = cases,
}
