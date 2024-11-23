local REALM_CL, REALM_SV = 0, 1
local source_cache = {}

-- The paths which are considered native, and so are filtered out of the metrics list
-- Paths are normalized during checks so are cross-platform safe
local native_paths = {
    ["lua/includes/"] = true,
    ["lua/derma/derma.lua"] = true,
    ["lua/derma/derma_menus.lua"] = true,
    ["lua/vgui/vgui.lua"] = true,
    ["lua/vgui/dnumberscratch.lua"] = true,
    ["lua/vgui/dframe.lua"] = true,
    ["lua/vgui/dtextentry.lua"] = true,
    ["lua/vgui/dbutton.lua"] = true,
    ["lua/vgui/dpanel.lua"] = true,
    ["lua/vgui/dcheckbox.lua"] = true,
    ["lua/vgui/dlabel.lua"] = true,
    ["lua/vgui/dslider.lua"] = true,
    ["lua/vgui/dscrollpanel.lua"] = true,
    ["lua/vgui/dpropertysheet.lua"] = true,
    ["lua/vgui/dcombobox.lua"] = true,
    ["lua/postprocess/"] = true,
    ["lua/menu/menu.lua"] = true,
    ["gamemodes/base/"] = true,
    ["gamemodes/sandbox/"] = true,
    ["gamemodes/darkrp/"] = true,
    ["lua/matproxy/"] = true,
    ["lua/skins/"] = true
}

local ADDON_PATTERNS = {
    "^.*/addons/",
    "^.*workshop/content/4000/"
}


PERFOPUS.HIDE_NATIVE = CreateConVar("cl_perfopus_hide_native", "0", FCVAR_ARCHIVE)
cvars.AddChangeCallback("cl_perfopus_hide_native", function()
    table.Empty(source_cache)
    if IsValid(PERFOPUS.CurrentPanel) then
        timer.Simple(0, function()
            -- Refresh the list whenever the cvar changes
            PERFOPUS.RefreshMetrics(PERFOPUS.CurrentPanel)
        end)
    end
end, "perfopus_refresh")


PERFOPUS.SHOWING_METRICS = CreateClientConVar("cl_perfopus_showing_metrics", "0", false, true)


function PERFOPUS.IsAddonSource(src)
    if source_cache[src] ~= nil then
        return source_cache[src]
    end

    src = src:lower():gsub("\\", "/")

    for _, pattern in ipairs(ADDON_PATTERNS) do
        if string.match(src, pattern) then
            source_cache[src] = true
            return true
        end
    end

    for path in pairs(native_paths) do
        if string.find(src, path) then
            source_cache[src] = false
            return false
        end
    end

    source_cache[src] = true
    return true
end

function PERFOPUS.FilterMetrics(metrics)
    if not PERFOPUS.HIDE_NATIVE:GetBool() then
        return metrics
    end

    local filtered = {}
    for src, data in pairs(metrics) do
        if PERFOPUS.IsAddonSource(src) then
            filtered[src] = data
        end
    end
    return filtered
end

-- Clear cache when Perfopus starts/stops
function PERFOPUS.ClearSourceCache()
    table.Empty(source_cache)
end

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
PERFOPUS.ZOOM = CreateConVar("cl_perfopus_zoom", "2", FCVAR_ARCHIVE)
function PERFOPUS.RefreshMetrics( panel )
    if !panel or !panel:IsValid() then return end
    if !PERFOPUS.SHOWING_METRICS:GetBool() then return end

    for _, bar in ipairs(PERFOPUS.Bars) do
        bar:Remove()
    end

    local readable_metrics = PERFOPUS.GetReadableMetrics()

    -- Filter metrics if hide native is enabled
    readable_metrics = PERFOPUS.FilterMetrics(readable_metrics)
    readable_metrics_sv = PERFOPUS.FilterMetrics(readable_metrics_sv)

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


function PERFOPUS.ReceiveServerMetrics(readable_metrics)
    readable_metrics_sv = readable_metrics
end


local function StartPerfopus( panel )
    if PERFOPUS.SHOWING_METRICS:GetBool() then return end


    if PERFOPUS.Started then

        RunConsoleCommand("cl_perfopus_showing_metrics", "1")
        PERFOPUS.RefreshMetrics( panel )

    else
        Derma_Query(
            "Start Perfopus? You will have to start a new map in order to stop Perfopus! You will experience worse performance while it is running.",

            "Start Perfopus?",

            "Start",
            function()

                if LocalPlayer():IsSuperAdmin() then
                    net.Start("sv_perfopus_start")
                    net.SendToServer()
                else
                    RunConsoleCommand("cl_perfopus_start")
                end

                PERFOPUS.ClearSourceCache()

                RunConsoleCommand("cl_perfopus_showing_metrics", "1")
                
            end,

            "Cancel"
        )
    end
end


conv.addToolMenu("Utilities", "Performance", "Perfopus", function( panel )

    RunConsoleCommand("cl_perfopus_showing_metrics", "0")

    panel:Help("Perfopus Performance Metrics")

    local StartButton = panel:Button("Start Perfopus")
    StartButton.DoClick = function() StartPerfopus(panel) end

    panel:CheckBox("Freeze", "sh_perfopus_freeze")
    panel:CheckBox("Hide Native GMod Activity", "cl_perfopus_hide_native")
    panel:NumSlider("Refresh Rate", "sh_perfopus_refresh_rate", 0.1, 5, 2)
    panel:NumSlider("Zoom", "cl_perfopus_zoom", 0.5, 10, 1)

    PERFOPUS.CurrentPanel = panel

end)
