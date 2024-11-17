local HeardNewEntMethod = false
function PERFOPUS.ListenForNewEntityMethods()
    local ENT = FindMetaTable("Entity")

    ENT.__newindex = conv.wrapFunc("PERFOPUSListenForNewEntityMethods", ENT.__newindex, nil, function(return_values, self, method, ...)
        if HeardNewEntMethod then return end
        HeardNewEntMethod = true
        PERFOPUS.TimeThisEntMethod( self, method, PERFOPUS.TakeMeasurement )
        HeardNewEntMethod = false
    end)
end


local ForbiddenMethods = {
    Use = true,
}
function PERFOPUS.TimeThisEntMethod( ent, methodname, listenerfunc )
    local method = ent[methodname]

    if !isfunction(method) then return end
    if ForbiddenMethods[methodname] then return end
    print("started watching", methodname)

    local short_src = debug.getinfo(method).short_src
    local newfunc = function(...)
        local startTime = SysTime()
        local return_values = table.Pack( method(...) )
        listenerfunc( SysTime()-startTime, "METHOD: "..methodname, short_src )
        return unpack(return_values)
    end
    ent[methodname] = newfunc
end


function PERFOPUS.TimeThisEntity( ent, listenerfunc )
    HeardNewEntMethod = true
    for k, v in pairs(ent:GetTable()) do
        if isfunction(v) then
            PERFOPUS.TimeThisEntMethod(ent, k, listenerfunc)
        end
    end
    HeardNewEntMethod = false
end


hook.Add("OnEntityCreated", "PERFOPUS", function( ent )
    if !PERFOPUS.Started then return end

    conv.callNextTick(function()
        if !IsValid(ent) then return end
        HeardNewEntMethod = true
        PERFOPUS.TimeThisEntity(ent, PERFOPUS.TakeMeasurement)
        HeardNewEntMethod = false
    end)
end)