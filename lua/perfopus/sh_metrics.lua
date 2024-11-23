-- Should contain: Function / hook name, source, exec time
PERFOPUS.Metrics = PERFOPUS.Metrics or {}


function PERFOPUS.TakeMeasurement( time, name, source )
    PERFOPUS.Metrics[source] = PERFOPUS.Metrics[source] or {}
    PERFOPUS.Metrics[source][name] = PERFOPUS.Metrics[source][name] && PERFOPUS.Metrics[source][name] + time or time
end


local REALM_CL, REALM_SV = 0, 1
function PERFOPUS.GetReadableMetrics()

    local srcs_metrics = {}
    for src, functbl in pairs(PERFOPUS.Metrics) do
        srcs_metrics[src] = {funcs=functbl, realm=SERVER && REALM_SV or REALM_CL }
        for funcname, time in pairs(functbl) do
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
        if ( ( CAMI and !CAMI.PlayerHasAccess(LocalPlayer(), "Perfopus - View Metrics", nil) ) or !LocalPlayer():IsSuperAdmin() ) then return end

        local readable_metrics = net.ReadTable()
        PERFOPUS.ReceiveServerMetrics(readable_metrics)
    end)
end



