--[[=========================== CONV MESSAGE START ===========================]]--
MissingConvMsg2 = CLIENT && function()

    Derma_Query(
        "This server does not have Zippy's Library installed, addons will function incorrectly!",

        "ZIPPY'S LIBRARY MISSING!",
        
        "Get Zippy's Library",

        function()
            gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3146473253")
        end,

        "Close"
    )

end or nil

hook.Add("PlayerInitialSpawn", "MissingConvMsg2", function( ply )

    if file.Exists("autorun/conv.lua", "LUA") then return end

    local sendstr = 'MissingConvMsg2()'
    ply:SendLua(sendstr)

end)
--[[============================ CONV MESSAGE END ============================]]--

PERFOPUS = PERFOPUS or {}


PERFOPUS.CAMIInstalled = SERVER && file.Exists("autorun/sh_cami.lua", "LUA")
PERFOPUS.CAMIInstalledCvar = CreateConVar("sh_perfopus_cami_installed", "0", FCVAR_REPLICATED, "Do not change this.")


conv.includeDir( "perfopus" )