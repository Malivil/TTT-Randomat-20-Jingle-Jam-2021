local plymeta = FindMetaTable("Player")
if not plymeta then return end

local EVENT = {}

util.AddNetworkString("RdmtBoxingDayBegin")

CreateConVar("randomat_boxingday_damage", 5, FCVAR_NONE, "Damage done by each punch", 1, 25)
CreateConVar("randomat_boxingday_chance", "0.33", FCVAR_NONE, "Percent chance a punched player will get knocked out", 0.0, 1.0)
CreateConVar("randomat_boxingday_timer", 3, FCVAR_NONE, "Time between being given gloves", 1, 30)
CreateConVar("randomat_boxingday_strip", 1, FCVAR_NONE, "The event strips your other weapons")
local knockout_duration = CreateConVar("randomat_boxingday_knockout_duration", 10, FCVAR_NONE, "Time punched player should be knocked down", 1, 60)

EVENT.Title = "Boxing Day"
EVENT.Description = "Boxing gloves for everyone!"
EVENT.id = "boxingday"
EVENT.Categories = {"item", "rolechange", "largeimpact"}

local knockout = Sound("knockout.mp3")

local function TransferRagdollDamage(rag, dmginfo)
    if not IsRagdoll(rag) then return end
    local ply = rag:GetNWEntity("RdmtBoxingRagdolledPly", nil)
    if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end

    -- Keep track of how much health they have left
    local damage = dmginfo:GetDamage()
    rag.playerHealth = rag.playerHealth - damage

    -- Kill the player if they run out of health
    if rag.playerHealth <= 0 then
        ply:RdmtBoxingRevive()

        local att = dmginfo:GetAttacker()
        local inflictor = dmginfo:GetInflictor()
        if not IsValid(inflictor) then
            inflictor = att
        end
        local dmg_type = dmginfo:GetDamageType()

        -- Use TakeDamage instead of Kill so it properly applies karma
        local dmg = DamageInfo()
        dmg:SetDamageType(dmg_type)
        dmg:SetAttacker(att)
        dmg:SetInflictor(inflictor)
        -- Use 10 so damage scaling doesn't mess with it. The worse damage factor (0.1) will still deal 1 damage after scaling a 10 down
        -- Karma ignores excess damage anyway
        dmg:SetDamage(10)
        dmg:SetDamageForce(Vector(0, 0, 1))

        ply:TakeDamageInfo(dmg)
    else
        ply:SetHealth(rag.playerHealth)
    end
end

function EVENT:HandleRoleWeapons(ply)
    local updated = false
    -- Convert all bad guys to traitors so we don't have to worry about fighting with special weapon replacement logic
    if (Randomat:IsTraitorTeam(ply) and ply:GetRole() ~= ROLE_TRAITOR) or Randomat:IsMonsterTeam(ply) or Randomat:IsIndependentTeam(ply) then
        Randomat:SetRole(ply, ROLE_TRAITOR)
        updated = true
    elseif Randomat:IsJesterTeam(ply) then
        Randomat:SetRole(ply, ROLE_INNOCENT)
        updated = true
    end

    -- Remove role weapons from anyone on the traitor team now
    if Randomat:IsTraitorTeam(ply) then
        self:StripRoleWeapons(ply)
    end
    return updated
end

function EVENT:Begin()
    local duration = knockout_duration:GetInt()
    net.Start("RdmtBoxingDayBegin")
    net.WriteInt(duration, 8)
    net.Broadcast()

    for _, v in ipairs(self:GetAlivePlayers()) do
        self:HandleRoleWeapons(v)
    end
    SendFullStateUpdate()

    local strip = GetConVar("randomat_boxingday_strip"):GetBool()
    local weaponid = "weapon_randomat_boxgloves"
    timer.Create("RandomatBoxingGlovesTimer", GetConVar("randomat_boxingday_timer"):GetInt(), 0, function()
        local updated = false
        for _, ply in ipairs(self:GetAlivePlayers()) do
            if strip then
                for _, wep in ipairs(ply:GetWeapons()) do
                    local weaponclass = WEPS.GetClass(wep)
                    if weaponclass ~= weaponid then
                        ply:StripWeapon(weaponclass)
                    end
                end

                -- Reset FOV to unscope
                ply:SetFOV(0, 0.2)
            end

            if not ply:HasWeapon(weaponid) then
                ply:Give(weaponid)
            end

            -- Workaround the case where people can respawn as Zombies while this is running
            updated = updated or self:HandleRoleWeapons(ply)
        end

        -- If anyone's role changed, send the update
        if updated then
            SendFullStateUpdate()
        end
    end)

    self:AddHook("PlayerCanPickupWeapon", function(ply, wep)
        if not strip then return end
        return IsValid(wep) and WEPS.GetClass(wep) == weaponid
    end)

    self:AddHook("EntityTakeDamage", function(ent, dmginfo)
        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end

        -- Don't transfer damage from jester-like players
        if att:ShouldActLikeJester() then return end

        -- Override the weapon damage
        dmginfo:SetDamage(GetConVar("randomat_boxingday_damage"):GetInt())

        local ply, rag
        if IsRagdoll(ent) then
            rag = ent
            ply = ent:GetNWEntity("RdmtBoxingRagdolledPly", nil)
        elseif IsPlayer(ent) then
            ply = ent
            rag = ply:GetNWEntity("RdmtBoxingRagdoll", nil)
        end

        if not IsValid(rag) then return end
        if not IsValid(ply) or not ply:GetNWBool("RdmtBoxingKnockedOut", false) then return end
        if att == ply then return end

        -- Transfer damage from the knockout ragdoll to the real player
        TransferRagdollDamage(rag, dmginfo)
    end)
