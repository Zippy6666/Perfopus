function PERFOPUS.TimeThisEntity( ent, listenerfunc )
    for k, v in pairs(ent:GetTable()) do
        if isfunction(v) then
            local short_src = debug.getinfo(v).short_src
            newfunc = function(...)
                local startTime = SysTime()
                local return_values = table.Pack( v(...) )
                listenerfunc( SysTime()-startTime, "METHOD: "..k, short_src )
                return unpack(return_values)
            end
            ent[k] = newfunc
        end
    end
end


hook.Add("OnEntityCreated", "PERFOPUS", function( ent )
    if !PERFOPUS.Started then return end

    conv.callNextTick(function()
        if !IsValid(ent) then return end
        PERFOPUS.TimeThisEntity(ent, PERFOPUS.TakeMeasurement)
    end)
end)