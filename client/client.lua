local waypointBlip = nil
local created_ped = nil
local variables = {
    coords = nil,
    model_ped = nil,
    ped_spawn = false,
    target_check = false,
}

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local repeater = 0
    repeat
        Wait(1)
        repeater = HasAnimDictLoaded(dict)
    until (repeater == 1)
end

Citizen.CreateThread(function()
    local repeater = 0
    modelHash = GetHashKey('s_m_m_doctor_01')
    RequestModel(modelHash)
     repeat
     Wait(50)
     repeater = HasModelLoaded(modelHash)
     until(repeater == 1)
     peds_ambulance = CreatePed(0, 's_m_m_doctor_01', 301.3128, -600.1235, 43.28405 -1, 344.0687)
     FreezeEntityPosition(peds_ambulance, true)
     SetEntityInvincible(peds_ambulance, true)
     SetBlockingOfNonTemporaryEvents(peds_ambulance, true)
end)

local function GetRandomLocalizations()
    return Config.Localizations[math.random(1, #Config.Localizations)]
end

local function GetRandomPedModel()
    return Config.PedsModel[math.random(1, #Config.PedsModel)]
end

local function spawnPed()
    local timer = math.random(Config.TimeQuest.min, Config.TimeQuest.max)
    Wait(timer*60000)
    ESX.ShowNotification('Przyjęto nowe zlecenie, lokalizacja zaznaczona na GPS!')
    variables.target_check = true
    variables.coords = GetRandomLocalizations()
    variables.model_ped = GetRandomPedModel()
    variables.ped_spawn = true
    created_ped = CreatePed(0, variables.model_ped, variables.coords.x, variables.coords.y, variables.coords.z -1, variables.coords.w)
    FreezeEntityPosition(created_ped, true)
    SetEntityInvincible(created_ped, true)
    SetBlockingOfNonTemporaryEvents(created_ped, true)
    RequestAnimDict("combat@damage@writheidle_b")
    TaskPlayAnim(created_ped, "combat@damage@writheidle_b", "writhe_idle_f", 100.0, 100.0, 0.3, 10, 0.2, variables.coords.x, variables.coords.y, variables.coords.z)
    
    waypointBlip = AddBlipForCoord(variables.coords.x, variables.coords.y, variables.coords.z)
    SetBlipSprite(waypointBlip, 480)
    SetBlipColour(waypointBlip, 5)
    SetBlipRoute(waypointBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Lokalne Zgłoszenie")
    EndTextCommandSetBlipName(waypointBlip)

    exports.qtarget:AddBoxZone("ped_help_medic", vector3(variables.coords.x, variables.coords.y, variables.coords.z), 0.8, 0.8, {
        name="ped_help_medic",
        heading=variables.coords.w,
        minZ=variables.coords.z-0.6,
        maxZ=variables.coords.z+0.6
        }, {
            options = {
                {
                    action = function()
                        pedInteract()
                    end,
                    icon = "fas fa-hands",
                    label = "Pomóż Obywatelowi",
                    job = "ambulance",
                    canInteract = function()
                        return variables.target_check
                    end,
                },
                },
            distance = 2.5
        })

end

local function startMedicJob()
    if ESX.PlayerData.job.name == 'ambulance' then
        ESX.ShowNotification('Rozpoczęto Pracę Lokalną, oczekuj na zgłoszenia, zajmuje to zazwyczaj od 5 do 10 minut.')
        spawnPed()
    else
        ESX.ShowNotification('Nie jesteś medykiem!')
    end
end

local function stopMedicJob()
    if ESX.PlayerData.job.name == 'ambulance' then
        ESX.ShowNotification('Zakończono Pracę')
        variables.target_check = false
        RemoveBlip(waypointBlip)
        DeletePed(created_ped)
        exports.qtarget:RemoveZone('ped_help_medic')
    end
end

function pedInteract()
    variables.target_check = false
    RequestAnimDict('amb@medic@standing@kneel@base')
    TaskPlayAnim(PlayerPedId(), 'amb@medic@standing@kneel@base', 'base', 100.0, 100.0, 0.3, 10, 0.2, false, false, false)
    TriggerEvent("wait_taskbar:progress", {
        name = "medic_local",
        duration = 15000,
        label = "Leczenie",
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
    }, function(wasCancelled)
        if not wasCancelled then
            ClearPedTasks(PlayerPedId())
            ESX.TriggerServerCallback('niko-medic-rewards', function(cb)
            end)
            RemoveBlip(waypointBlip)
            DeletePed(created_ped)
            exports.qtarget:RemoveZone('ped_help_medic')
            ESX.ShowNotification('Pomogłeś Obywatelowi oczekuj na kolejne zlecenie.')
            spawnPed()
        end
    end)
end

Citizen.CreateThread(function()
    exports.qtarget:AddBoxZone("PillboxBossMenu", vector3(301.3128, -600.1235, 43.28405), 1.00, 2.5, {
        name = "PillboxBossMenu",
        heading = 344.0687,
        debugPoly = false,
    }, {
        options = {
            {
                action = function()
                    startMedicJob()
                end,
                icon = "fa-solid fa-right-to-bracket",
                label = "Rozpocznij Pracę Dorywcze",
                job = "ambulance",
            },
            {
                action = function()
                    stopMedicJob()
                end,
                icon = "fa-solid fa-right-to-bracket",
                label = "Zakończ Pracę Dorywcze",
                job = "ambulance",
            },
        },
        distance = 2.0
    })
end)