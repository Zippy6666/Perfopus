local HeardNewHook = false
function PERFOPUS.ListenForNewHooks()
    hook.Add = conv.wrapFunc("PERFOPUSListenForNewHooks", hook.Add, nil, function(return_values, hooktype, hookid)
        if HeardNewHook then return end
        HeardNewHook = true
        PERFOPUS.TimeThisHook( hooktype, hookid, PERFOPUS.TakeMeasurement )
        HeardNewHook = false
    end)
end


function PERFOPUS.TimeThisHook( hooktype, hookid, listenerfunc )
    if TIMED_HOOKS && TIMED_HOOKS[hooktype] && TIMED_HOOKS[hooktype][hookid] then return end
    if hookid && isstring(hookid) && string.StartsWith(hookid, "PERFOPUS") then return end -- Don't time performance on PERFOPUS hooks

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

    local newfunc = function(...)
        local startTime = SysTime()
        local return_values = table.Pack( hookfunc(...) )
        listenerfunc( SysTime()-startTime, "HOOK: "..hooktype.." - "..tostring(hookid), short_src )
        return unpack(return_values)
    end

    local notValid = hookid == nil || isnumber( hookid ) or isbool( hookid ) or isfunction( hookid ) or !hookid.IsValid or !IsValid( hookid )
	if ( !isstring( hookid ) and notValid ) then
        return
    end
    
    hook.Add(hooktype, hookid, newfunc)
end



