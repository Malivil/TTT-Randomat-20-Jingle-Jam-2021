local EVENT = {}

util.AddNetworkString("RdmtJingleJam2021Start")
util.AddNetworkString("RdmtJingleJam2021Stop")

CreateConVar("randomat_jinglejam2021_interval_min", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Minimum seconds between jams", 1, 60)
CreateConVar("randomat_jinglejam2021_interval_max", 60, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Maximum seconds between jams", 2, 120)
CreateConVar("randomat_jinglejam2021_duration", 5, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Weapon jam duration", 1, 30)
CreateConVar("randomat_jinglejam2021_chance", 0.25, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Weapon jam chance", 0.1, 1)

EVENT.Title = "Jingle Jam 2021"
EVENT.Description = "Jingle all the way!"
EVENT.id = "jinglejam2021"

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

function EVENT:Begin()
    local duration = GetConVar("randomat_jinglejam2021_duration"):GetInt()
    local chance = GetConVar("randomat_jinglejam2021_chance"):GetFloat()

    timer.Create("RdmtJingleJam2021JamCheck", GetInterval(), 0, function()
        timer.Pause("RdmtJingleJam2021JamCheck")

        local targets = {}
        -- Select random people
        for _, p in ipairs(self:GetAlivePlayers(true)) do
            if math.random() < chance then
                table.insert(targets, p)
            end
        end

        for _, p in ipairs(targets) do
            p:SetNWBool("RdmtJingleJam2021Jammed", true)
            net.Start("RdmtJingleJam2021Start")
            net.Send(p)
        end

        -- TODO: Credit: https://steamcommunity.com/sharedfiles/filedetails/?id=849612809
        --function activeWeapon:PrimaryAttack(worldsnd)
		--	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
		--	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
		--
		--	if not self:CanPrimaryAttack() then return end
		--
		--	if not worldsnd then
		--		self:EmitSound("Weapon_Pistol.Empty", self.Primary.SoundLevel )
		--	elseif SERVER then
		--		sound.Play("Weapon_Pistol.Empty", self:GetPos(), self.Primary.SoundLevel)
		--	end
		--end
        -- TODO: Jam current weapon
        -- TODO: Un-jam/Jam when switching weapons
        -- TODO: Un-jam when dropping weapon
        -- TODO: All of this on the client

        timer.Create("RdmtJingleJam2021JamDuration", duration, 1, function()
            -- TODO: Un-jam

            for _, p in ipairs(targets) do
                p:SetNWBool("RdmtJingleJam2021Jammed", false)
            end

            timer.Adjust("RdmtJingleJam2021JamCheck", GetInterval())
            timer.UnPause("RdmtJingleJam2021JamCheck")
        end)
    end)
end

function EVENT:End()
    timer.Remove("RdmtJingleJam2021JamCheck")
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