end

function EVENT:End()
    for _, v in player.Iterator() do
        if v:GetNWBool("RdmtBoxingKnockedOut", false) then
            v:RdmtBoxingRevive()
        end
        v:SetNWInt("RdmtBoxingKnockoutEndTime", -1)
        timer.Remove("RdmtBoxingKnockout_" .. v:SteamID64())
    end
    timer.Remove("RandomatBoxingGlovesTimer")
end

function EVENT:Condition()
    -- Make sure the medium exists since we're using that particle
    return ConVarExists("ttt_medium_enabled")
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"knockout_duration", "timer", "damage", "chance"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = v == "chance" and 2 or 0
            })
        end
    end

    local checks = {}
    for _, v in ipairs({"strip"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    return sliders, checks
end

Randomat:register(EVENT)

function plymeta:RdmtBoxingKnockout()
    local boxerRagdoll = self:GetNWEntity("RdmtBoxingRagdoll", nil)
    if IsValid(boxerRagdoll) then return end

    self:SetNWBool("RdmtBoxingKnockedOut", true)
    self:SelectWeapon("weapon_ttt_unarmed")
    self:EmitSound(knockout)

    -- Create ragdoll and lock their view
    local ragdoll = ents.Create("prop_ragdoll")
    ragdoll:SetNWEntity("RdmtBoxingRagdolledPly", self)
    ragdoll.playerHealth = self:Health()
    ragdoll.playerColor = self:GetPlayerColor()
    -- Don't let the red matter bomb destroy this ragdoll
    ragdoll.WYOZIBHDontEat = true

    local velocity = self:GetVelocity()
    ragdoll:SetPos(self:GetPos())
    ragdoll:SetModel(self:GetModel())
    ragdoll:SetSkin(self:GetSkin())
    for _, value in pairs(self:GetBodyGroups()) do
        ragdoll:SetBodygroup(value.id, self:GetBodygroup(value.id))
    end
    ragdoll:SetAngles(self:GetAngles())
    ragdoll:SetColor(self:GetColor())
    CORPSE.SetPlayerNick(ragdoll, self)
    ragdoll:Spawn()
    ragdoll:Activate()

    -- So their player ent will match up (position-wise) with where their ragdoll is.
    self:SetParent(ragdoll)
    -- Set velocity for each piece of the ragdoll
    for i = 1, ragdoll:GetPhysicsObjectCount() do
        local phys_obj = ragdoll:GetPhysicsObjectNum(i)
        if phys_obj then
            phys_obj:SetVelocity(velocity)
        end
    end

    self:SetNWEntity("RdmtBoxingRagdoll", ragdoll)
    self:Spectate(OBS_MODE_CHASE)
    self:SpectateEntity(ragdoll)

    -- The diguiser stays in their hand so hide it from view
    self:DrawViewModel(false)
    self:DrawWorldModel(false)

    -- Timer to revive
    local duration = knockout_duration:GetInt()
    self:SetNWInt("RdmtBoxingKnockoutEndTime", CurTime() + duration)
    timer.Create("RdmtBoxingKnockout_" .. self:SteamID64(), duration, 1, function()
        if not self:GetNWBool("RdmtBoxingKnockedOut", false) then return end
        self:RdmtBoxingRevive()
    end)
end

function plymeta:RdmtBoxingRevive()
    local boxerRagdoll = self:GetNWEntity("RdmtBoxingRagdoll", nil)
    if not IsValid(boxerRagdoll) then return end

    self:SetNWBool("RdmtBoxingKnockedOut", false)
    self:SetNWInt("RdmtBoxingKnockoutEndTime", 0)

    -- Unragdoll
    -- Set these so players don't get their role weapons given back if they've already used them
    self.Resurrecting = true
    self.DeathRoleWeapons = nil
    self:SpectateEntity(nil)
    self:UnSpectate()
    self:SetParent()
    self:Spawn()
    self:SetPos(boxerRagdoll:GetPos())
    self:SetVelocity(boxerRagdoll:GetVelocity())
    local yaw = boxerRagdoll:GetAngles().yaw
    self:SetAngles(Angle(0, yaw, 0))
    self:SetModel(boxerRagdoll:GetModel())
    self:SetPlayerColor(boxerRagdoll.playerColor)

    -- Let weapons be seen again
    self:DrawViewModel(true)
    self:DrawWorldModel(true)

    local newhealth = boxerRagdoll.playerHealth
    if newhealth <= 0 then
        newhealth = 1
    end
    self:SetHealth(newhealth)
    SetRoleMaxHealth(self)

    SafeRemoveEntity(boxerRagdoll)
    self:SetNWEntity("RdmtBoxingRagdoll", nil)
end