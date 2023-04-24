local client

local function JamWeapon(weap)
    if not weap.OldPrimaryAttack then
        weap.OldPrimaryAttack = weap.PrimaryAttack
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
        end
    end
end

local function UnjamWeapon(weap)
    if weap.OldPrimaryAttack then
        weap.PrimaryAttack = weap.OldPrimaryAttack
        weap.OldPrimaryAttack = nil
    end
end

net.Receive("RdmtJingleJam2021Start", function()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    local weap_class = net.ReadString()
    local weap = client:GetWeapon(weap_class)
    if not IsValid(weap) then return end
    JamWeapon(weap)
end)

net.Receive("RdmtJingleJam2021Stop", function()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    local weap_class = net.ReadString()
    local weap = client:GetWeapon(weap_class)
    if not IsValid(weap) then return end
    UnjamWeapon(weap)
end)

net.Receive("RdmtJingleJam2021End", function()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    -- If we still don't have a client it's because we're not loaded yet
    -- This can happen because the Randomat "ends" all events during the Prep phase so if
    -- a player is still loading at that point then `LocalPlayer` would return a NULL Entity
    if not client or not IsPlayer(client) or not client.GetWeapons then return end

    for _, w in ipairs(client:GetWeapons()) do
        UnjamWeapon(w)
    end
end)