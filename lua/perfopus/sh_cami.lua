hook.Add("Initialize", "PerfopusCAMI", function()

    PERFOPUS.CAMI_Init_Ran = true

    PERFOPUS.CAMIInstalled = PERFOPUS.CAMIInstalled or (CLIENT && CAMI)

    if ( !PERFOPUS.CAMIInstalled ) then return end

    // Adds CAMI support: https://github.com/glua/CAMI
    CAMI.RegisterPrivilege({
        Name = "Perfopus - View Metrics",
        MinAccess = "superadmin"
    })
    
end)


if PERFOPUS.CAMI_Init_Ran then
    hook.Run("Initialize", "PerfopusCAMI")
end

