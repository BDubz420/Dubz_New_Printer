dubz = dubz or {}

dubz.printer = {
    ["dubz_printer"] = {
        PrinterColor = Color(145, 145, 145),          -- Base money per print

        PrintAmount = 50,          -- Base money per print
        PrintTime = 30,             -- Seconds between prints
        Health = 100,               -- Max health

        MaxCoolant = 100,           -- Maximum coolant level
        CoolantPerPrint = 10,       -- Coolant consumed per print
        CoolantRefillCost = 100,    -- Coolant consumed per print

        MaxUpgradeLevel = 5,        -- Max number of stars
        UpgradeCost = 500,          -- Cost per upgrade star
        UpgradeBonus = 0.215,         -- Bonus per star (e.g. +20% per upgrade)

        OverheatChance = 5          -- Lower = more dangerous, 3 is high risk
    }
}

dubz.printerrack = {
    ["dubz_printer_rack"] = {
        Health = 100
    }
}