-- Stuff
local ox_target = exports.ox_target
local towJobStartLocation = lib.points.new(Config.StartJobLocation, Config.StartJobRadius)
local towJobDeliverLocation = lib.points.new(Config.DeliverLocation, Config.DeliverRadius)
local targetVehicle = nil
local currentlyTowedVehicle = nil
local towVehicle = nil
local inService = nil
local spawnedVehicle = nil
local spawnedVehiclePlate = nil
local randomLoc = nil
local selectLoc = nil
local randomCar = nil
local selectCar = nil
local jobAssigned = false
local enabledCalls = false
local jobMenu = nil
local towRequest = nil

-- Blip stuff
CreateThread(function()
    while true do
        local sleep = 1000
        local isLoaded = ESX.IsPlayerLoaded()
        if isLoaded then
            createBlip()
            break
        end
        Wait(sleep)
    end
end)

-- Function to create the blip
function createBlip()
    local blip = AddBlipForCoord(Config.StartJobLocation)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipScale(blip, Config.BlipScale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.BlipName)
    EndTextCommandSetBlipName(blip)
end

-- On player death set variables to proper values
AddEventHandler('esx:onPlayerDeath', function(data)
    if inService then
        inService = false
        enabledCalls = false
        jobAssigned = false
        DeleteWaypoint()
    end
end)

-- Function that spawns the tow truck at the job start location
function spawnTowTruck()
    local nearbyVehicles = lib.getClosestVehicle(Config.SpawnTruckLocation, 3, false)
    if nearbyVehicles == nil then
        ESX.Game.SpawnVehicle('flatbed', Config.SpawnTruckLocation, Config.SpawnTruckHeading, function(vehicle)
            Entity(vehicle).state.fuel = 100.0
            local vehicleProperties = ESX.Game.GetVehicleProperties(vehicle)
            if Config.EnableCarKeys then
                spawnedVehiclePlate = vehicleProperties.plate
                -- Example: exports.wasabi_carlock:GiveKeys(vehicleProperties.plate, false)
                -- Insert give car keys export here
            end
            spawnedVehicle = vehicle
        end)
        inService = true
    else
        lib.notify({
            title = Notifications.title,
            description = Notifications.towTruckSpawnOccupied,
            icon = Notifications.icon,
            type = 'error',
            position = Notifications.position
        })
    end
end

-- Prompt asking if players want to continue doing jobs
function startNextJob()
    local confirmNext = lib.alertDialog({
        header = AlertDialog.header,
        content = AlertDialog.content,
        centered = true,
        cancel = true,
        labels = {
            cancel = 'End Job',
            confirm = 'Continue'
        }
    })
    if confirmNext == 'confirm' then
        return lib.notify({ title = Notifications.title, description = Notifications.confirmNextJob, icon = Notifications.icon, type = 'success', position = Notifications.position })
    else
        endJob()
    end
end

