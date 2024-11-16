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


concommand.Add(SERVER && "sv_perfopus_hooks" or "cl_perfopus_hooks", function(ply)
    if SERVER && !ply:IsSuperAdmin() then return end

    if SERVER then
        ply:SendLua('RunConsoleCommand("cl_perfopus_hooks")')
    end

    for hookname, hooktbl in pairs(hook.GetTable()) do
        for hookid, hookfunc in pairs(hooktbl) do
            PERFOPUS.TimeThisHook(hookname, hookid, PERFOPUS.TakeMeasurement)
        end
    end
end)

if SERVER then
    util.AddNetworkString("sv_perfopus_hooks")

    net.Receive("sv_perfopus_hooks", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        concommand.Run( ply, "sv_perfopus_hooks" )
    end)
end



