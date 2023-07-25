-- Stuff
local qtarget = exports.qtarget
local towJobStartLocation = lib.points.new(Config.StartJobLocation, Config.StartJobRadius)
local targetVehicle, currentlyTowedVehicle, towVehicle, inService, spawnedVehicle, spawnedVehiclePlate
local jobAssigned, enabledCalls, car, location, targetCarBlip, dropOffBlip

local blip = AddBlipForCoord(Config.StartJobLocation)
SetBlipSprite(blip, Config.Blips.startJob.blipSprite)
SetBlipDisplay(blip, 4)
SetBlipColour(blip, Config.Blips.startJob.blipColor)
SetBlipScale(blip, Config.Blips.startJob.blipScale)
SetBlipAsShortRange(blip, true)
BeginTextCommandSetBlipName("STRING")
AddTextComponentString(Config.Blips.startJob.blipName)
EndTextCommandSetBlipName(blip)

-- Function that spawns the tow truck at the job start location
function spawnTowTruck()
    local nearbyVehicles = lib.getClosestVehicle(Config.SpawnTruckLocation, 3, false)
    if nearbyVehicles == nil then
        lib.requestModel('flatbed')
        vehicle = CreateVehicle('flatbed', Config.SpawnTruckLocation, Config.SpawnTruckHeading, true, true)
        Entity(vehicle).state.fuel = 100.0
        local truckPlate = GetVehicleNumberPlateText(vehicle)
        if Config.Framework == 'qbcore' then
            TriggerEvent('qb-vehiclekeys:client:AddKeys', truckPlate)
        end
        if Config.EnableCarKeys then
            spawnedVehiclePlate = truckPlate
            -- Example: exports.wasabi_carlock:GiveKeys(spawnedVehiclePlate, false)
            -- Insert give car keys export here
        end
        spawnedVehicle = vehicle
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
    local randomLoc = math.random(1, #Config.Locations)
    local selectLoc = Config.Locations[randomLoc]
    local randomCar = math.random(1, #Config.CarModels)
    local selectCar = Config.CarModels[randomCar]
    return selectCar, selectLoc
end

-- Function that spawns the vehicle and sets the waypoint when job is selected
function setWaypoint()
    car, location = selectCarAndLocation()
    local nearbyVehicles = lib.getClosestVehicle(vec3(location.x, location.y, location.z), 5, false)
    if nearbyVehicles == nil then
        lib.requestModel(car)
        vehicle = CreateVehicle(car, location.x, location.y, location.z, location.h, true, true)
        SetVehicleDoorOpen(vehicle, 4, false, false)
        SetVehicleEngineHealth(vehicle, 200)
        SetVehicleBodyHealth(vehicle, 200)
        SetVehicleDirtLevel(vehicle, 12.0)
        missionVehPlate = GetVehicleNumberPlateText(vehicle)
        car = vehicle
        -- Set waypoint & create blip
        SetNewWaypoint(location.x, location.y)
        targetCarBlip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(targetCarBlip, Config.Blips.pickupVehicle.blipSprite)
        SetBlipDisplay(targetCarBlip, 4)
        SetBlipColour(targetCarBlip, Config.Blips.pickupVehicle.blipColor)
        SetBlipScale(targetCarBlip, Config.Blips.pickupVehicle.blipScale)
        SetBlipAsShortRange(targetCarBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blips.pickupVehicle.blipName)
        EndTextCommandSetBlipName(targetCarBlip)
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

-- Function that runs when the job is ended (remove waypoint, delete vehicles, remove keys, etc)
function endJob()
    DeleteWaypoint()
    DeleteEntity(spawnedVehicle)
    DeleteEntity(car)
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
        targetVehiclePlate = GetVehicleNumberPlateText(targetVehicle)
        if currentlyTowedVehicle == nil then
            if targetVehicle ~= 0 then
                if not IsPedInAnyVehicle(cache.ped, true) then
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
                            AttachEntityToEntity(targetVehicle, towVehicle, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                            currentlyTowedVehicle = targetVehicle
                            if targetVehiclePlate == missionVehPlate then
                                RemoveBlip(targetCarBlip)
                                SetVehicleDoorShut(targetVehicle, 4, true)
                                SetNewWaypoint(Config.DeliverLocation.x, Config.DeliverLocation.y)
                                dropOffBlip = AddBlipForCoord(Config.DeliverLocation.x, Config.DeliverLocation.y, Config.DeliverLocation.z)
                                SetBlipSprite(dropOffBlip, Config.Blips.dropOff.blipSprite)
                                SetBlipDisplay(dropOffBlip, 4)
                                SetBlipColour(dropOffBlip, Config.Blips.dropOff.blipColor)
                                SetBlipScale(dropOffBlip, Config.Blips.dropOff.blipScale)
                                SetBlipAsShortRange(dropOffBlip, true)
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString(Config.Blips.dropOff.blipName)
                                EndTextCommandSetBlipName(dropOffBlip)
                            end
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
            if targetVehiclePlate == missionVehPlate then
                local verifyLocation = lib.callback.await('lation_towtruck:checkDistance', false)
                if verifyLocation then
                    RemoveBlip(dropOffBlip)
                    DeleteEntity(currentlyTowedVehicle)
                    local success = lib.callback.await('lation_towtruck:payPlayer')
                    if success then
                        startNextJob()
                        jobAssigned = false
                    end
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
            disabled = not inService and true or enabledCalls and true
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
    if Config.JobLock then
        local jobCheck = lib.callback.await('lation_towtruck:checkJob', false)
        if jobCheck then
            lib.showContext('towJobStartMenu')
        else
            lib.notify({
                title = Notifications.title,
                description = Notifications.notAuthorized,
                icon = Notifications.icon,
                type = 'error',
                position = Notifications.position
            })
        end
    else
        lib.showContext('towJobStartMenu')
    end
end

-- Applies the target options above to the flatbed model
qtarget:AddTargetModel('flatbed', {
    options = {
        {
            name = 'loadVehicle',
            icon = Target.loadVehicleIcon,
            label = Target.loadVehicle,
            action = function()
                attachVehicle()
            end,
            distance = Target.distance
        },
        {
            name = 'unloadVehicle',
            icon = Target.unloadVehicleIcon,
            label = Target.unloadVehicle,
            action = function()
                detachVehicle()
            end,
            distance = Target.distance
        }
    }
})

-- Spawns the ped & applies the target to the ped a when player enters the configured radius
function towJobStartLocation:onEnter()
    spawnTowJobNPC()
    qtarget:AddTargetEntity(createTowJobNPC, {
        options = {
            {
                name = 'talkToStart',
                icon = Target.startJobIcon,
                label = Target.startJob,
                action = function()
                    openJobMenu()
                end,
                distance = Target.distance
            }
        }
    })
end

-- Deletes the ped & target option when a player leaves the configured radius
function towJobStartLocation:onExit()
    DeleteEntity(createTowJobNPC)
    qtarget:RemoveTargetEntity(createTowJobNPC, nil)
end

-- Function that handles the actual spawning of the ped, etc
function spawnTowJobNPC()
    lib.RequestModel(Config.StartJobPedModel)
    createTowJobNPC = CreatePed(0, Config.StartJobPedModel, Config.StartJobLocation, Config.StartJobPedHeading, false, true)
    FreezeEntityPosition(createTowJobNPC, true)
    SetBlockingOfNonTemporaryEvents(createTowJobNPC, true)
    SetEntityInvincible(createTowJobNPC, true)
end