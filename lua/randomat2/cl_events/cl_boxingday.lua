local MathCos = math.cos
local MathSin = math.sin

surface.CreateFont("KnockedOut", {
    font = "Trebuchet24",
    size = 22,
    weight = 600
})

-- Translation strings
hook.Add("Initialize", "RdmtBoxingDay_Translations_Initialize", function()
    LANG.AddToLanguage("english", "rdmtbox_gloves_help_pri", "Use {primaryfire} to knock weapons out of players' hands")
    LANG.AddToLanguage("english", "rdmtbox_gloves_help_sec", "Attack with {secondaryfire} to knock players out")
end)

local duration
local client

net.Receive("RdmtBoxingDayBegin", function()
    if not client then
        client = LocalPlayer()
    end
    duration = net.ReadInt(8)

    -- Dizzy effect
    local function GetHeadPos(ply, rag)
        local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
        local pos
        if bone then
            local _
            pos, _ = rag:GetBonePosition(bone)
        else
            pos = rag:GetPos()
        end

        pos.z = 15
        local plyPos = ply:GetPos()
        plyPos.z = pos.z

        -- Shift further toward the head, rather than the neck area
        local dir = (plyPos - pos):GetNormal()
        return pos + (dir * -5)
    end

    hook.Add("TTTPlayerAliveClientThink", "RdmtBoxingDay_TTTPlayerAliveClientThink", function(cli, ply)
        if not client then
            client = cli
        end
        local ragdoll = ply:GetNWEntity("RdmtBoxingRagdoll", nil)
        if not IsValid(ragdoll) then return end

        if ply:GetNWBool("RdmtBoxingKnockedOut", false) then
            if not ragdoll.KnockoutEmitter then ragdoll.KnockoutEmitter = ParticleEmitter(ragdoll:GetPos()) end
            if not ragdoll.KnockoutNextPart then ragdoll.KnockoutNextPart = CurTime() end
            if not ragdoll.KnockoutDir then ragdoll.KnockoutDir = 0 end
            local pos = ragdoll:GetPos()
            if ragdoll.KnockoutNextPart < CurTime() then
                if client:GetPos():Distance(pos) <= 3000 then
                    ragdoll.KnockoutEmitter:SetPos(pos)
                    ragdoll.KnockoutNextPart = CurTime() + 0.02
                    ragdoll.KnockoutDir = ragdoll.KnockoutDir + 0.25
                    local radius = 7
                    local vec = Vector(MathSin(ragdoll.KnockoutDir) * radius, MathCos(ragdoll.KnockoutDir) * radius, 10)
                    local particle = ragdoll.KnockoutEmitter:Add("particle/wisp.vmt", GetHeadPos(ply, ragdoll) + vec)
                    particle:SetVelocity(Vector(0, 0, 0))
                    particle:SetDieTime(1)
                    particle:SetStartAlpha(200)
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(1)
                    particle:SetEndSize(1)
                    particle:SetRoll(0)
                    particle:SetRollDelta(0)
                    particle:SetColor(200, 230, 90)
                end
            end
        elseif ragdoll.KnockoutEmitter then
            ragdoll.KnockoutEmitter:Finish()
            ragdoll.KnockoutEmitter = nil
        end
    end)

    -- Knocked out progress bar
    local margin = 10
    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height
    local colors = {
        background = Color(30, 60, 100, 222),
        fill = Color(75, 150, 255, 255)
    }
    hook.Add("HUDPaint", "RdmtBoxingDay_HUDPaint", function()
        if not client then
            client = LocalPlayer()
        end

        if not client:GetNWBool("RdmtBoxingKnockedOut", false) then return end

        local endTime = client:GetNWInt("RdmtBoxingKnockoutEndTime", 0)
        if endTime <= 0 then return end

        local diff = endTime - CurTime()
        if diff <= 0 then return end

        CRHUD:PaintBar(8, x, y, width, height, colors, 1 - (diff / duration))
        draw.SimpleText("KNOCKED OUT", "KnockedOut", ScrW() / 2, y + 1, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end)
end)

net.Receive("RdmtBoxingDayEnd", function()
    hook.Remove("TTTPlayerAliveClientThink", "RdmtBoxingDay_TTTPlayerAliveClientThink")
    hook.Remove("HUDPaint", "RdmtBoxingDay_HUDPaint")
end)