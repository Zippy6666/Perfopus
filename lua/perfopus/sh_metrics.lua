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
    util.AddNetworkString("OrderServerMetrics")
    util.AddNetworkString("SendServerMetrics")

    net.Receive("OrderServerMetrics", function(_, ply)
        if !ply:IsSuperAdmin() then return end

        local readable_metrics = PERFOPUS.GetReadableMetrics()
    
        -- Very expensive, I know
        net.Start("SendServerMetrics")
        net.WriteTable(readable_metrics)
        net.Send(ply)
    end)
end


if CLIENT then
    function PERFOPUS.OrderServerMetrics()
        if !LocalPlayer():IsSuperAdmin() then return end
        net.Start("OrderServerMetrics")
        net.SendToServer()
    end

    net.Receive("SendServerMetrics", function()
        if !LocalPlayer():IsSuperAdmin() then return end
        local readable_metrics = net.ReadTable()
        PERFOPUS.ReceiveServerMetrics(readable_metrics)
    end)
end



