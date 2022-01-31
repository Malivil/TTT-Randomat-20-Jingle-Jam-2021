local plymeta = FindMetaTable("Player")
if not plymeta then return end
local SetMDL = FindMetaTable("Entity").SetModel
if not SetMDL then return end

local EVENT = {}

CreateConVar("randomat_hellosanta_blocklist", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The comma-separated list of weapon IDs to not give out")

EVENT.Title = "Hello, Santa! It's me! Santa!"
EVENT.Description = "All players are turned into santa and given a christmas cannon"
EVENT.id = "hellosanta"

local oldPlayerModels = {}

function EVENT:HandleRoleWeapons(ply)
    -- Convert all bad guys to traitors so we don't have to worry about fighting with special weapon replacement logic
    if (Randomat:IsTraitorTeam(ply) and ply:GetRole() ~= ROLE_TRAITOR) or Randomat:IsMonsterTeam(ply) or Randomat:IsIndependentTeam(ply) then
        Randomat:SetRole(ply, ROLE_TRAITOR)
        self:StripRoleWeapons(ply)
    elseif Randomat:IsJesterTeam(ply) then
        Randomat:SetRole(ply, ROLE_INNOCENT)
        self:StripRoleWeapons(ply)
    -- If santa or other special detectives are in the round we make them a normal detective
    elseif Randomat:IsDetectiveLike(ply) then
        Randomat:SetRole(ply, ROLE_DETECTIVE)
        self:StripRoleWeapons(ply)
    end
end

function EVENT:Begin()
    for _, v in ipairs(self:GetAlivePlayers()) do
        self:HandleRoleWeapons(v)
        v:Give("weapon_randomat_christmas_cannon")
        v:SetNWBool("RdmtXmasCannonHasAmmo", true)
        oldPlayerModels[v:SteamID64()] = v:GetModel()
        SetMDL(v, "models/player/christmas/santa.mdl")
        v:RdmtResetSantaGifts()
    end
    SendFullStateUpdate()
end

function EVENT:End()
    for _, v in ipairs(self:GetAlivePlayers()) do
        SetMDL(v, oldPlayerModels[v:SteamID64()])
        v:RdmtResetSantaGifts()
    end
end

Randomat:register(EVENT)

function plymeta:RdmtCheckSantaGift(sender)
    if not IsValid(sender) then return false end

    if not self.giftsReceived then
        self.giftsReceived = {}
    end

    local sid = sender:SteamID64()
    if self.giftsReceived[sid] then
        self:PrintMessage(HUD_PRINTTALK, "You have already received a gift from " .. sender:Nick() .. "!")
        return false
    elseif sid == self:SteamID64() then
        self:PrintMessage(HUD_PRINTTALK, "You cannot open a gift from yourself!")
        return false
    else
        self.giftsReceived[sid] = true
        return true
    end
end

function plymeta:RdmtUndoSantaGift(sender)
    self.giftsReceived[sender:SteamID64()] = false
end

function plymeta:RdmtResetSantaGifts()
    self.giftsReceived = {}
end