local T = {}

T.groupName = "Scythe"
T.cases = {
    {
        name = "Should create public API table",
        func = function()
            expect(Scythe).to.exist()
        end,
    }
}

return T
