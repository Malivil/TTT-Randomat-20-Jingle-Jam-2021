local EVENT = {}

util.AddNetworkString("RdmtJingleJam2021Start")
util.AddNetworkString("RdmtJingleJam2021Stop")
util.AddNetworkString("RdmtJingleJam2021End")

CreateConVar("randomat_jinglejam2021_interval_min", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Minimum seconds between jams", 1, 60)
CreateConVar("randomat_jinglejam2021_interval_max", 60, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Maximum seconds between jams", 2, 120)
CreateConVar("randomat_jinglejam2021_duration", 5, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Weapon jam duration", 1, 30)
CreateConVar("randomat_jinglejam2021_chance", 0.25, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Weapon jam chance", 0.1, 1)

EVENT.Title = "Jingle Jam 2021"
EVENT.Description = "Periodically jams random players' weapons for a short time"
EVENT.id = "jinglejam2021"
EVENT.Categories = {"smallimpact"}

local function GetInterval()
    local interval_min = GetConVar("randomat_jinglejam2021_interval_min"):GetInt()
    local interval_max = GetConVar("randomat_jinglejam2021_interval_max"):GetInt()
    local interval
    if interval_min > interval_max then
        interval = interval_min
    else
        interval = math.random(interval_min, interval_max)
    end
    return interval
end

-- Only jam primary weapons and pistols
function EVENT:IsValidWeapon(weap)
    return IsValid(weap) and (weap.Kind == WEAPON_HEAVY or weap.Kind == WEAPON_PISTOL)
end

local timers = {}
function EVENT:JamWeapon(ply, weap)
    if not weap.OldPrimaryAttack then
        weap.OldPrimaryAttack = weap.PrimaryAttack
        weap.JammedMessage = false
        weap.PrimaryAttack = function(w, worldsnd)
            local has_delay = type(w.Primary.Delay) == "number"
            -- Workaround for the weapons that don't use the normal delay system: Just use a fixed delay time and don't check CanPrimaryAttack
            if has_delay then
                w:SetNextSecondaryFire(CurTime() + w.Primary.Delay)
                w:SetNextPrimaryFire(CurTime() + w.Primary.Delay)

                if not w:CanPrimaryAttack() then return end
            else
                w:SetNextSecondaryFire(CurTime() + 0.2)
                w:SetNextPrimaryFire(CurTime() + 0.2)
            end

            if not worldsnd then
                w:EmitSound("Weapon_Pistol.Empty", w.Primary.SoundLevel or 100)
            elseif SERVER then
                sound.Play("Weapon_Pistol.Empty", w:GetPos(), w.Primary.SoundLevel or 100)
            end

            -- Let the player know their weapon is jammed if we haven't told them already
            local owner = w:GetOwner()
            if IsPlayer(owner) and not w.JammedMessage then
                w.JammedMessage = true
                owner:PrintMessage(HUD_PRINTTALK, "Your weapon has jammed!")
                owner:PrintMessage(HUD_PRINTCENTER, "Your weapon has jammed!")
            end
        end

        local timerKey = "RdmtJingleJam2021StartDelay_" .. weap:EntIndex()
        table.insert(timers, timerKey)
        -- Let the client realize they have the weapon before telling them to jam it
        timer.Create(timerKey, 0.1, 1, function()
            net.Start("RdmtJingleJam2021Start")
            net.WriteString(WEPS.GetClass(weap))
            net.Send(ply)
        end)
    end
end

function EVENT:JamWeapons(ply)
    for _, w in ipairs(ply:GetWeapons()) do
        if self:IsValidWeapon(w) then
            self:JamWeapon(ply, w)
        end
    end
end

function EVENT:UnjamWeapon(ply, weap)
    if weap.OldPrimaryAttack then
        local timerKey = "RdmtJingleJam2021StartDelay_" .. weap:EntIndex()
        timer.Remove(timerKey)

        local weap_class = WEPS.GetClass(weap)
        weap.PrimaryAttack = weap.OldPrimaryAttack
        weap.OldPrimaryAttack = nil

        -- If the player knows their weapon was jammed, let them know they've unjammed it
        local owner = weap:GetOwner()
        if IsPlayer(owner) and weap.JammedMessage then
            owner:PrintMessage(HUD_PRINTTALK, "You have cleared your jammed weapon!")
            owner:PrintMessage(HUD_PRINTCENTER, "You have cleared your jammed weapon!")
        end

        net.Start("RdmtJingleJam2021Stop")
        net.WriteString(weap_class)
        net.Send(ply)
    end
end

function EVENT:UnjamWeapons(ply)
    for _, w in ipairs(ply:GetWeapons()) do
        self:UnjamWeapon(ply, w)
    end
end

function EVENT:Begin()
    local duration = GetConVar("randomat_jinglejam2021_duration"):GetInt()
    local chance = GetConVar("randomat_jinglejam2021_chance"):GetFloat()

    timer.Create("RdmtJingleJam2021JamCheck", GetInterval(), 0, function()
        timer.Stop("RdmtJingleJam2021JamCheck")

        local targets = {}
        -- Select random people
        for _, p in ipairs(self:GetAlivePlayers(true)) do
            if math.random() < chance then
                table.insert(targets, p)
            end
        end

        for _, p in ipairs(targets) do
            p:SetNWBool("RdmtJingleJam2021Jammed", true)

            -- Jam current weapons
            self:JamWeapons(p)
        end

        -- Jam when picking up weapon
        self:AddHook("WeaponEquip", function(weap, ply)
            if not self:IsValidWeapon(weap) or not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
            if not ply:GetNWBool("RdmtJingleJam2021Jammed", false) then return false end

            self:JamWeapon(ply, weap)
        end)

        -- Un-jam when dropping weapon
        self:AddHook("PlayerDroppedWeapon", function(ply, weap)
            if not self:IsValidWeapon(weap) or not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
            if not ply:GetNWBool("RdmtJingleJam2021Jammed", false) then return false end

            self:UnjamWeapon(ply, weap)
        end)

        timer.Create("RdmtJingleJam2021JamDuration", duration, 1, function()
            for _, p in ipairs(targets) do
                self:UnjamWeapons(p)
                p:SetNWBool("RdmtJingleJam2021Jammed", false)
            end

            timer.Adjust("RdmtJingleJam2021JamCheck", GetInterval())
            timer.Start("RdmtJingleJam2021JamCheck")
        end)
    end)
end

function EVENT:End()
    timer.Remove("RdmtJingleJam2021JamDuration")
    timer.Remove("RdmtJingleJam2021JamCheck")
    for _, k in ipairs(timers) do
        timer.Remove(k)
    end

    net.Start("RdmtJingleJam2021End")
    net.Broadcast()
end

function EVENT:GetConVars()
    local sliders = {}
    for _, v in ipairs({"chance", "interval_min", "interval_max", "duration"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = v == "chance" and 1 or 0
            })
        end
    end
    return sliders
end

Randomat:register(EVENT)