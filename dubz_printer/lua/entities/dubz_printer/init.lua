AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("autorun/dubz_config.lua")

util.AddNetworkString("dubz_printer_collect")
util.AddNetworkString("dubz_printer_refill")
util.AddNetworkString("dubz_printer_upgrade")

ENT.SpawnOffset = Vector(15, 0, 15)

local function GetLevelConfig(ent)
    local cfg = dubz.printer[ent:GetClass()]
    local stars = ent:GetNWInt("Stars", 0)

    local amountMultiplier = 1 + stars * (cfg.AmountBonusPerStar or cfg.UpgradeBonus or 0)
    local speedMultiplier = math.Clamp(1 - stars * (cfg.SpeedBonusPerStar or cfg.UpgradeBonus or 0), 0.4, 1)
    local maxCoolant = (cfg.MaxCoolant or 100) * (1 + stars * (cfg.CoolantCapacityPerStar or 0))
    local coolantPerPrint = (cfg.CoolantPerPrint or 0) * math.max(0.25, 1 - stars * (cfg.CoolantEfficiencyPerStar or 0))
    local passiveDrain = (cfg.PassiveCoolantDrain or 0.1) * (1 + stars * 0.05)

    return {
        amountMultiplier = amountMultiplier,
        speedMultiplier = speedMultiplier,
        maxCoolant = maxCoolant,
        coolantPerPrint = coolantPerPrint,
        passiveDrain = passiveDrain
    }
end

local function GetUpgradeCost(cfg, level)
    local base = cfg.UpgradeCostBase or cfg.UpgradeCost or 0
    local scale = cfg.UpgradeCostScale or 1
    return math.floor(base * (scale ^ (level - 1)))
end

local function PrintMore(ent)
    if not IsValid(ent) then return end
    ent.sparking = true
    timer.Simple(3, function()
        if not IsValid(ent) then return end
        ent:CreateMoneybag()
    end)
end

function ENT:CreateMoneybag()
    if self:IsOnFire() then return end
    if self:GetNWInt("Coolant") == 0 then return end

    local baseAmount = dubz.printer[self:GetClass()].PrintAmount
    local levelConfig = GetLevelConfig(self)
    local amount = math.Round(baseAmount * levelConfig.amountMultiplier)

    local prevent, hookAmount = hook.Run("moneyPrinterPrintMoney", self, amount)
    if prevent == true then return end
    amount = hookAmount or amount

    local MoneyPos = self:GetPos() + self.SpawnOffset
    local currentAmount = self:GetNWInt("Amount", 0)
    self:SetNWInt("Amount", currentAmount + amount)

    self.MaxCoolant = levelConfig.maxCoolant
    local coolantAfterPrint = math.max(0, (self.Coolant or levelConfig.maxCoolant) - levelConfig.coolantPerPrint)
    self.Coolant = math.min(levelConfig.maxCoolant, coolantAfterPrint)
    self:SetNWInt("Coolant", self.Coolant)

    -- Overheat logic
    if self.OverheatChance and self.OverheatChance > 0 then
        local coolantFactor = (self.Coolant or 100) / 100
        local chance = self.OverheatChance / coolantFactor
        if math.random(1, math.Round(chance)) == 3 then
            self:BurstIntoFlames()
        end
    end

    hook.Run("moneyPrinterPrinted", self)

    -- Adjusted PrintTime based on stars
    local basePrintTime = dubz.printer[self:GetClass()].PrintTime
    local nextPrintTime = basePrintTime * levelConfig.speedMultiplier

    self.PrintTimerID = "DubzPrinterPrint_" .. self:EntIndex()
    timer.Create(self.PrintTimerID, nextPrintTime, 1, function()
        if IsValid(self) then PrintMore(self) end
    end)
end

function ENT:StartSound()
    if not self.SoundLoop then
        self.SoundLoop = CreateSound(self, Sound("ambient/levels/labs/equipment_printer_loop1.wav"))
        self.SoundLoop:SetSoundLevel(52)
        self.SoundLoop:PlayEx(1, 100)
    end
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetUseType(SIMPLE_USE)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetColor(dubz.printer[self:GetClass()].PrinterColor)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    local cfg = dubz.printer[self:GetClass()]
    self.damage = cfg.Health or 100
    local levelConfig = GetLevelConfig(self)
    self.MaxCoolant = levelConfig.maxCoolant
    self.Coolant = levelConfig.maxCoolant

    self:SetNWInt("Amount", 0)
    self:SetNWInt("Health", self.damage)
    self:SetNWInt("Coolant", self.Coolant)
    self:SetNWInt("Stars", 0)
    self:SetNWInt("Temperature", cfg.StartingTemp)
    self:SetNWBool("Overheated", false)

    local basePrintTime = dubz.printer[self:GetClass()].PrintTime
    local nextPrintTime = basePrintTime * levelConfig.speedMultiplier

    timer.Simple(nextPrintTime, function() PrintMore(self) end)
