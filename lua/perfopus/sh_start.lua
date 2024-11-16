PERFOPUS.Started = PERFOPUS.Started or false

concommand.Add(SERVER && "sv_perfopus_start" or "cl_perfopus_start", function(ply)
    if SERVER && !ply:IsSuperAdmin() then return end
    if PERFOPUS.Started then return end

    if SERVER then
        ply:SendLua('RunConsoleCommand("cl_perfopus_start")')
    end

    -- Time all hooks
    for hookname, hooktbl in pairs(hook.GetTable()) do
        for hookid, hookfunc in pairs(hooktbl) do
            PERFOPUS.TimeThisHook(hookname, hookid, PERFOPUS.TakeMeasurement)
        end
    end

    PERFOPUS.Started = true
end)


if SERVER then
    util.AddNetworkString("sv_perfopus_start")

    net.Receive("sv_perfopus_start", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        concommand.Run( ply, "sv_perfopus_start" )
    end)
end