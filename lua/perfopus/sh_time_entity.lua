function PERFOPUS.ListenForNewEntityMethods()
    local ENT = FindMetaTable("Entity")

    ENT.__newindex = conv.wrapFunc("PERFOPUSListenForNewEntityMethods", ENT.__newindex, nil, function(return_values, self, method, ...)
        PERFOPUS.TimeThisEntMethod( ent, method, PERFOPUS.TakeMeasurement )
    end)
end


function PERFOPUS.TimeThisEntMethod( ent, methodname, listenerfunc )
    local method = ent[methodname]

    if !isfunction(method) then return end

    local short_src = debug.getinfo(method).short_src
    newfunc = function(...)
        local startTime = SysTime()
        local return_values = table.Pack( method(...) )
        listenerfunc( SysTime()-startTime, "METHOD: "..methodname, short_src )
        return unpack(return_values)
    end
    ent[methodname] = newfunc

    print("started listening to", methodname, "for", ent)
end


function PERFOPUS.TimeThisEntity( ent, listenerfunc )
    for k, v in pairs(ent:GetTable()) do
        if isfunction(v) then
            PERFOPUS.TimeThisEntMethod(ent, methodname, listenerfunc)
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