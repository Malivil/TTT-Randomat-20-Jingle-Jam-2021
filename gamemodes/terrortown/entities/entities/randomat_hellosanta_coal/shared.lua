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
        if data.Speed < 300 then return end -- The coal has to be going fast enough to kill someone

        if CurTime() <= self.antiSpam then return end

        self.antiSpam = CurTime() + 0.5

        ent:TakeDamage(ent:Health(), owner, self)
        self.lifetime = CurTime() + 3 -- Leave the coal around for a few more seconds then remove it
        if Randomat:IsTraitorTeam(ent) or (Randomat:IsJesterTeam(ent) and GetConVar("randomat_hellosanta_jesters_are_naughty"):GetBool()) or (Randomat:IsIndependentTeam(ent) and GetConVar("randomat_hellosanta_independents_are_naughty"):GetBool()) then
            owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " was naughty and your ammo has been refunded.")
            owner:SetNWBool("XmasCannonHasAmmo", true)
        else
            owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " was nice and the christmas cannon has been disabled.")
        end
    end
end