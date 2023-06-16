lib.callback.register('lation_towtruck:payPlayer', function()
    local source = source
    local ped = ESX.GetPlayerFromId(source)
    if Config.RandomPayPerDelivery then
        local payAmount = math.random(Config.MinPayPerDelivery, Config.MaxPayPerDelivery)
        ped.addAccountMoney(Config.PayPerDeliveryAccount, payAmount)
    else
        ped.addAccountMoney(Config.PayPerDeliveryAccount, Config.PayPerDelivery)
    end
end)