local function startMedicJob()
    if ESX.PlayerData.job.name == 'ambulance' then
        print('start')
        GetRandomLocalizations()
    else
        ESX.ShowNotification('Nie jesteś medykiem!')
    end
end

local function GetRandomLocalizations()
    return Config.Localizations[math.random(1, #Config.Localizations)]
end