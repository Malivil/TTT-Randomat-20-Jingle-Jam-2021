AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Christmas Cannon"
    SWEP.Slot = 8
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "rpg"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Weight = 5

SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 50
SWEP.Primary.Damage = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.ClipMax = -1
SWEP.Primary.DefaultClip = -1

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.ViewModel = Model("models/weapons/v_rpg.mdl")
SWEP.WorldModel = Model("models/weapons/w_rocket_launcher.mdl")

SWEP.Kind = WEAPON_ROLE
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "none"
SWEP.AllowDrop = false
SWEP.IsSilent = false
SWEP.NoSights = true

local ShootSound = Sound("weapons/grenade_launcher1.wav")

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    if CLIENT then
        self:AddHUDHelp("Use {primaryfire} to give gifts to nice children", "Use {secondaryfire} to shoot coal at naughty children", false)
    end
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local has_ammo = owner:GetNWBool("RdmtXmasCannonHasAmmo", false)

    if has_ammo then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:EmitSound(ShootSound)

        if SERVER then
            owner:SetNWBool("RdmtXmasCannonHasAmmo", false)

            local blocklist = {}
            for blocked_id in string.gmatch(GetConVar("randomat_hellosanta_blocklist"):GetString(), "([^,]+)") do
                table.insert(blocklist, blocked_id:Trim())
            end

            local tracking = 0
            local _, _, swep_table = Randomat:GetShopEquipment(nil, Randomat:GetShopRoles(), blocklist, false, tracking, function(value) tracking = value end, true)
            local item_id = WEPS.GetClass(swep_table)

            local present = ents.Create("randomat_hellosanta_present")
            if not present:IsValid() then return false end
            local ang = owner:EyeAngles()
            present:SetAngles(ang)
            present:SetPos(owner:GetShootPos() + ang:Forward() * 50 + ang:Right() * 1 - ang:Up() * 1)
            present:SetOwner(owner)
            present.item_id = item_id
            present:Spawn()
            local physobj = present:GetPhysicsObject()
            if IsValid(physobj) then
                physobj:SetVelocity(owner:GetAimVector() * 1000)
            end
        end

        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(),  -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    elseif CLIENT and LocalPlayer() == self:GetOwner() and self:CanPrimaryAttack() then
        self:EmitSound( "Weapon_Pistol.Empty" )
    end
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local has_ammo = owner:GetNWBool("RdmtXmasCannonHasAmmo", false)

    if has_ammo then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:EmitSound(ShootSound)

        if SERVER then
            owner:SetNWBool("RdmtXmasCannonHasAmmo", false)

            local coal = ents.Create("randomat_hellosanta_coal")
            if not coal:IsValid() then return false end
            local ang = owner:EyeAngles()
            coal:SetAngles(ang)
            coal:SetPos(owner:GetShootPos() + ang:Forward() * 50 + ang:Right() * 1 - ang:Up() * 1)
            coal:SetOwner(owner)
            coal:Spawn()
            coal:SetColor(Color(128, 128, 128, 255))
            local physobj = coal:GetPhysicsObject()
            if IsValid(physobj) then
                physobj:SetVelocity(owner:GetAimVector() * 1500)
            end
        end

        owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(),  -0.1, 0.1, 1) * self.Primary.Recoil, 0))
    elseif CLIENT and LocalPlayer() == self:GetOwner() then
        self:EmitSound( "Weapon_Pistol.Empty" )
    end
end