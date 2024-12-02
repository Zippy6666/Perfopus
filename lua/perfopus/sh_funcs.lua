function PERFOPUS.MakeToolTipString( funcs )

    /*
        Takes a table of function names to execution time key-value pairs, and makes a readable text that can be applied as a tooltip
    */

    local tooltip_func_metrics = {}

    for funcname, time in pairs(funcs or {}) do
        table.insert(tooltip_func_metrics, {name=funcname, time=math.Round(time, 4)})
    end

    if table.IsEmpty(tooltip_func_metrics) then return "" end

    local ToolTipStr = ""
    table.sort(tooltip_func_metrics, function(a, b) return a.time > b.time end)

    for _, funcdata in ipairs(tooltip_func_metrics) do
        if funcdata.time == 0 then continue end
        ToolTipStr = ToolTipStr..funcdata.name.." ~ "..(funcdata.time*1000).."ms\n"
    end

    return ToolTipStr

end