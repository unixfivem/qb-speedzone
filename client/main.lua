local SpeedZone = 0
local affectedPeds = {}

local gRadius
local gKmh
local gPos

local function KMPHtoMPS(mps)
    if mps then return mps / 3.6 else return 0 end
end

local function SetSpeedZone()
    local pedsArr = GetGamePool('CPed')

    for k, v in pairs(pedsArr) do
        if not IsPedAPlayer(v) then
            local pedCoords = GetEntityCoords(v, true)
            local dist = #(gPos.xy - pedCoords.xy)
            local veh = GetVehiclePedIsIn(v, false)
            
            -- inside zone
            if veh ~= 0 then
                if dist <= tonumber(gRadius) then
                    if tonumber(gKmh) <= 0 then
                        FreezeEntityPosition(veh, true)
                    else
                        FreezeEntityPosition(veh, false)
                        SetVehicleMaxSpeed(veh, gKmh)
                    end
                    table.insert(affectedPeds, v)
                else
                    -- outside zone
                    FreezeEntityPosition(veh, false)
                    SetVehicleMaxSpeed(veh, 0) -- reset maxspeed
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        if SpeedZone ~= 0 then
            SetSpeedZone()
        end
        Wait(1000)
    end
end)

local function RemoveSpeedZone()
    RemoveBlip(SpeedZone)

    for i, v in ipairs(affectedPeds) do
        local veh = GetVehiclePedIsIn(v, false)
        FreezeEntityPosition(veh, false)
        SetVehicleMaxSpeed(veh, 0)
    end
    affectedPeds = {}
    SpeedZone = 0
end

RegisterCommand("endspeedzone", function(source, args)
    if SpeedZone ~= 0 then
        RemoveSpeedZone()
        TriggerEvent('QBCore:Notify', "You've removed your speedzone.")
    else
        TriggerEvent('QBCore:Notify', "You don't have any active speedzone, use /speedzone.", "error")
    end
end)

RegisterCommand("speedzone", function(source, args)
    if not args[1] or not args[2] then
        TriggerEvent('QBCore:Notify', "/speedzone [radius] [limit in kmh]")
    else
        if not tonumber(args[1]) or not tonumber(args[2]) then
            TriggerEvent('QBCore:Notify', "You have to enter valid numbers", "error")
            return
        end
        gKmh = KMPHtoMPS(tonumber(args[2]))
        
        gPos = GetEntityCoords(PlayerPedId())        
        gRadius = args[1]

        if SpeedZone ~= 0 then
            RemoveSpeedZone()
        end
        
        SetSpeedZone()

        local radius = ToFloat(tonumber(args[1]))
        local blip = AddBlipForRadius(gPos, radius)
        SpeedZone = blip
    
        FlashMinimapDisplay()
    
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, 128)
        SetBlipFlashInterval(blip, 500)
        SetBlipFlashes(blip, true)
    
        TriggerEvent('QBCore:Notify', "Use /endspeedzone to remove the speedzone", "primary", 7000)
        TriggerEvent('QBCore:Notify', "You've set a speedzone of " .. tonumber(args[2]) .. ' km/h in a radius of ' .. args[1], "success")
    end
end)
