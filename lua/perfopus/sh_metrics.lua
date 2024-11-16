-- Should contain: Function / hook name, source, exec time
PERFOPUS.Metrics = PERFOPUS.Metrics or {}


function PERFOPUS.TakeMeasurement( time, name, source )
    PERFOPUS.Metrics[source] = PERFOPUS.Metrics[source] or {}
    PERFOPUS.Metrics[source][name] = PERFOPUS.Metrics[source][name] && PERFOPUS.Metrics[source][name] + time or time
end


function PERFOPUS.GetReadableMetrics()

    local srcs_metrics = {}
    for src, functbl in pairs(PERFOPUS.Metrics) do
        srcs_metrics[src] = {funcs=functbl}
        for funcname, time in pairs(functbl) do
            srcs_metrics[src].time = srcs_metrics[src].time && srcs_metrics[src].time+time or time
        end
    end

    local times_ordered = {}
    for k, v in pairs(srcs_metrics) do
        table.insert(times_ordered, v.time)
    end
    table.sort(times_ordered, function(a, b) return a > b end)


    return srcs_metrics, times_ordered

end


if SERVER then
    util.AddNetworkString("OrderServerMetrics")
end

if CLIENT then
    function PERFOPUS.OrderServerMetrics()


    end
end



