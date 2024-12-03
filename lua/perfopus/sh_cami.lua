hook.Add("Initialize", "PerfopusCAMI", function()

    PERFOPUS.CAMI_Init_Ran = true

    if SERVER then
        RunConsoleCommand("sh_perfopus_cami_installed", (PERFOPUS.CAMIInstalled && "1") or "0")
    end

    PERFOPUS.CAMIInstalled = PERFOPUS.CAMIInstalled or GetConVar("sh_perfopus_cami_installed"):GetBool()

    if ( !PERFOPUS.CAMIInstalled ) then
        conv.devPrint(Color(255,0,0), "Did not find CAMI for perfopus.")
        return
    end

    // Adds CAMI support: https://github.com/glua/CAMI
    CAMI.RegisterPrivilege({
        Name = "Perfopus - View Metrics",
        MinAccess = "superadmin"
    })
    
    conv.devPrint("Registered CAMI for perfopus!")

end)


if PERFOPUS.CAMI_Init_Ran then
    hook.Run("Initialize", "PerfopusCAMI")
end

