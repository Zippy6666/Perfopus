PERFOPUS.Started = PERFOPUS.Started or false

PERFOPUS.REFRESH_RATE = CreateConVar("sh_perfopus_refresh_rate", "2", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
PERFOPUS.FREEZE = CreateConVar("sh_perfopus_freeze", "0", FCVAR_REPLICATED)

concommand.Add(SERVER && "sv_perfopus_start" or "cl_perfopus_start", function(ply)
    if SERVER then
        if ( ( CAMI and !CAMI.PlayerHasAccess(ply, "Perfopus - View Metrics", nil) ) or !ply:IsSuperAdmin() ) then return end
    end

    if CLIENT && PERFOPUS.Started then
        -- Perfopus already started on this client
        return
    end


    if SERVER then

        -- Run the command for this client
        ply:SendLua('RunConsoleCommand("cl_perfopus_start")')

        -- Already started on server, don't start again
        if PERFOPUS.Started then return end

    end


    -- Time all hooks
    for hookname, hooktbl in pairs(hook.GetTable()) do
        for hookid, hookfunc in pairs(hooktbl) do
            PERFOPUS.TimeThisHook(hookname, hookid, PERFOPUS.TakeMeasurement)
        end
    end
    PERFOPUS.ListenForNewHooks()


    -- Time all currently spawned entities
    for _, ent in ipairs(ents.GetAll()) do
        PERFOPUS.TimeThisEntity( ent, PERFOPUS.TakeMeasurement )
    end
    PERFOPUS.ListenForNewEntityMethods()


    PERFOPUS.ListenForTimersToTime(PERFOPUS.TakeMeasurement)


    -- Stuff for refresh
    local NextThink = CurTime()
    if SERVER then

        hook.Add("Think", "PERFOPUS", function()
            if PERFOPUS.FREEZE:GetBool() then return end
            if NextThink > CurTime() then return end


            for _, superadmin in player.Iterator() do
                if ( ( CAMI and !CAMI.PlayerHasAccess(superadmin, "Perfopus - View Metrics", nil) ) or !superadmin:IsSuperAdmin() ) then continue end

                if superadmin:GetInfoNum("cl_perfopus_showing_metrics", 0) < 1 then continue end

                net.Start("SendServerMetrics")
                net.WriteTable(PERFOPUS.GetReadableMetrics()) -- Very expensive, I know
                net.Send(superadmin)
            end


            table.Empty(PERFOPUS.Metrics)
            NextThink = CurTime()+PERFOPUS.REFRESH_RATE:GetFloat()
        end)

    elseif CLIENT then

        if PERFOPUS.CurrentPanel then
            PERFOPUS.RefreshMetrics( PERFOPUS.CurrentPanel )
        end

        hook.Add("Think", "PERFOPUS", function()
            if PERFOPUS.FREEZE:GetBool() then return end
            if NextThink > CurTime() then return end

            if PERFOPUS.CurrentPanel then
                PERFOPUS.RefreshMetrics( PERFOPUS.CurrentPanel )
            end

            table.Empty(PERFOPUS.Metrics)
            NextThink = CurTime()+PERFOPUS.REFRESH_RATE:GetFloat()
        end)

    end

    -- Perfopus started
    PERFOPUS.Started = true
end)


if SERVER then
    util.AddNetworkString("sv_perfopus_start")

    net.Receive("sv_perfopus_start", function(_, ply)
        if ( ( CAMI and !CAMI.PlayerHasAccess(ply, "Perfopus - View Metrics", nil) ) or !ply:IsSuperAdmin() ) then return end

        ply:ConCommand("sv_perfopus_start")
    end)
end