end

function ENT:OnTakeDamage(dmg)
    self:TakePhysicsDamage(dmg)
    if self.burningup then return end

    self.damage = self.damage - dmg:GetDamage()
    self:SetNWInt("Health", self.damage)

    if self.damage <= 0 then
        if math.random(1, 10) < 3 then
            self:BurstIntoFlames()
        else
            self:Destruct()
            self:Remove()
        end
    end
end

function ENT:Destruct()
    local vPoint = self:GetPos()
    local effectdata = EffectData()
    effectdata:SetStart(vPoint)
    effectdata:SetOrigin(vPoint)
    effectdata:SetScale(1)
    util.Effect("Explosion", effectdata)

    if IsValid(self:Getowning_ent()) then
        DarkRP.notify(self:Getowning_ent(), 1, 4, DarkRP.getPhrase("money_printer_exploded"))
    end
end

function ENT:BurstIntoFlames()
    if hook.Run("moneyPrinterCatchFire", self) == true then return end

    if IsValid(self:Getowning_ent()) then
        DarkRP.notify(self:Getowning_ent(), 0, 4, DarkRP.getPhrase("money_printer_overheating"))
    end

    self.burningup = true
    local burntime = math.random(8, 18)
    self:Ignite(burntime, 0)

    timer.Simple(burntime, function()
        if IsValid(self) then self:Fireball() end
    end)
end

function ENT:Fireball()
    if not self:IsOnFire() then self.burningup = false return end

    local dist = math.random(20, 280)
    self:Destruct()

    for _, v in ipairs(ents.FindInSphere(self:GetPos(), dist)) do
        if not v:IsPlayer() and not v:IsWeapon() and v:GetClass() ~= "predicted_viewmodel" and not v.IsMoneyPrinter then
            v:Ignite(math.random(5, 22), 0)
        elseif v:IsPlayer() then
            local distance = v:GetPos():Distance(self:GetPos())
            v:TakeDamage(distance / dist * 100, self, self)
        end
    end

    self:Remove()
end

function ENT:Think()
    if self:WaterLevel() > 0 then
        self:Destruct()
        self:Remove()
        return
    end

    local levelConfig = GetLevelConfig(self)
    self.MaxCoolant = levelConfig.maxCoolant

    -- Handle coolant sound start/stop
    local coolant = self.Coolant or 0

    if coolant > 0 then
        -- Start sound if not already playing
        if not self.SoundLoop then
            self:StartSound()
        end
    else
        -- Stop sound if coolant depleted and sound playing
        if self.SoundLoop then
            self.SoundLoop:Stop()
            self.SoundLoop = nil
        end

        -- Cancel old timer
        if self.PrintTimerID then
            timer.Remove(self.PrintTimerID)
        end
    end

    -- Coolant consumption
    self.Coolant = math.max(0, math.min(levelConfig.maxCoolant, coolant - levelConfig.passiveDrain))
    self:SetNWInt("Coolant", self.Coolant)

    local temp = self:GetNWInt("Temperature", 25)
    if self.burningup then
        temp = math.min(100, temp + 0.5)
    else
        local coolantLevel = self.Coolant or 0
        if coolantLevel > levelConfig.maxCoolant * 0.5 then
            temp = math.max(0, temp - 0.3)
        elseif coolantLevel < levelConfig.maxCoolant * 0.2 then
            temp = math.min(100, temp + 0.5)
        end
    end
    self:SetNWInt("Temperature", temp)
end

function ENT:OnRemove()
    if self.SoundLoop then
        self.SoundLoop:Stop()
    end
end

