local record To
    equal: function(any)
    eq: function(any)
    aboutEqual: function(any)
    deepEqual: function(table)
    beLessThan: function(any)
    beGreaterThan: function(any)
    beBetween: function(any, any)
    beTrue: function()
    beFalse: function()
    beValid: function()
    beInvalid: function()
    beNil: function()
    exist: function()
    beA: function(string)
    beAn: function(string)
    succeed: function()
    err: function()
    errWith: function(string)
    called: function()
end

local record Expectation
    to: To
    was: To
    toNot: To
    notTo: To
end

global function expect(any): Expectation
end
