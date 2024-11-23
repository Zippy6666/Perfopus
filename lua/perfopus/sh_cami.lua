if ( !CAMI ) then return end

// Adds CAMI support: https://github.com/glua/CAMI

CAMI.RegisterPrivilege({
    Name = "Perfopus - View Metrics",
    MinAccess = "superadmin"
})