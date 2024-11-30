-- Test expensive operations to see if perfopus detects them

local Developer = GetConVar("developer")


if SERVER then

    concommand.Add("perfopus_lag_entity", function(ply)
        if ( ( CAMI and !CAMI.PlayerHasAccess(ply, "Perfopus - View Metrics", nil) ) or !ply:IsSuperAdmin() ) then return end

        if !PERFOPUS.Started then return end
        if !Developer:GetBool() then return end

        local sent = ents.Create("base_gmodentity")
        sent:SetPos(ply:GetEyeTrace().HitPos)
        sent:Spawn()
        SafeRemoveEntityDelayed(sent, 5)

        timer.Simple(1, function()
            sent.Think = function() for i = 1, 100000 do sent:GetPos():Distance(ply:GetPos()) end print("lag") end
        end)
    end)

end

concommand.Add(SERVER && "perfopus_lag_hook" or "cl_perfopus_lag_hook", function(ply)
    if ( ( CAMI and !CAMI.PlayerHasAccess(ply, "Perfopus - View Metrics", nil) ) or !ply:IsSuperAdmin() ) then return end

    if !PERFOPUS.Started then return end
    if !Developer:GetBool() then return end

    if SERVER then
        ply:ConCommand("cl_perfopus_lag_hook")
    end

    hook.Add("Think", "TheLaggerOfAllTime", function()
        for i = 1, 10000 do
            Entity(0):GetPos():Distance(ply:GetPos())
        end

        print("lag")
    end)


    timer.Simple(5, function()
        hook.Remove("Think", "TheLaggerOfAllTime")
    end)
end)

concommand.Add(SERVER && "perfopus_lag_timer" or "cl_perfopus_lag_timer", function(ply)
    if ( ( CAMI and !CAMI.PlayerHasAccess(ply, "Perfopus - View Metrics", nil) ) or !ply:IsSuperAdmin() ) then return end

    if !PERFOPUS.Started then return end
    if !Developer:GetBool() then return end

    if SERVER then
        ply:ConCommand("cl_perfopus_lag_timer")
    end

    timer.Create("LaggerTimer69420", 0, 0, function()
        for i = 1, 10000 do
            Entity(0):GetPos():Distance(ply:GetPos())
        end

        print("lag")
    end)


    timer.Simple(5, function()
        timer.Remove("LaggerTimer69420")
    end)
end)