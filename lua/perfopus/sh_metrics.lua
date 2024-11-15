-- Should contain: Function / hook name, addon name / source, exec time
PERFOPUS.Metrics = PERFOPUS.Metrics or {}


function PERFOPUS.TakeMeasurement( time, name, source )
    PERFOPUS.Metrics[source] = PERFOPUS.Metrics[source] or {}
    PERFOPUS.Metrics[source][name] = PERFOPUS.Metrics[source][name] && PERFOPUS.Metrics[source][name] + time or time
end


function PERFOPUS.ShowMetrics()

    local addons_metrics = {}

    for addon, functbl in pairs(PERFOPUS.Metrics) do
        for funcname, time in pairs(functbl) do
            addons_metrics[addon] = addons_metrics[addon] && addons_metrics[addon] + time or time
        end
    end

    table.sort( addons_metrics, function(a, b) return a[2] > b[2] end )
    PrintTable(addons_metrics)

end


concommand.Add(SERVER && "sv_perfopus_show" or "cl_perfopus_show", function()
    if SERVER then
        RunConsoleCommand("cl_perfopus_show")
    end

    PERFOPUS.ShowMetrics()
end)