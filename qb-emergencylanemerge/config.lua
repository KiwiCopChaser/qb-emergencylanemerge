Config = {}

-- Detection settings
Config.DetectionRange = 50.0 -- Range to detect emergency vehicles (meters)
Config.MergeDistance = 25.0 -- Distance at which vehicles start merging
Config.MergeSpeed = 0.8 -- Speed multiplier when merging (0.8 = 80% of normal speed)

-- Emergency vehicle classes that trigger merging
Config.EmergencyClasses = {
    [18] = true, -- Emergency vehicles
}

-- Emergency vehicle models (add more as needed)
Config.EmergencyVehicles = {
    [`nzmskoda`] = true,
    [`police2`] = true,
    [`police3`] = true,
    [`police4`] = true,
    [`policeb`] = true,
    [`policeold1`] = true,
    [`policeold2`] = true,
    [`policet`] = true,
    [`sheriff`] = true,
    [`sheriff2`] = true,
    [`ambulance`] = true,
    [`firetruk`] = true,
    [`lguard`] = true,
    [`pbus`] = true,
    [`fbi`] = true,
    [`fbi2`] = true,
}

-- Jobs that can trigger the merge system
Config.EmergencyJobs = {
    ['police'] = true,
    ['ambulance'] = true,
    ['fire'] = true,
    ['sheriff'] = true,
}

-- Performance settings
Config.UpdateInterval = 500 -- How often to check for emergency vehicles (ms)
Config.MaxMergeVehicles = 15 -- Maximum number of AI vehicles to process at once
Config.EnableDebug = true -- Set to true for debug prints
Config.MinMergeSpeed = 5.0 -- Minimum speed for vehicles to be considered for merging
