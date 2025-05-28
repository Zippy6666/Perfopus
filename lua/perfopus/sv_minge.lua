local help = "How much execution time per refresh rate is a player allowed to waste before some of their entities are removed."

PERFOPUS.perfopus_anti_minge = CreateConVar("perfopus_anti_minge", "0", FCVAR_ARCHIVE)
PERFOPUS.perfopus_max_minge_time = CreateConVar("perfopus_max_minge_time", "2", FCVAR_ARCHIVE, help)
PERFOPUS.perfopus_minge_n_ents_to_rm = CreateConVar("perfopus_minge_n_ents_to_rm", "3", FCVAR_ARCHIVE)

local mingeStats = {}

-- Look for players that lag the server with LUA
function PERFOPUS.MingeThink(data)
    if game.SinglePlayer() then return end
    if !PERFOPUS.perfopus_anti_minge:GetBool() then return end

    if IsValid(data.ent) then
        local creator = data.ent:GetCreator()

        if IsValid(creator) then
            -- Track player who created entity
            mingeStats[creator] = mingeStats[creator] or {}

            -- Track time
            mingeStats[creator].time = (mingeStats[creator].time && mingeStats[creator].time+data.time) or data.time

            -- Track entities
            mingeStats[creator].ents = mingeStats[creator].ents or {}
            data.ent:CONV_MapInTable(mingeStats[creator].ents)
        end
    end
end

function PERFOPUS.HandleMinges()
    if game.SinglePlayer() then return end
    if !PERFOPUS.perfopus_anti_minge:GetBool() then return end

    for ply, data in pairs(mingeStats) do

        -- Remove some of players laggy entities
        if data.time > PERFOPUS.perfopus_max_minge_time:GetFloat()*PERFOPUS.REFRESH_RATE:GetFloat() then
            local nRemoved = 0

            for ent in pairs(data.ents) do
                if nRemoved < PERFOPUS.perfopus_minge_n_ents_to_rm:GetInt() then
                    local entname = hook.Run("GetDeathNoticeEntityName", ent) or "no name"

                    MsgN("[PERFOPUS] Removing "..ply:GetName().."'s '"..entname.."' due to lag.")
                    conv.sendGModHint( ply, "[PERFOPUS] Your entity '"..(entname).."' will be removed due to lag.", 1, 3 )
                    
                    ent:Remove()
                    nRemoved = nRemoved + 1
                else
                    break
                end
            end

        end
    end
end

function PERFOPUS.ResetMingeStats()
    if game.SinglePlayer() then return end
    if !PERFOPUS.perfopus_anti_minge:GetBool() then return end

    mingeStats={}
end