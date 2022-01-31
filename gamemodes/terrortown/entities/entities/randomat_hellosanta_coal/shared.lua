AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
    self:SetModel("models/props_phx/misc/potato.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetModelScale(2)
    self:Activate()
    self.antiSpam = CurTime()
end

if SERVER then
    function ENT:Think()
        self.lifetime = self.lifetime or CurTime() + 20
        if CurTime() > self.lifetime then
            self:Remove()
        end
    end

    function ENT:PhysicsCollide(data, phys)
        local ent = data.HitEntity
        local owner = self:GetOwner()

        if not IsValid(ent) or not ent:IsPlayer() or not ent:IsActive() then return end
        -- Don't let this kill someone if it's just being carried by a magneto stick
        if IsValid(phys) and phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) then return end
        if data.Speed < 300 then return end -- The coal has to be going fast enough to kill someone

        if CurTime() <= self.antiSpam then return end

        self.antiSpam = CurTime() + 0.5

        ent:TakeDamage(ent:Health(), owner, self)
        self.lifetime = CurTime() + 3 -- Leave the coal around for a few more seconds then remove it
        if not owner:IsSameTeam(ent) then
            owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " was naughty and your ammo has been refunded.")
            owner:SetNWBool("RdmtXmasCannonHasAmmo", true)
        else
            owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " was nice and the christmas cannon has been disabled.")
        end
    end
end