local REALM_CL, REALM_SV = 0, 1


PERFOPUS.Bars = PERFOPUS.Bars or {}
local svcol, clcol = Color(0, 0, 255), Color(255, 255, 0)
local function CreateBar( panel, frac, perfdata )
    local grey = Color(200, 200, 200)
    local bar = vgui.Create("DPanel", panel)
    bar:Dock(TOP)
    bar.frac = frac or 0
    bar:DockMargin(6, 2, 6, 2)

    bar.perfdata = perfdata

    function bar:Paint( w, h )
        draw.RoundedBox( 5, 0, 0, w, h, grey )
        draw.RoundedBox( 5, 0, h*0.1, w*bar.frac, h*0.8, Color(Lerp(bar.frac, 0, 255), Lerp(bar.frac, 255 ,0), 50) )
        local textcol = ( bar.perfdata && bar.perfdata.realm &&
        (bar.perfdata.realm == REALM_CL && clcol) or (bar.perfdata.realm == REALM_SV && svcol) )
        or color_white
        draw.SimpleText( (self.perfdata && self.perfdata.source) or "Unknown", "DermaDefault", 4, 2, textcol )
        return true
    end


    if bar.perfdata then
        local ToolTipStr = REALM_CL && "[CLIENT]\n" or "[SERVER]\n"
        ToolTipStr = ToolTipStr.."Functions:\n"

        for funcname, time in pairs(bar.perfdata.funcs or {}) do
            ToolTipStr = ToolTipStr..funcname.." -> "..time.."\n"
        end

        bar:SetTooltip(ToolTipStr)
        bar:SetTooltipDelay(0)
    end

    table.insert(PERFOPUS.Bars, bar)
end


local function RefreshMetrics( panel )
    for _, bar in ipairs(PERFOPUS.Bars) do
        bar:Remove()
    end

    -- Tell server we want metrics from it
    PERFOPUS.OrderServerMetrics()

    local readable_metrics, times_ordered = PERFOPUS.GetReadableMetrics()
    local largest_exec_time
    for _, time in ipairs(times_ordered) do
        if !largest_exec_time then
            largest_exec_time = time
        end

        local perfdata
        for source, data in pairs(readable_metrics) do
            if data.time == time then
                perfdata = table.Copy(data)
                perfdata.source = source
                perfdata.realm = REALM_CL
                break
            end
        end
            
        CreateBar( panel, time/largest_exec_time, perfdata )
    end
end


local function StartPerfopus( panel )
    Derma_Query(
        "Start Perfopus? This cannot be undone for your current session, you will have to start a new map in order to stop Perfopus!",

        "Start Perfopus?",

        "Start",
        function()
            net.Start("sv_perfopus_hooks")
            net.SendToServer()
        end,

        "Cancel"
    )

    if panel && panel:IsValid() then
        RefreshMetrics(panel)

        timer.Create("PERFOPUS", 2, 0, function()
            if panel:IsValid() then
                RefreshMetrics(panel)
            else
                timer.Remove("PERFOPUS")
            end
        end)
    end
end


conv.addToolMenu("Utilities", "Performance", "Perfopus", function( panel )


    local StartButton = panel:Button("Start Perfopus")
    StartButton.DoClick = function() StartPerfopus(panel) end

end)
