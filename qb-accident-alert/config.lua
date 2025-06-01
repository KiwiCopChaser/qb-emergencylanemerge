Config = {}

-- Alert settings
Config.AlertRadiuses = {
    [1] = { radius = 10, label = "10m - Immediate Area" },
    [2] = { radius = 20, label = "20m - Close Proximity" },
    [3] = { radius = 40, label = "40m - Medium Range" },
    [4] = { radius = 100, label = "100m - Wide Area" }
}

-- Police jobs that can use the system
Config.PoliceJobs = {
    ['police'] = true,
    ['sheriff'] = true,
    ['state'] = true,
    ['trooper'] = true
}

-- Alert messages
Config.AlertMessages = {
    ['accident'] = "🚨 TRAFFIC ACCIDENT - Exercise caution in the area",
    ['investigation'] = "🔍 ACCIDENT INVESTIGATION - Avoid the area if possible",
    ['cleanup'] = "🚧 ACCIDENT CLEANUP - Expect delays",
    ['hazard'] = "⚠️ ROAD HAZARD - Drive carefully",
    ['custom'] = "" -- Will be filled by user input
}

-- UI settings
Config.AlertDuration = 15000 -- How long alerts show (ms)
Config.CooldownTime = 5000 -- Cooldown between alerts (ms)
Config.MaxCustomMessageLength = 100

-- Key binding
Config.OpenUIKey = 'F6' -- Key to open accident alert UI