-- Should contain: Function / hook name, source, exec time
PERFOPUS.Metrics = PERFOPUS.Metrics or {}


PERFOPUS.ENT_INFLICTOR_IDX = -1


function PERFOPUS.TakeMeasurement( time, name, source, ent )
    -- New measurement of *source* (a lua file path), with data ({})
    PERFOPUS.Metrics[source] = PERFOPUS.Metrics[source] or {}

    -- Add a sub source of *name* with execution time
    -- A sub source is a function call in some form
    PERFOPUS.Metrics[source][name] = PERFOPUS.Metrics[source][name] && PERFOPUS.Metrics[source][name] + time or time

    -- Optional entity that is to blame for the execution time
    ent = ent or NULL
    PERFOPUS.Metrics[source][PERFOPUS.ENT_INFLICTOR_IDX] = ent
end


local REALM_CL, REALM_SV = 0, 1
function PERFOPUS.GetReadableMetrics()

    local srcs_metrics = {}
    for src, functbl in pairs(PERFOPUS.Metrics) do
        local entInfl = functbl[PERFOPUS.ENT_INFLICTOR_IDX]
        functbl[PERFOPUS.ENT_INFLICTOR_IDX] = nil

        srcs_metrics[src] = {funcs=functbl, realm=SERVER && REALM_SV or REALM_CL, ent=entInfl }

        for funcname, time in pairs(functbl) do
            if funcname == PERFOPUS.ENT_INFLICTOR_IDX then continue end

            srcs_metrics[src].time = srcs_metrics[src].time && srcs_metrics[src].time+time or time
        end
    end

    return srcs_metrics

end


if SERVER then
    util.AddNetworkString("SendServerMetrics")
end


if CLIENT then
    net.Receive("SendServerMetrics", function()
        if ( ( PERFOPUS.CAMIInstalled and !CAMI.PlayerHasAccess(LocalPlayer(), "Perfopus - View Metrics", nil) )
        or !LocalPlayer():IsSuperAdmin() ) then return end

        local source, tooltipstr, realm, time = net.ReadString(), net.ReadString(), net.ReadUInt(1), net.ReadFloat()
        PERFOPUS.ReceiveServerMetrics(source, tooltipstr, realm, time)
    end)
end



