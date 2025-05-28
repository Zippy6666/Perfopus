-- Look for players that lag the server with LUA
function PERFOPUS.MingeThink(superadmin, luafsrc, data)
    -- print("------", luafsrc, "------")
    -- PrintTable(data)
    -- print("----------------------------------")

    if IsValid(data.ent) then
        local creator = data.ent:GetCreator()
        if IsValid(creator) then
            MsgN("[PERFOPUS] ", creator:GetName(), " wasted ", data.time, " seconds of exec time.")
        end
    end
end