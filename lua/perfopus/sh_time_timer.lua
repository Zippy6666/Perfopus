function PERFOPUS.ListenForTimersToTime( listenerfunc )
    timer.Create = conv.wrapFunc("PERFOPUSListenForNewTimers", timer.Create, nil, function(return_vales, id, delay, reps, func)

        local short_src = debug.getinfo(func).short_src
        local newfunc = function(...)
            local startTime = SysTime()
            local return_values = table.Pack( func(...) )
            listenerfunc( SysTime()-startTime, "TIMER: "..id, short_src )
            return unpack(return_values)
        end
        timer.Adjust(id, delay, nil, newfunc)

    end)
end

-- TODO: Is it possible to get all current timers?