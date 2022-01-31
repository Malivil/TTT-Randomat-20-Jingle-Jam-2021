AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
    self:SetModel("models/katharsmodels/present/type-2/big/present2.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:Activate()
    self.nextUse = CurTime()

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(10)
    end
end

if SERVER then
    function ENT:Use(activator)
        if CurTime() > self.nextUse then
            if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end
            self.nextUse = CurTime() + 0.5

            local owner = self:GetOwner()
            if activator:RdmtCheckSantaGift(owner) then
                local item_id = self.item_id

                if activator:CanCarryWeapon(weapons.GetStored(item_id)) then
                    if activator:HasWeapon(item_id) then
                        activator:PrintMessage(HUD_PRINTTALK, "You already have this item!")
                        activator:RdmtUndoSantaGift(owner)
                        return
                    else
                        activator:Give(item_id)
                    end
                else
                    activator:PrintMessage(HUD_PRINTTALK, "You are already holding an item that shares a slot with this gift!")
                    activator:RdmtUndoSantaGift(owner)
                    return
                end

                owner:PrintMessage(HUD_PRINTTALK, activator:Nick() .. " has opened your present and your ammo has been refunded.")
                owner:SetNWBool("RdmtXmasCannonHasAmmo", true)
                self:Remove()
            end
        end
    end
end