include("shared.lua")

surface.CreateFont("dubz_font", {
    font = "Data Control",
    size = 14,  -- smaller font size
    weight = 700,
    antialias = true,
})

local function RainbowColor(frequency)
    local t = CurTime() * frequency
    local r = math.floor(math.sin(t) * 127 + 128)
    local g = math.floor(math.sin(t + 2) * 127 + 128)
    local b = math.floor(math.sin(t + 4) * 127 + 128)
    return Color(r, g, b, 255)
end

function ENT:Draw()
    self:DrawModel()

    local distance = LocalPlayer():GetPos():Distance(self:GetPos())
    if distance > 450 then return end

    local Pos = self:GetPos()
    local Ang = self:GetAngles()
    local scale = 0.07

    Ang:RotateAroundAxis(Ang:Up(), 90)
    Ang:RotateAroundAxis(Ang:Forward(), 90)

    local owner = self:Getowning_ent()
    owner = (IsValid(owner) and owner:Nick()) or "Disconnected"
    local amount = self:GetNWInt("Amount", 0)
    local health = math.Clamp(self:GetNWInt("Health", 100), 0, 100)
    local coolant = math.Clamp(self:GetNWInt("Coolant", 100), 0, 100)
    local stars = math.Clamp(self:GetNWInt("Stars", 0), 0, 5)
    local overheating = self:GetNWBool("Overheating", false)
    local opacity = math.Clamp(health * 2.5, 0, 255)

    cam.Start3D2D(Pos + Ang:Up() * 12.82, Ang, scale)
        local totalW, totalH = 466, 78
        local cols, rows = 4, 2
        local cellW, cellH = totalW / cols, totalH / rows
        local startX, startY = -totalW / 2, -totalH / 2

        -- Background dark panel
        surface.SetDrawColor(30, 30, 30, 230)
        surface.DrawRect(startX, startY, totalW, totalH)

        -- Outer border with rainbow effect if 5 stars, else grey
        if stars == 5 then
            surface.SetDrawColor(RainbowColor(2))
        else
            surface.SetDrawColor(80, 80, 80, 255)
        end
        surface.DrawOutlinedRect(startX, startY, totalW, totalH)

        -- Draw grid cells with subtle borders
        surface.SetDrawColor(50, 50, 50, 150)
        for c = 0, cols - 1 do
            for r = 0, rows - 1 do
                local x = startX + c * cellW
                local y = startY + r * cellH
                surface.DrawOutlinedRect(x, y, cellW +1, cellH)
            end
        end

        -- Helper to draw text with shadow for contrast
        local function drawTextShadow(text, font, x, y, color, alignX, alignY)
            surface.SetTextColor(0, 0, 0, 160)
            surface.SetFont(font)
            surface.SetTextPos(x + 1, y + 1)
            surface.DrawText(text)

            surface.SetTextColor(color)
            surface.SetTextPos(x, y)
            surface.DrawText(text)
        end

        -- Cell 1 (Owner)
        local c1x, c1y = startX, startY
        drawTextShadow("Owner:", "dubz_font", c1x + 6, c1y + 5, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        drawTextShadow(owner, "dubz_font", c1x + 6, c1y + 22, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Cell 2 (Coolant)
        local c2x, c2y = startX + cellW, startY
        drawTextShadow("Coolant:", "dubz_font", c2x + 6, c2y + 5, Color(120, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local cBarX, cBarY, cBarW, cBarH = c2x + 6, c2y + 22, cellW - 12, 14
        surface.SetDrawColor(60, 60, 90, 180)
        surface.DrawRect(cBarX, cBarY, cBarW, cBarH)
        surface.SetDrawColor(0, 180, 255, 230)
        surface.DrawRect(cBarX, cBarY, cBarW * (coolant / 100), cBarH)
        drawTextShadow(math.Round(coolant) .. "%", "dubz_font", c2x + cellW / 2, cBarY + (cBarH / 2) - 7, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Cell 3 (Balance)
        local c3x, c3y = startX + cellW * 1.56, startY
        drawTextShadow("Balance:", "dubz_font", c3x + cellW / 2, c3y + 6, Color(140, 240, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local balanceText = DarkRP.formatMoney(amount)
        surface.SetFont("dubz_font")
        local tw, th = surface.GetTextSize(balanceText)
        local balanceY = c3y + 23 + (cellH - 28) / 2 - th / 2
        drawTextShadow(balanceText, "dubz_font", c3x + cellW / 2, balanceY, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Cell 4 (Stars)
        local c4x, c4y = startX + cellW * 3, startY
        drawTextShadow("Level:"..self:GetNWInt("stars", 0), "dubz_font", c4x + 6, c4y + 6, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local starY = c4y + 22
        local starSpacing = 18
        for i = 1, 5 do
            local colStar = i <= stars and Color(255, 215, 0) or Color(80, 80, 80)
            drawTextShadow("★", "dubz_font", c4x + cellW / 2.75 - starSpacing * 2 + (i - 1) * starSpacing, starY, colStar, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Cell 5 (Health)
        local c5x, c5y = startX, startY + cellH
        drawTextShadow("Health:", "dubz_font", c5x + 6, c5y + 2, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local barX, barY, barW, barH = c5x + 6, c5y + 17, cellW - 12, 14
        surface.SetDrawColor(50, 50, 50, 180)
        surface.DrawRect(barX, barY, barW, barH)
        surface.SetDrawColor(0, 200, 0, opacity)
        surface.DrawRect(barX, barY, barW * (health / 100), barH)
        drawTextShadow(health .. "%", "dubz_font", c5x + cellW / 2, barY + (barH / 2) - 7, Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Buttons (moved):
        -- Upgrade → Cell 8 (bottom row, 4th column)
        -- Collect → Cell 7 (bottom row, 3rd column) stays
        -- Refill → Cell 6 (bottom row, 2nd column)

        local buttonPositions = {
            {x = startX + cellW * 3, y = startY + cellH}, -- Upgrade (Cell 8)
            {x = startX + cellW * 2, y = startY + cellH}, -- Collect (Cell 7)
            {x = startX + cellW * 1, y = startY + cellH}, -- Refill (Cell 6)
        }

        local buttonLabels = { "Upgrade", "Collect", "Refill" }
        self.Buttons = self.Buttons or {}

        local eyePos = LocalPlayer():GetEyeTrace().HitPos
        local localEyePos = self:WorldToLocal(eyePos)
        hoverPosLocal = {
            x = localEyePos.y / scale,
            y = -localEyePos.z / scale
        }

        for i = 1, 3 do
            local bx, by = buttonPositions[i].x, buttonPositions[i].y
            local btnX, btnY, btnW, btnH = bx + 6, by + 8, cellW - 12, cellH - 16

            -- Restore original Y position (remove "+ 5" offset)
            self.Buttons[i] = {
                x = btnX,
                y = (btnY - cellH), -- original Y position
                w = btnW,
                h = btnH,
                netmsg = "dubz_printer_" .. string.lower(buttonLabels[i])
            }

            local baseCol = overheating and Color(230, 60, 60, 200) or Color(60, 60, 130, 200)

            local isHover = false
            if hoverPosLocal then
                if hoverPosLocal.x >= btnX and hoverPosLocal.x <= btnX + btnW and
                   hoverPosLocal.y >= btnY and hoverPosLocal.y <= btnY + btnH then
                    isHover = true
                end
            end

            surface.SetDrawColor(baseCol)
            surface.DrawRect(btnX, btnY, btnW, btnH)

            if isHover then
                surface.SetDrawColor(255, 255, 255, 40)
                surface.DrawRect(btnX, btnY, btnW, btnH)
            end

            drawTextShadow(
                buttonLabels[i],
                "dubz_font",
                btnX + btnW / 3,
                btnY + btnH / 4,
                Color(255, 255, 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end
    cam.End3D2D()
end

hook.Add("KeyPress", "dubz_printer_button_click", function(ply, key)
    if key ~= IN_USE then return end

    -- Cooldown check (1 second)
    if ply._nextPrinterButtonPress and ply._nextPrinterButtonPress > CurTime() then return end
    ply._nextPrinterButtonPress = CurTime() + 1

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    if not IsValid(ent) or ent:GetClass() ~= "dubz_printer" then return end

    if tr.HitPos:DistToSqr(ent:GetPos()) > 5000 then return end -- distance check (100 units squared)

    local Ang = ent:GetAngles()
    Ang:RotateAroundAxis(Ang:Up(), 90)
    Ang:RotateAroundAxis(Ang:Forward(), 90)

    local pos3d2d = ent:GetPos() + Ang:Up() * 12.82
    local localHitPos = WorldToLocal(tr.HitPos, Angle(0,0,0), pos3d2d, Ang)

    local scale = 0.07
    localHitPos = localHitPos / scale

    for _, btn in ipairs(ent.Buttons or {}) do
        if localHitPos.x >= btn.x and localHitPos.x <= btn.x + btn.w and
           localHitPos.y >= btn.y and localHitPos.y <= btn.y + btn.h then

            net.Start(btn.netmsg)
            net.WriteEntity(ply)
            net.WriteEntity(ent)
            net.SendToServer()

            break
        end
    end
end)