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
    util.AddNetworkString("TTT_RdmtSantaPresentNotify")

    local function NotifyPlayer(ply, item, has, can_carry)
        net.Start("TTT_RdmtSantaPresentNotify")
        net.WriteString(tostring(item))
        net.WriteBool(has)
        net.WriteBool(can_carry)
        net.Send(ply)
    end

    function ENT:Use(activator)
        if CurTime() > self.nextUse then
            if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end
            self.nextUse = CurTime() + 0.5

            local owner = self:GetOwner()
            if activator:RdmtCheckSantaGift(owner) then
                local item_id = self.item_id
                local has = activator:HasWeapon(item_id)
                local can_carry = activator:CanCarryWeapon(weapons.GetStored(item_id))
                NotifyPlayer(activator, item_id, has, can_carry)
                if has or not can_carry then
                    activator:RdmtUndoSantaGift(owner)
                    return
                else
                    activator:Give(item_id)
                    Randomat:CallShopHooks(nil, item_id, activator)
                end

                owner:PrintMessage(HUD_PRINTTALK, activator:Nick() .. " has opened your present and your ammo has been refunded.")
                owner:SetNWBool("RdmtXmasCannonHasAmmo", true)
                self:Remove()
            end
        end
    end
end

if CLIENT then
    net.Receive("TTT_RdmtSantaPresentNotify", function()
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local item = net.ReadString()
        local has = net.ReadBool()
        local can_carry = net.ReadBool()
        local name = Randomat:GetWeaponName(item)

        if has then
            client:PrintMessage(HUD_PRINTTALK, "You already have '" .. name .. "'!")
        elseif not can_carry then
            client:PrintMessage(HUD_PRINTTALK, "You are already holding an item that shares a slot with '" .. name .. "'!")
        else
            client:PrintMessage(HUD_PRINTTALK, "You got '" .. name .. "' from Santa!")
        end
    end)
end