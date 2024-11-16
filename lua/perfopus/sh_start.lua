PERFOPUS.Started = PERFOPUS.Started or false

PERFOPUS.REFRESH_RATE = CreateConVar("sh_perfopus_refresh_rate", "2", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
PERFOPUS.FREEZE = CreateConVar("sh_perfopus_freeze", "0", FCVAR_REPLICATED)

concommand.Add(SERVER && "sv_perfopus_start" or "cl_perfopus_start", function(ply)
    if SERVER && !ply:IsSuperAdmin() then return end
    if PERFOPUS.Started then return end


    -- Do on client as well if done from server
    if SERVER then
        ply:SendLua('RunConsoleCommand("cl_perfopus_start")')
    end


    -- Time all hooks
    for hookname, hooktbl in pairs(hook.GetTable()) do
        for hookid, hookfunc in pairs(hooktbl) do
            PERFOPUS.TimeThisHook(hookname, hookid, PERFOPUS.TakeMeasurement)
        end
    end


    -- Time all currently spawned entities
    for _, ent in ipairs(ents.GetAll()) do
        PERFOPUS.TimeThisEntity( ent, PERFOPUS.TakeMeasurement )
    end


    -- Timer stuff for refresh
    local NextThink = CurTime()
    if CLIENT then
        PERFOPUS.RefreshMetrics( PERFOPUS.CurrentPanel )
    end
    hook.Add("Think", "PERFOPUS", function()
        if PERFOPUS.FREEZE:GetBool() then return end
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

        table.Empty(PERFOPUS.Metrics)


        NextThink = CurTime()+PERFOPUS.REFRESH_RATE:GetFloat()
    end)


    -- Perfopus started
    PERFOPUS.Started = true
end)


if SERVER then
    util.AddNetworkString("sv_perfopus_start")

    net.Receive("sv_perfopus_start", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        concommand.Run( ply, "sv_perfopus_start" )
    end)
end