function PERFOPUS.TimeThisHook( hooktype, hookid, listenerfunc )
    /*
        Makes so that a hook supplies the execution time by passing it as an argument to 'listenerfunc'
    */

    if TIMED_HOOKS && TIMED_HOOKS[hooktype] && TIMED_HOOKS[hooktype][hookid] then print("already timed") return end

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
    local addonname
    if string.StartsWith(short_src, "addons/") then
        split = string.Split(short_src, "/")
        addonname = split[2]
    end
    if !addonname then return end -- Not addon so screw this mf


    TIMED_HOOKS = TIMED_HOOKS or {}
    TIMED_HOOKS[hooktype] = TIMED_HOOKS[hooktype] or {}
    TIMED_HOOKS[hooktype][hookid] = true

    newfunc = function(...)
        local startTime = SysTime()
        local return_values = table.Pack( hookfunc(...) )
        listenerfunc(SysTime()-startTime, "HOOK: "..hooktype.." - "..hookid, )
        return unpack(return_values)
    end

    hook.Add(hooktype, hookid, newfunc)
end


concommand.Add(SERVER && "sv_time_listen_hooks" or "cl_time_listen_hooks", function()
    if SERVER then
        RunConsoleCommand("cl_time_listen_hooks")
    end

    for hookname, hooktbl in pairs(hook.GetTable()) do
        for hookid, hookfunc in pairs(hooktbl) do
            PERFOPUS.TimeThisHook(hookname, hookid, PERFOPUS.TakeMeasurement)
        end
    end
end)