-- Function that selects a random car & spawn location from the Config
function selectCarAndLocation()
    randomLoc = math.random(1, #Config.Locations)
    selectLoc = Config.Locations[randomLoc]
    randomCar = math.random(1, #Config.CarModels)
    selectCar = Config.CarModels[randomCar]
end

-- Function that spawns the vehicle and sets the waypoint when job is selected
function setWaypoint()
    selectCarAndLocation()
    local nearbyVehicles = lib.getClosestVehicle(vec3(selectLoc.x, selectLoc.y, selectLoc.z), 5, false)
    if nearbyVehicles == nil then
        ESX.Game.SpawnVehicle(selectCar, vector3(selectLoc.x, selectLoc.y, selectLoc.z), selectLoc.h, function(vehicle) 
            ESX.Game.SetVehicleProperties(vehicle, {
                bodyHealth = 15,
                engineHealth = 15,
                dirtLevel = 10,
                SetVehicleDoorOpen(vehicle, 4, false, false)
            })
            missionVehProperties = ESX.Game.GetVehicleProperties(vehicle)
            selectCar = vehicle
        end)
        SetNewWaypoint(selectLoc.x, selectLoc.y, selectLoc.z)
        jobAssigned = true
        lib.notify({
            title = Notifications.title,
            description = Notifications.jobAssigned,
            icon = Notifications.icon,
            type = 'success',
            position = Notifications.position
        })
    else
        lib.notify({
            title = Notifications.title,
            description = Notifications.searchingForJob,
            icon = Notifications.icon,
            type = 'warning',
            position = Notifications.position
        })
    end
end

-- Function that updates waypoint to delivery location once a car has been loaded
function deliverVehicle()
    SetNewWaypoint(Config.DeliverLocation)
end

-- Function that runs when the job is ended (remove waypoint, delete vehicles, remove keys, etc)
function endJob()
    DeleteWaypoint()
    ESX.Game.DeleteVehicle(spawnedVehicle)
    ESX.Game.DeleteVehicle(selectCar)
    if Config.EnableCarKeys then
        -- Example: exports.wasabi_carlock:RemoveKeys(spawnedVehiclePlate, false)
        -- Insert remove car keys export here
    end
    inService = false
    enabledCalls = false
    jobAssigned = false
end

-- Thread that runs and randomly assigns job while player is inService
CreateThread(function()
    while true do
        Wait(2000)
        if enabledCalls then -- checks if "clocked in"
            if inService and not jobAssigned then -- if spawned truck, "clocked in" and no job assigned then assign job
                local jobCall = math.random(Config.MinWaitTime * 60000, Config.MaxWaitTime * 60000)
                Wait(jobCall)
                setWaypoint()
            elseif inService and jobAssigned then -- if spawned truck, "clocked in" and has job then wait
                Wait(10000)
            end
        else -- if not meeting above parameters, just wait
            Wait(10000)
        end
    end
end)

-- Function that attaches the target vehicle to the tow truck
function attachVehicle()
    towVehicle = GetVehiclePedIsIn(cache.ped, true)
    local towTruckModel = GetHashKey('flatbed')
    local isVehicleTowTruck = IsVehicleModel(towVehicle, towTruckModel)
    local ped = GetEntityCoords(cache.ped)
    if isVehicleTowTruck then
        targetVehicle = lib.getClosestVehicle(ped, 5, false)
        targetVehicleProperties = ESX.Game.GetVehicleProperties(targetVehicle)
        if currentlyTowedVehicle == nil then
            if targetVehicle ~= 0 then
                if not IsPedInAnyVehicle(playerPed, true) then
                    if towVehicle ~= targetVehicle then
                        if lib.progressCircle({
                            label = ProgressCircle.loadVehicleLabel,
                            duration = ProgressCircle.loadVehicleDuration,
                            position = ProgressCircle.position,
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            },
                            anim = {
                                dict = 'anim@apt_trans@buzzer', -- or random@mugging4
                                clip = 'buzz_reg' -- or struggle_loop_b_thief
                            },
                        }) then
                            if targetVehicleProperties.plate == missionVehProperties.plate then
                                deliverVehicle()
                            end
                            AttachEntityToEntity(targetVehicle, towVehicle, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                            currentlyTowedVehicle = targetVehicle
                            SetVehicleDoorShut(currentlyTowedVehicle, 4, true)
                            lib.notify({
                                title = Notifications.title,
                                description = Notifications.successfulVehicleLoad,
                                type = 'success',
                                icon = Notifications.icon,
                                position = Notifications.position
                            })
                        else
                            lib.notify({
                                title = Notifications.title,
                                description = Notifications.cancelledVehicleLoad,
                                type = 'error',
                                icon = Notifications.icon,
                                position = Notifications.position
                            })
                        end
                    else
                        lib.notify({
                            title = Notifications.title,
                            description = Notifications.notCloseEnough,
                            type = 'error',
                            icon = Notifications.icon,
                            position = Notifications.position
                        })
                    end
                end
            else
                lib.notify({
                    title = Notifications.title,
                    description = Notifications.error,
                    type = 'error',
                    icon = Notifications.icon,
                    position = Notifications.position
                })
            end
        end
    end
end

-- Function that removes the towed vehicle from the tow truck
function detachVehicle()
    if currentlyTowedVehicle == nil then 
        return lib.notify({ id = 'noVehicleToUnload', title = Notifications.title, description = Notifications.noVehicleToUnload, icon = Notifications.icon, type = 'warning', position = Notifications.position })
    end
    if lib.progressCircle({
        label = ProgressCircle.unloadVehicleLabel,
        duration = ProgressCircle.unloadVehicleDuration,
        position = ProgressCircle.position,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@apt_trans@buzzer',
            clip = 'buzz_reg'
        },
    }) then
        AttachEntityToEntity(currentlyTowedVehicle, towVehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
        DetachEntity(currentlyTowedVehicle, true, true)
        if inService then
            if targetVehicleProperties.plate == missionVehProperties.plate then
                local pedCoords = GetEntityCoords(cache.ped)
                if GetDistanceBetweenCoords(pedCoords, Config.DeliverLocation, true) < Config.DeliverRadius then
                    DeleteEntity(currentlyTowedVehicle)
                    lib.callback.await('lation_towtruck:payPlayer')
                    startNextJob()
                    jobAssigned = false
                else
                    lib.notify({
                        title = Notifications.title,
                        description = Notifications.tooFarToDeliver,
                        type = 'error',
                        icon = Notifications.icon,
                        position = Notifications.position
                    })
                end
            end
        end
        if currentlyTowedVehicle ~= nil then
            lib.notify({
                title = Notifications.title,
                description = Notifications.sucessfulVehicleUnload,
                type = 'success',
                icon = Notifications.icon,
                position = Notifications.position
            })
        currentlyTowedVehicle = nil
        end
    else
        lib.notify({
            title = Notifications.title,
            description = Notifications.cancelledVehicleUnload,
            type = 'error',
            icon = Notifications.icon,
            position = Notifications.position
        })
    end
end

-- Target options to be applied to the tow truck
local towTargetOptions = {
    {
        name = 'loadVehicle',
        icon = Target.loadVehicleIcon,
        label = Target.loadVehicle,
        onSelect = function()
            attachVehicle()
        end,
        distance = Target.distance
    },
    {
        name = 'unloadVehicle',
        icon = Target.unloadVehicleIcon,
        label = Target.unloadVehicle,
        onSelect = function()
            detachVehicle()
        end,
        distance = Target.distance
    }
}

-- Target options on start job ped
local startTowJobOptions = {
    {
        name = 'talkToStart',
        icon = Target.startJobIcon,
        label = Target.startJob,
        onSelect = function()
            openJobMenu()
        end,
        distance = Target.distance
    },
}

-- Function that opens the job menu to start working, etc
function openJobMenu()
    enabledCalls = enabledCalls
    local jobMenu = {
        {
            title = ContextMenu.towTruckTitle,
            description = ContextMenu.towTruckDescription,
            icon = ContextMenu.towTruckIcon,
            onSelect = function()
                spawnTowTruck()
            end
        },
        {
            title = ContextMenu.clockInTitle,
            description = not enabledCalls and ContextMenu.clockInDescription or ContextMenu.clockInDescription2,
            icon = ContextMenu.clockInIcon,
            onSelect = function()
                enabledCalls = true
                lib.notify({
                    title = Notifications.title,
                    description = Notifications.clockedIn,
                    icon = Notifications.icon,
                    type = 'success',
                    position = Notifications.position
                })
            end,
            disabled = enabledCalls and true or false
        },
        {
            title = ContextMenu.clockOutTitle,
            description = enabledCalls and ContextMenu.clockOutDescription or ContextMenu.clockOutDescription2,
            icon = ContextMenu.clockOutIcon,
            onSelect = function()
                inService = false
                jobAssigned = false
                enabledCalls = false
                endJob()
            end,
            disabled = not enabledCalls and true or enabledCalls and false
        }
    }
    lib.registerContext({
        id = 'towJobStartMenu',
        title = ContextMenu.menuTitle,
        options = jobMenu
    })
    lib.showContext('towJobStartMenu')
end

-- Applies the target options above to the flatbed model
ox_target:addModel('flatbed', towTargetOptions)

-- Spawns the ped & applies the target to the ped a when player enters the configured radius
function towJobStartLocation:onEnter()
    spawnTowJobNPC()
    ox_target:addLocalEntity(createTowJobNPC, startTowJobOptions)
end

-- Deletes the ped & target option when a player leaves the configured radius
function towJobStartLocation:onExit()
    DeleteEntity(createTowJobNPC)
    ox_target:removeLocalEntity(createTowJobNPC, nil)
end

-- Function that handles the actual spawning of the ped, etc
function spawnTowJobNPC()
    lib.RequestModel(Config.StartJobPedModel)
    createTowJobNPC = CreatePed(0, Config.StartJobPedModel, Config.StartJobLocation, Config.StartJobPedHeading, false, true)
    FreezeEntityPosition(createTowJobNPC, true)
    SetBlockingOfNonTemporaryEvents(createTowJobNPC, true)
    SetEntityInvincible(createTowJobNPC, true)
end