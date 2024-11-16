function PERFOPUS.TimeThisHook( hooktype, hookid, listenerfunc )
    /*
        Makes so that a hook supplies the execution time by passing it as an argument to 'listenerfunc'
    */

    if TIMED_HOOKS && TIMED_HOOKS[hooktype] && TIMED_HOOKS[hooktype][hookid] then print("already timed") return end
    if hookid && isstring(hookid) && string.StartsWith(hookid, "PERFOPUS") then return end -- Don't time performance on PERFOPUS hooks

    local hooktbl = hook.GetTable()[hooktype]
    if !hooktbl then
        ErrorNoHalt("[TimeThisHook] Hook type does not exist: ", hooktype, "\n")
        return
    end

    local hookfunc = hooktbl[hookid]
    if !hookfunc then
        ErrorNoHalt("[TimeThisHook] Could not find: '", hooktype, "' with ID '", hookid, "'\n")
        return
    end

    local short_src = debug.getinfo(hookfunc).short_src

    TIMED_HOOKS = TIMED_HOOKS or {}
    TIMED_HOOKS[hooktype] = TIMED_HOOKS[hooktype] or {}
    TIMED_HOOKS[hooktype][hookid] = true

    newfunc = function(...)
        local startTime = SysTime()
        local return_values = table.Pack( hookfunc(...) )
        listenerfunc( SysTime()-startTime, "HOOK: "..hooktype.." - "..tostring(hookid), short_src )
        return unpack(return_values)
    end

    hook.Add(hooktype, hookid, newfunc)
end



