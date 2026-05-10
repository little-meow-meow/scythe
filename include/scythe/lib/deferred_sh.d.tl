-- https://github.com/zserge/lua-promises/blob/master/deferred.lua

local record Promise<TResult, TFailure>
    --- Returns a new promise object.
    new: function(): Promise<TResult, TFailure>
    --- Returns a new promise object that is resolved when all promises are resolved/rejected.
    all: function(promises: {Promise}): Promise
    --- Returns a new promise object that is resolved with the values of sequential application of function fn to each element in the list. fn is expected to return promise object.
    map: function<TIn, TOut>(values: {TIn}, functor: function(TIn): Promise<TOut>): Promise<TOut>
    --- Returns a new promise object that is resolved as soon as the first of the promises gets resolved/rejected.
    first: function<T>(promises: {Promise<T>}): Promise<T>

    resolve: function(self: Promise, value: TResult): Promise<TResult>
    reject: function(self: Promise, reason: TFailure): Promise

    next: function<TNextResult, TNextFailure>(self: Promise, closure: function(TResult): TNextResult, rejectedClosure: function(TFailure): TNextFailure): Promise<TNextResult, TNextFailure>
end

return Promise
