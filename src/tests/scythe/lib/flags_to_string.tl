return {
    groupName = "FlagsToString",
    cases = {
        {
            name = "Should return a comma-separated string of constant identifiers",
            func = function()
                local FlagsToString = require("scythe.lib.flags_to_string_sh")
                local flags = FlagsToString.contents(CONTENTS_DEBRIS + CONTENTS_SOLID + CONTENTS_WATER)
                -- We can't rely on the ordering of identifiers due to dictionary tables being unsorted
                expect(flags).to.exist()
                expect(flags).to.beA("string")
                expect(#flags).to.equal(47)
            end,
        },
    },
}
