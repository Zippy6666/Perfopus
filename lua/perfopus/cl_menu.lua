local REALM_CL, REALM_SV = 0, 1


PERFOPUS.Bars = PERFOPUS.Bars or {}
local svcol, clcol = Color(0, 55, 255), Color(255, 200, 0)
local function CreateBar( panel, frac, perfdata )
    local grey = Color(200, 200, 200)
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
        local ToolTipStr = bar.perfdata.realm==REALM_CL && "[CLIENT]\n" or "[SERVER]\n"
        ToolTipStr = ToolTipStr.."Functions:\n"

        for funcname, time in pairs(bar.perfdata.funcs or {}) do
            ToolTipStr = ToolTipStr..funcname.." ~ "..time.."\n"
        end

        bar:SetTooltip(ToolTipStr)
        bar:SetTooltipDelay(0)
    end

    table.insert(PERFOPUS.Bars, bar)
end


local readable_metrics_sv = {}
local last_server_frame_time = 0.1
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
        CreateBar( panel, math.Clamp(data.time/0.05, 0, 1), data )
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
            end,

            "Cancel"
        )
    end


    PERFOPUS.StartedInMenu = true
end


conv.addToolMenu("Utilities", "Performance", "Perfopus", function( panel )

    panel:NumSlider("Refresh Rate", "sh_perfopus_refresh_rate", 0.1, 5, 2)

    local StartButton = panel:Button("Start Perfopus")
    StartButton.DoClick = function() StartPerfopus(panel) end

    PERFOPUS.CurrentPanel = panel

    if PERFOPUS.Started then
        -- Started already, just show metrics
        StartPerfopus(panel)
    end

end)
