BountyHuntedMotionTracker = {}
local BountyHuntedMotionTracker = BountyHuntedMotionTracker
BountyHuntedMotionTracker.ShouldPlayVeryFastSound 		= false
BountyHuntedMotionTracker.ShouldPlayFastSound 			= false
BountyHuntedMotionTracker.ShouldPlayNormalSound 		= false
BountyHuntedMotionTracker.ShouldPlaySlowSound 			= false
BountyHuntedMotionTracker.ShouldPlayVerySlowSound 		= false
BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound 	= false

local hbd = LibStub("HereBeDragons-2.0")

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function BountyHuntedMotionTracker.OnEvent(self, event, arg1, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		BountyHuntedMotionTracker.MainFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		BountyHuntedMotionTracker.StartScanner()
		
		BountyHuntedMotionTracker.StartVeryFastTimer()
		BountyHuntedMotionTracker.StartFastTimer()
		BountyHuntedMotionTracker.StartNormalTimer()
		BountyHuntedMotionTracker.StartSlowTimer()
		BountyHuntedMotionTracker.StartVerySlowTimer()
		BountyHuntedMotionTracker.StartVeryVerySlowTimer()
	end
end

function BountyHuntedMotionTracker.GetPlayerPosition()
	x, y, currentPlayerUIMapID = hbd:GetPlayerZonePosition()
	return x, y, currentPlayerUIMapID
end

function BountyHuntedMotionTracker.GetDistanceTo(zone, pX, pY, tX, tY)
	return hbd:GetZoneDistance(zone, pX, pY, zone, tX, tY)
end

function BountyHuntedMotionTracker.GetVignettes()
	vignettes = {}
	pX, pY, zone = BountyHuntedMotionTracker.GetPlayerPosition()
	
	if WorldMapFrame.pinPools and WorldMapFrame.pinPools.VignettePinTemplate and WorldMapFrame.pinPools.VignettePinTemplate.activeObjects then
		for vignette,_ in pairs(WorldMapFrame.pinPools.VignettePinTemplate.activeObjects) do
			vX, vY = vignette:GetPosition()
			distance = BountyHuntedMotionTracker.GetDistanceTo(zone, pX, pY, vX, vY)
			vignette.DistanceToPlayer = distance
			table.insert(vignettes, vignette)
		end
	end
	
	--if WorldMapFrame.pinPools and WorldMapFrame.pinPools.WorldMap_WorldQuestPinTemplate and WorldMapFrame.pinPools.WorldMap_WorldQuestPinTemplate.activeObjects then
	--	for vignette,_ in pairs(WorldMapFrame.pinPools.WorldMap_WorldQuestPinTemplate.activeObjects) do
	--		vX, vY = vignette:GetPosition()
	--		distance = BountyHuntedMotionTracker.GetDistanceTo(zone, pX, pY, vX, vY)
	--		vignette.DistanceToPlayer = distance
	--		table.insert(vignettes, vignette)
	--	end
	--end
	
	return vignettes
end

function BountyHuntedMotionTracker.OrderVignettesByDistance()
	vignetteOrderDistance = {}
	
	for _, vignette in spairs(BountyHuntedMotionTracker.GetVignettes(), function(t, a, b) return t[b].DistanceToPlayer > t[a].DistanceToPlayer end) do
		table.insert(vignetteOrderDistance, vignette)
	end
	
	return vignetteOrderDistance
end

function BountyHuntedMotionTracker.GetClosestVignette()
	vignettes = BountyHuntedMotionTracker.OrderVignettesByDistance()
	if vignettes[1] then
		BountyHuntedMotionTracker.StartSoundIfNeeded(vignettes[1].DistanceToPlayer)
	else
		BountyHuntedMotionTracker.StopAllSounds()
	end
end

function BountyHuntedMotionTracker.StartSoundIfNeeded(distance)
	if distance <= 50 then
		BountyHuntedMotionTracker.StopAllSounds()
		BountyHuntedMotionTracker.ShouldPlayVeryFastSound = true
	elseif distance > 50 and distance <= 150 then
		BountyHuntedMotionTracker.StopAllSounds()
		BountyHuntedMotionTracker.ShouldPlayFastSound = true
	elseif distance > 150 and distance <= 250 then
		BountyHuntedMotionTracker.StopAllSounds()
		BountyHuntedMotionTracker.ShouldPlayNormalSound = true
	elseif distance > 250 and distance <= 350 then
		BountyHuntedMotionTracker.StopAllSounds()
		BountyHuntedMotionTracker.ShouldPlaySlowSound = true
	elseif distance > 350 and distance <= 450 then
		BountyHuntedMotionTracker.StopAllSounds()
		BountyHuntedMotionTracker.ShouldPlayVerySlowSound = true
	elseif distance > 450 then
		BountyHuntedMotionTracker.StopAllSounds()
		BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound = true
	else
		BountyHuntedMotionTracker.StopAllSounds()
	end
end

function BountyHuntedMotionTracker.StartScanner()
	C_Timer.NewTicker(1, BountyHuntedMotionTracker.GetClosestVignette)
end

function BountyHuntedMotionTracker.StopAllSounds()
	BountyHuntedMotionTracker.ShouldPlayVeryFastSound 		= false
	BountyHuntedMotionTracker.ShouldPlayFastSound 			= false
	BountyHuntedMotionTracker.ShouldPlayNormalSound 		= false
	BountyHuntedMotionTracker.ShouldPlaySlowSound 			= false
	BountyHuntedMotionTracker.ShouldPlayVerySlowSound 		= false
	BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound 	= false
end

function BountyHuntedMotionTracker.PlayVeryFastSound()
	if BountyHuntedMotionTracker.ShouldPlayVeryFastSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-5.mp3")
	end
end

function BountyHuntedMotionTracker.PlayFastSound()
	if BountyHuntedMotionTracker.ShouldPlayFastSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-4.mp3")
	end
end

function BountyHuntedMotionTracker.PlayNormalSound()
	if BountyHuntedMotionTracker.ShouldPlayNormalSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-3.mp3")
	end
end

function BountyHuntedMotionTracker.PlaySlowSound()
	if BountyHuntedMotionTracker.ShouldPlaySlowSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-2.mp3")
	end
end

function BountyHuntedMotionTracker.PlayVerySlowSound()
	if BountyHuntedMotionTracker.ShouldPlayVerySlowSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-1.mp3")
	end
end

function BountyHuntedMotionTracker.PlayVeryVerySlowSound()
	if BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-0.mp3")
	end
end

function BountyHuntedMotionTracker.StartVeryFastTimer()
	C_Timer.NewTicker(0.5, BountyHuntedMotionTracker.PlayVeryFastSound)
end

function BountyHuntedMotionTracker.StartFastTimer()
	C_Timer.NewTicker(1, BountyHuntedMotionTracker.PlayFastSound)
end

function BountyHuntedMotionTracker.StartNormalTimer()
	C_Timer.NewTicker(2, BountyHuntedMotionTracker.PlayNormalSound)
end

function BountyHuntedMotionTracker.StartSlowTimer()
	C_Timer.NewTicker(4, BountyHuntedMotionTracker.PlaySlowSound)
end

function BountyHuntedMotionTracker.StartVerySlowTimer()
	C_Timer.NewTicker(8, BountyHuntedMotionTracker.PlayVerySlowSound)
end

function BountyHuntedMotionTracker.StartVeryVerySlowTimer()
	C_Timer.NewTicker(16, BountyHuntedMotionTracker.PlayVeryVerySlowSound)
end

BountyHuntedMotionTracker.MainFrame = CreateFrame("Frame")
BountyHuntedMotionTracker.MainFrame:Hide()
BountyHuntedMotionTracker.MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
BountyHuntedMotionTracker.MainFrame:SetScript("OnEvent", BountyHuntedMotionTracker.OnEvent)
