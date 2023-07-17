ESX.RegisterServerCallback('niko-medic-rewards', function(source, cb)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local random = math.random(Config.MedicRewardMoney.min, Config.MedicRewardMoney.max)

    xPlayer.addInventoryItem('money', random)
end)