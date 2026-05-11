return {
    groupName = "FlagsToString",
    cases = {
        {
            name = "Should return a comma-separated string of constant identifiers",
            func = function()
                local FlagsToString = require("scythe.lib.flags_to_string_sh")
                local flags = FlagsToString.contents(CONTENTS_DEBRIS + CONTENTS_SOLID + CONTENTS_WATER)
                expect(flags).to.equal("CONTENTS_DEBRIS, CONTENTS_SOLID, CONTENTS_WATER")
            end,
        },
    },
}