net.Receive("dubz_printer_collect", function()
    local ply = net.ReadEntity()
    local ent = net.ReadEntity()

    if IsValid(ent) and ent:GetClass() == "dubz_printer" then
        if IsValid(ply) and ply:IsPlayer() and ent:GetNWInt("Amount") > 0 then
            local amount = ent:GetNWInt("Amount")
            ply:addMoney(amount)
            DarkRP.notify(ply, 0, 4, "You collected " .. DarkRP.formatMoney(amount) .. " from the printer.")
            ent:SetNWInt("Amount", 0)
        end
    end
end)

net.Receive("dubz_printer_refill", function()
    local ply = net.ReadEntity()
    local ent = net.ReadEntity()

    if IsValid(ent) and ent:GetClass() == "dubz_printer" then
        local baseRefillCost = dubz.printer[ent:GetClass()].CoolantRefillCost
        local levelConfig = GetLevelConfig(ent)
        local currentCoolant = math.min(ent.Coolant or levelConfig.maxCoolant, levelConfig.maxCoolant)

        if currentCoolant >= levelConfig.maxCoolant then
            DarkRP.notify(ply, 0, 4, "Coolant is already full.")
            return
        end

        local missingFraction = (levelConfig.maxCoolant - currentCoolant) / levelConfig.maxCoolant
        local refillCost = math.ceil(baseRefillCost * missingFraction)

        if ply:getDarkRPVar("money") >= refillCost then
            local wasEmpty = currentCoolant == 0

            ent.MaxCoolant = levelConfig.maxCoolant
            ent.Coolant = levelConfig.maxCoolant
            ent:SetNWInt("Coolant", ent.Coolant)
            ply:addMoney(-refillCost)
            DarkRP.notify(ply, 0, 4, "Coolant refilled for " .. DarkRP.formatMoney(refillCost) .. ".")

            -- Start sound if it was empty before refill
            if wasEmpty then
                if not ent.SoundLoop then
                    ent:StartSound()

                    -- Restart the print process
                    local stars = ent:GetNWInt("Stars", 0)
                    local basePrintTime = dubz.printer[ent:GetClass()].PrintTime
                    local nextPrintTime = basePrintTime * levelConfig.speedMultiplier

                    ent.PrintTimerID = "DubzPrinterTimer_" .. ent:EntIndex()
                    timer.Create(ent.PrintTimerID, nextPrintTime, 1, function()
                        if IsValid(ent) then PrintMore(ent) end
                    end)

                end
            end
        else
            DarkRP.notify(ply, 1, 4, "You can't afford to refill the coolant.")
        end
    end
end)

net.Receive("dubz_printer_upgrade", function()
    local ply = net.ReadEntity()
    local ent = net.ReadEntity()

    if not IsValid(ply) or not IsValid(ent) then return end
    if ent:GetClass() ~= "dubz_printer" then return end

    local current = ent:GetNWInt("Stars", 0)
    local cfg = dubz.printer[ent:GetClass()]
    local upgradecost = GetUpgradeCost(cfg, current + 1)
    local maxLevel = cfg.MaxUpgradeLevel or 5

    if current < maxLevel then
        if ply:getDarkRPVar("money") >= upgradecost then
            ent:SetNWInt("Stars", current + 1)
            ply:addMoney(-upgradecost)
            DarkRP.notify(ply, 0, 4, "Printer upgraded to " .. (current + 1) .. " stars.")

            -- CANCEL any existing timer
            if ent.PrintTimerID then
                timer.Remove(ent.PrintTimerID)
            end

            -- Cancel old timer
            if ent.PrintTimerID then
                timer.Remove(ent.PrintTimerID)
            end

            -- Restart the print process
            local levelConfig = GetLevelConfig(ent)
            ent.MaxCoolant = levelConfig.maxCoolant
            ent.Coolant = math.min(ent.Coolant or levelConfig.maxCoolant, levelConfig.maxCoolant)
            ent:SetNWInt("Coolant", ent.Coolant)

            local basePrintTime = dubz.printer[ent:GetClass()].PrintTime
            local nextPrintTime = basePrintTime * levelConfig.speedMultiplier

            ent.PrintTimerID = "DubzPrinterTimer_" .. ent:EntIndex()
            timer.Create(ent.PrintTimerID, nextPrintTime, 1, function()
                if IsValid(ent) then PrintMore(ent) end
            end)
        else
            DarkRP.notify(ply, 1, 4, "You can't afford to upgrade the printer.")
        end
    else
        DarkRP.notify(ply, 1, 4, "This printer is already fully upgraded.")
    end
end)