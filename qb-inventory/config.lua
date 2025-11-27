Config = {}

-- General Settings
Config.MaxInventoryWeight = 120000 -- Maximum weight a player can carry (grams)
Config.MaxInventorySlots = 41 -- Maximum inventory slots

-- Hotbar Settings
Config.UseHotbar = true
Config.HotbarSlots = 5

-- Drop Settings
Config.MaxDropSlots = 30
Config.MaxDropWeight = 100000
Config.DropDespawnTime = 300 -- seconds

-- Shop Settings
Config.Shops = {
    ["247supermarket"] = {
        name = "24/7 Supermarket",
        items = {
            { name = "sandwich", price = 2, amount = 50 },
            { name = "water_bottle", price = 1, amount = 50 },
            { name = "bandage", price = 10, amount = 20 },
            { name = "lighter", price = 2, amount = 30 },
        }
    },
    ["hardware"] = {
        name = "Hardware Store",
        items = {
            { name = "lockpick", price = 20, amount = 10 },
            { name = "screwdriver", price = 15, amount = 10 },
            { name = "wrench", price = 12, amount = 10 },
            { name = "drill", price = 500, amount = 5 },
        }
    },
    ["electronics"] = {
        name = "Electronics Store",
        items = {
            { name = "phone", price = 500, amount = 10 },
            { name = "radio", price = 250, amount = 10 },
            { name = "gps", price = 100, amount = 15 },
        }
    },
    ["ammunition"] = {
        name = "Ammunation",
        items = {
            { name = "weapon_pistol", price = 2500, amount = 5 },
            { name = "pistol_ammo", price = 50, amount = 100 },
            { name = "weapon_bat", price = 100, amount = 10 },
            { name = "weapon_knife", price = 200, amount = 10 },
        }
    }
}

-- Stash Locations
Config.Stashes = {
    ["police_evidence"] = {
        name = "Police Evidence",
        slots = 100,
        weight = 500000,
        coords = vector3(473.53, -992.77, 26.27),
        job = "police",
        jobGrade = 0
    },
    ["hospital_storage"] = {
        name = "Hospital Storage",
        slots = 50,
        weight = 200000,
        coords = vector3(310.16, -593.51, 43.29),
        job = "ambulance",
        jobGrade = 0
    }
}

-- Vehicle Trunk Sizes (by vehicle class)
Config.VehicleTrunks = {
    [0] = { slots = 15, weight = 30000 },   -- Compacts
    [1] = { slots = 30, weight = 50000 },   -- Sedans
    [2] = { slots = 50, weight = 75000 },   -- SUVs
    [3] = { slots = 20, weight = 35000 },   -- Coupes
    [4] = { slots = 40, weight = 60000 },   -- Muscle
    [5] = { slots = 25, weight = 40000 },   -- Sports Classics
    [6] = { slots = 20, weight = 35000 },   -- Sports
    [7] = { slots = 10, weight = 20000 },   -- Super
    [8] = { slots = 5, weight = 10000 },    -- Motorcycles
    [9] = { slots = 25, weight = 40000 },   -- Off-road
    [10] = { slots = 60, weight = 100000 }, -- Industrial
    [11] = { slots = 80, weight = 150000 }, -- Utility
    [12] = { slots = 100, weight = 200000 },-- Vans
    [13] = { slots = 5, weight = 10000 },   -- Cycles
    [14] = { slots = 5, weight = 10000 },   -- Boats
    [15] = { slots = 5, weight = 10000 },   -- Helicopters
    [16] = { slots = 5, weight = 10000 },   -- Planes
    [17] = { slots = 60, weight = 100000 }, -- Service
    [18] = { slots = 40, weight = 60000 },  -- Emergency
    [19] = { slots = 50, weight = 80000 },  -- Military
    [20] = { slots = 80, weight = 150000 }, -- Commercial
}

-- Glovebox Sizes
Config.GloveboxSize = {
    slots = 5,
    weight = 10000
}

-- UI Settings
Config.UI = {
    blur = true,
    animation = true,
    sound = true,
    theme = "nopixel" -- "nopixel", "dark", "light"
}

-- Keybinds
Config.OpenInventoryKey = "TAB"
Config.UseItemKey = "E"
Config.HotbarKeys = {"1", "2", "3", "4", "5"}

-- Item Use Animations
Config.ItemAnimations = {
    ["sandwich"] = {
        dict = "mp_player_inteat@burger",
        anim = "mp_player_int_eat_burger",
        time = 5000
    },
    ["water_bottle"] = {
        dict = "mp_player_intdrink",
        anim = "loop_bottle",
        time = 3000
    },
    ["bandage"] = {
        dict = "anim@heists@narcotics@funding@gang_idle",
        anim = "gang_chatting_idle01",
        time = 5000
    }
}
