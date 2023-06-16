Config = {}

--[[ General Configs ]]
Config.StartJobPedModel = 'a_m_m_business_01' -- The model of the ped that starts the job
Config.StartJobLocation = vec3(1242.0847, -3257.0403, 5.0288) -- The location at which you start the job (and the map blip location)
Config.DeliverLocation = vec3(393.0399, -1617.5004, 29.2920) -- The location at which you deliver vehicles
Config.DeliverRadius = 10 -- The radius at which the player must be within (in relation to DeliverLocation) to get paid for delivering
Config.StartJobRadius = 50 -- The distance at which once a player is within the ped will spawn/be visable
Config.StartJobPedHeading = 272.1205 -- The direction at which the start job ped is facing
Config.SpawnTruckLocation = vector3(1247.0011, -3262.6636, 5.8075) -- The location at which the tow truck spawns to start the job
Config.SpawnTruckHeading = 269.8075 -- The direction the tow truck being spawned is facing
Config.EnableCarKeys = true -- If true, you have to configure your car keys export(s) in client.lua line 55 & 140
Config.MinWaitTime = 1 -- The minimum wait time in minutes for a new job assignment
Config.MaxWaitTime = 2 -- The maximum wait time in minutes for a new job assignment

--[[ Pay Conigs ]]
Config.PayPerDelivery = 500 -- How much the player is paid per delivery completed
Config.PayPerDeliveryAccount = 'money' -- Pay in cash with 'money' or to the bank with 'bank'
Config.RandomPayPerDelivery = true -- Set true if you want randomized pay, set false for same amount (PayPerDelivery).
Config.MinPayPerDelivery = 350 -- If Config.RandomPayPerDelivery = true then what is the minimum pay? (If RandomPay false, ignore this)
Config.MaxPayPerDelivery = 950 -- If Config.RandomPayPerDelivery = true then what is the maxmimum pay? (If RandomPay false, ignore this)

--[[ Blip Configs ]]
Config.BlipSprite = 477 -- https://docs.fivem.net/docs/game-references/blips/
Config.BlipColor = 21 -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
Config.BlipScale = 0.7 
Config.BlipName = 'Towing'

--[[ Car Spawns - Must Follow Format ]]
Config.Locations = {
    { x = 1015.3276, y = -2462.3572, z = 27.7853, h = 82.8159 },
    { x = -247.7807, y = -1687.8434, z = 33.4754, h = 178.8647 },
    { x = 372.9686, y = -767.0320, z = 29.2700, h = 0.0682 },
    { x = -1276.2042, y = -556.5905, z = 30.2092, h = 219.8612 },
    { x = 1205.2948, y = -708.5202, z = 59.4169, h = 9.6660 },
    { x = 213.8225, y = 389.6160, z = 106.5621, h = 171.4204 },
    { x = -449.8099, y = 98.6727, z = 62.8731, h = 355.5552 },
    { x = -928.4528, y = -124.9771, z = 37.2992, h = 117.7664 },
    { x = -1772.7124, y = -519.8768, z = 38.5269, h = 299.9457 },
    { x = -2165.7588, y = -420.4905, z = 13.0514, h = 20.4053 },
    { x = -1483.1953, y = -895.6342, z = 9.7399, h = 64.1165 }
}

--[[ Car Models ]]
Config.CarModels = {
    'felon',
    'prairie',
    'baller',
    'sentinel',
    'zion',
    'ruiner',
    'asea',
    'ingot',
    'intruder',
    'primo',
    'stratum',
    'tailgater'
}

--[[ String Configs ]]
Notifications = {
    position = 'top', -- The position of all notifications
    icon = 'truck-ramp-box', -- The icon displayed for all notifications
    title = 'Tow Truck', -- The title for all notifications
    successfulVehicleLoad = 'You have successfully loaded the vehicle onto the Tow Truck',
    cancelledVehicleLoad = 'You cancelled loading the vehicle',
    notCloseEnough = 'You are not close enough to the vehicle you are trying to tow',
    sucessfulVehicleUnload = 'You have successfully unloaded the vehicle from the Tow Truck',
    cancelledVehicleUnload = 'You cancelled unloading the vehicle',
    error = 'An error has occured - please try again',
    noVehicleToUnload = 'There is no vehicle on the truck to unload',
    towTruckSpawnOccupied = 'The location is currently occupied - please move any vehicles and try again',
    clockedIn = 'You will now start receiving jobs as they become available',
    tooFarToDeliver = 'You are too far from the delivery location to get paid',
    confirmNextJob = 'Great - a new job will be assigned as it becomes available',
    searchingForJob = 'Searching for a new job location..',
    jobAssigned = 'A new job is available - your GPS was updated'
}

Target = {
    distance = 2, -- The radius at which target options are visable from the target for all target options
    loadVehicle = 'Load vehicle',
    loadVehicleIcon = 'fas fa-truck-ramp-box',
    unloadVehicle = 'Unload vehicle',
    unloadVehicleIcon = 'fas fa-truck-ramp-box',
    startJob = 'Talk',
    startJobIcon = 'fas fa-truck'
}

ContextMenu = {
    menuTitle = 'Towing',
    towTruckTitle = 'Tow Truck',
    towTruckDescription = 'Receive your Tow Truck then Clock In to begin work',
    towTruckIcon = 'truck',
    clockInTitle = 'Clock In',
    clockInDescription = 'Show yourself as on-duty & ready to receive calls', -- This description displays whilst not clocked in
    clockInDescription2 = 'You are already on-duty & receiving calls', -- This description displays whilst clocked in
    clockInIcon = 'clock',
    clockOutTitle = 'Clock Out',
    clockOutDescription = 'Return your truck and go off-duty', -- This description displays whilst clocked in
    clockOutDescription2 = 'You\'re not clocked in', -- This description displays whilst not clocked in
    clockOutIcon = 'clock'
}

ProgressCircle = {
    position = 'middle', -- The position for all Progress Circles
    loadVehicleLabel = 'Loading vehicle..',
    loadVehicleDuration = 5000,
    unloadVehicleLabel = 'Unloading vehicle..',
    unloadVehicleDuration = 5000
}

AlertDialog = {
    header = 'Towing',
    content = 'Thank you for delivering the vehicle to the impound. Would you like to continue?',
}