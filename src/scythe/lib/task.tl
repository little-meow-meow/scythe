local Promise = require("scythe.lib.deferred_sh")

local record TaskPool
    executionQuota: number
    tasks: {thread:Promise<any, any>}
end

-- The maximum time in seconds the task pool will spend working every work()
TaskPool.executionQuota = (1 / 66) / 4

function TaskPool.add<TResult>(closure: function(): TResult): Promise<TResult, string>
    local promise: Promise<TResult, string> = Promise.new()
    local thread = coroutine.create(closure)
    TaskPool.tasks[thread] = promise as Promise<any, any>
    return promise
end

function TaskPool.work()
    local startTime = os.clock()

    local worked = false
    repeat
        worked = false
        for thread, promise in pairs(TaskPool.tasks) do
            if os.clock() - startTime >= TaskPool.executionQuota then
                break
            end

            local noError, result = coroutine.resume(thread)

            if not noError then
                promise:reject(result)
            elseif coroutine.status(thread) == "dead" then
                TaskPool.tasks[thread] = nil
                promise:resolve(result)
            end

            worked = true
        end
    until os.clock() - startTime >= TaskPool.executionQuota or not worked
end

if hook then
    hook.Add( "Think", "TaskPool.Think", TaskPool.work )
end

return TaskPool
