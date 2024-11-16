local REALM_CL, REALM_SV = 0, 1


PERFOPUS.Bars = PERFOPUS.Bars or {}
local svcol, clcol = Color(0, 55, 255), Color(255, 200, 0)
local function CreateBar( panel, frac, perfdata )
    local grey = Color(125, 125, 125)
    local bar = vgui.Create("DPanel", panel)
    bar:Dock(TOP)
    bar.Fraction = frac or 0
    bar:DockMargin(6, 2, 6, 2)

    bar.perfdata = perfdata

    function bar:Paint( w, h )
        draw.RoundedBox( 5, 0, 0, w, h, grey )
        draw.RoundedBox( 5, 0, h*0.1, w*bar.Fraction, h*0.8, Color(Lerp(bar.Fraction, 0, 255), Lerp(bar.Fraction, 255 ,0), 50) )
        local textcol = ( bar.perfdata && bar.perfdata.realm &&
        (bar.perfdata.realm == REALM_CL && clcol) or (bar.perfdata.realm == REALM_SV && svcol) )
        or color_white
        draw.SimpleText( (self.perfdata && self.perfdata.source) or "Unknown", "DermaDefault", 4, 2, textcol )
        return true
    end


    if bar.perfdata && bar.perfdata.realm then
        local tooltip_func_metrics = {}
        for funcname, time in pairs(bar.perfdata.funcs or {}) do
            table.insert(tooltip_func_metrics, {name=funcname, time=math.Round(time, 4)})
        end

        if !table.IsEmpty(tooltip_func_metrics) then
            local ToolTipStr = ""
            table.sort(tooltip_func_metrics, function(a, b) return a.time > b.time end)

            for _, funcdata in ipairs(tooltip_func_metrics) do
                if funcdata.time == 0 then continue end
                ToolTipStr = ToolTipStr..funcdata.name.." ~ "..(funcdata.time*1000).."ms\n"
            end

            if #ToolTipStr != 0 then
                ToolTipStr = "Most Time Consuming:\n"..ToolTipStr

                bar:SetTooltip(ToolTipStr)
                bar:SetTooltipDelay(0)
            end
        end
    end

    table.insert(PERFOPUS.Bars, bar)
end


local readable_metrics_sv = {}
local last_server_frame_time = 0
PERFOPUS.ZOOM = CreateConVar("cl_perfopus_zoom", "8", FCVAR_ARCHIVE)
function PERFOPUS.RefreshMetrics( panel )
    if !panel or !panel:IsValid() then return end

    for _, bar in ipairs(PERFOPUS.Bars) do
        bar:Remove()
    end

    -- Tell server we want metrics from it
    -- PERFOPUS.OrderServerMetrics()


    local readable_metrics = PERFOPUS.GetReadableMetrics()
    table.Merge(readable_metrics, readable_metrics_sv)

    local sequential_tbl = {}
    for source, data in pairs(readable_metrics) do
        for funcname, functime in pairs(data.funcs) do
            data.funcs[funcname] = functime
        end
        data.source = source
        table.insert(sequential_tbl, data)
    end

    table.sort(sequential_tbl, function(a, b) return a.time > b.time end)

    for _, data in ipairs(sequential_tbl) do
        CreateBar( panel, math.Clamp(data.time/PERFOPUS.REFRESH_RATE:GetFloat()*PERFOPUS.ZOOM:GetFloat(), 0, 1), data )
    end

end


function PERFOPUS.ReceiveServerMetrics(readable_metrics, ftime)
    readable_metrics_sv = readable_metrics
    last_server_frame_time = ftime
end


PERFOPUS.StartedInMenu = PERFOPUS.StartedInMenu or false
local function StartPerfopus( panel )
    if !PERFOPUS.StartedInMenu && !PERFOPUS.Started then
        Derma_Query(
            "Start Perfopus? This cannot be undone for your current session, you will have to start a new map in order to stop Perfopus!",

            "Start Perfopus?",

            "Start",
            function()
                net.Start("sv_perfopus_start")
                net.SendToServer()
                PERFOPUS.StartedInMenu = true
            end,

            "Cancel"
        )
    end
end


conv.addToolMenu("Utilities", "Performance", "Perfopus", function( panel )

    local StartButton = panel:Button("Start Perfopus")
    StartButton.DoClick = function() StartPerfopus(panel) end

    panel:CheckBox("Freeze", "sh_perfopus_freeze")
    panel:NumSlider("Refresh Rate", "sh_perfopus_refresh_rate", 0.1, 5, 2)
    panel:NumSlider("Zoom", "cl_perfopus_zoom", 1, 10, 1)


    PERFOPUS.CurrentPanel = panel

    if PERFOPUS.Started then
        -- Started already, just show metrics
        StartPerfopus(panel)
    end

end)
