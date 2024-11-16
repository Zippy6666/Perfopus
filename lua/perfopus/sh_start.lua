PERFOPUS.Started = PERFOPUS.Started or false

local REFRESH_RATE = CreateConVar("sh_perfopus_refresh_rate", "2", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
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

    if CLIENT then
        PERFOPUS.RefreshMetrics( PERFOPUS.CurrentPanel )
    end

    local NextThink = CurTime()
    hook.Add("Think", "PERFOPUS", function()
        if NextThink > CurTime() then return end

        if CLIENT then
            PERFOPUS.RefreshMetrics( PERFOPUS.CurrentPanel )
        elseif SERVER then
            -- Very expensive, I know
            net.Start("SendServerMetrics")
            net.WriteTable(PERFOPUS.GetReadableMetrics())
            net.WriteFloat(FrameTime())
            net.Send(ply)
        end

        for source, funcs in pairs(PERFOPUS.Metrics) do
            for func in pairs(funcs) do
                funcs[func] = 0 -- Reset time
            end
        end

        NextThink = CurTime()+REFRESH_RATE:GetFloat()
    end)

    PERFOPUS.Started = true
end)


if SERVER then
    util.AddNetworkString("sv_perfopus_start")

    net.Receive("sv_perfopus_start", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        concommand.Run( ply, "sv_perfopus_start" )
    end)
end