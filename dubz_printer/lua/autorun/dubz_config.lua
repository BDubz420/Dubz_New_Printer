dubz = dubz or {}

dubz.printer = {
    ["dubz_printer"] = {
        PrinterColor = Color(145, 145, 145),          -- Base money per print

        PrintAmount = 50,           -- Base money per print
        PrintTime = 30,             -- Seconds between prints
        Health = 100,               -- Max health

        MaxCoolant = 100,           -- Maximum coolant level
        CoolantPerPrint = 10,       -- Coolant consumed per print
        PassiveCoolantDrain = 0.1,  -- Passive coolant drain per tick
        CoolantRefillCost = 100,    -- Coolant consumed per print

        MaxUpgradeLevel = 5,        -- Max number of stars
        UpgradeCostBase = 500,      -- Base cost for the first star
        UpgradeCostScale = 1.5,     -- Multiplier applied per level (Level 2 = 500 * 1.5 = 750)

        AmountBonusPerStar = 0.25,       -- Bonus to print amount per star
        SpeedBonusPerStar = 0.08,        -- Reduction to print time per star
        CoolantCapacityPerStar = 0.1,    -- Additional max coolant per star (10%)
        CoolantEfficiencyPerStar = 0.05, -- Reduces coolant cost per print by 5% per star

        OverheatChance = 5          -- Lower = more dangerous, 3 is high risk
    }
}

dubz.printerrack = {
    ["dubz_printer_rack"] = {
        Health = 100
    }
}
