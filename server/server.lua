if Config.Framework == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
else
    -- Custom framework
end

-- Event that is used to pay a player for a successful job
lib.callback.register('lation_towtruck:payPlayer', function(source)
    local source = source
    local player = nil
    if Config.RandomPayPerDelivery then
        if Config.Framework == 'esx' then
            player = ESX.GetPlayerFromId(source)
            local payAmount = math.random(Config.MinPayPerDelivery, Config.MaxPayPerDelivery)
            player.addAccountMoney(Config.PayPerDeliveryAccount, payAmount)
            return true
        elseif Config.Framework == 'qbcore' then
            player = QBCore.Functions.GetPlayer(source)
            local payAmount = math.random(Config.MinPayPerDelivery, Config.MaxPayPerDelivery)
            player.Functions.AddMoney(Config.PayPerDeliveryAccount, payAmount)
            return true
        else
            -- Custom framework
        end
    else
        if Config.Framework == 'esx' then
            player = ESX.GetPlayerFromId(source)
            player.addAccountMoney(Config.PayPerDeliveryAccount, Config.PayPerDelivery)
            return true
        elseif Config.Framework == 'qbcore' then
            player = QBCore.Functions.GetPlayer(source)
            player.Functions.AddMoney(Config.PayPerDeliveryAccount, Config.PayPerDelivery)
            return true
        else
            -- Custom framework
        end
    end
end)

-- Event that is used to check a players job if Config.JobLock is true
lib.callback.register('lation_towtruck:checkJob', function(source)
    local source = source
    local player = nil
    if Config.Framework == 'esx' then
        player = ESX.GetPlayerFromId(source)
        local playerJob = player.job.name
        if playerJob == Config.JobName then
            return true
        else
            return false
        end
    elseif Config.Framework == 'qbcore' then
        player = QBCore.Functions.GetPlayer(source)
        local playerJob = player.PlayerData.job.name
        if playerJob == Config.JobName then
            return true
        else
            return false
        end
    else
        -- Custom framework
    end
end)

-- Event that is used to check a players distance relative to delivery location before payment
lib.callback.register('lation_towtruck:checkDistance', function(source)
    local player = GetPlayerPed(source)
    local playerPos = GetEntityCoords(player)
    local distance = #(playerPos - Config.DeliverLocation)
    if distance < Config.DeliverRadius then
        return true
    end
    return false
end)