BountyHuntedMotionTracker = LibStub("AceAddon-3.0"):NewAddon("BountyHuntedMotionTracker", "AceConsole-3.0", "AceEvent-3.0")

BountyHuntedMotionTracker.ShouldPlayVeryFastSound 		= false
BountyHuntedMotionTracker.ShouldPlayFastSound 			= false
BountyHuntedMotionTracker.ShouldPlayNormalSound 		= false
BountyHuntedMotionTracker.ShouldPlaySlowSound 			= false
BountyHuntedMotionTracker.ShouldPlayVerySlowSound 		= false
BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound 	= false
BountyHuntedMotionTracker.Bounties = {}
BountyHuntedMotionTracker.Frame = nil
BountyHuntedMotionTracker.LastTrackerRefresh = 0
BountyHuntedMotionTracker.TrackerWidgetPool = {}

local defaults = {
    profile = {
        channel = "Master"
    },
}

local options = { 
    name = "Bounty Hunted Motion Tracker",
    handler = BountyHuntedMotionTracker,
    type = "group",
    args = {
		general = {
			type = "group",
			name = "General",
			args = {
				channel = {
					type = "select",
					name = "Sound Channel",
					desc = "The sound channel to use.",
					values = function()
						sound_channels = {
							["Master"] = "Master",
							["SFX"] = "SFX",
							["Ambience"] = "Ambience",
							["Music"] = "Music"
						}
						return sound_channels
					end,
					get = function(info) return BountyHuntedMotionTracker.db.profile.channel end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.channel = val end
				},
			}
		},
		profiles = {
			type = "group",
			name = "Profiles",
			args = {}
		}
    },
}

local hbd = LibStub("HereBeDragons-2.0")

function BountyHuntedMotionTracker:Refresh()
	db = self.db.profile
end

function BountyHuntedMotionTracker:OnInitialize()
    -- Called when the addon is loaded
	self.db = LibStub("AceDB-3.0"):New("BountyHuntedMotionTrackerDB", defaults, true);
	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
	
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("BountyHuntedMotionTracker", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BountyHuntedMotionTracker", "Bounty Hunted Motion Tracker")
    self:RegisterChatCommand("bountyhunted", "ChatCommand")
    self:RegisterChatCommand("bh", "ChatCommand")
end

function BountyHuntedMotionTracker:OnEnable()
    -- Called when the addon is enabled
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("VIGNETTES_UPDATED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function BountyHuntedMotionTracker:OnDisable()
    -- Called when the addon is disabled
	BountyHuntedMotionTracker.StopScanner()
end

function BountyHuntedMotionTracker:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("bh", "BountyHuntedMotionTracker", input)
    end
end

function BountyHuntedMotionTracker:VIGNETTES_UPDATED()
	if (C_PvP.IsWarModeActive() == true) then
		BountyHuntedMotionTracker.GetClosestVignette()

function BountyHuntedMotionTracker:ZONE_CHANGED_NEW_AREA()
	if (C_PvP.IsWarModeActive() == true) then
		BountyHuntedMotionTracker.Bounties = {}
		BountyHuntedMotionTracker.RefreshTrackerWidgets()
	end
end

function BountyHuntedMotionTracker:PLAYER_ENTERING_WORLD()
	BountyHuntedMotionTracker.StartVeryFastTimer()
	BountyHuntedMotionTracker.StartFastTimer()
	BountyHuntedMotionTracker.StartNormalTimer()
	BountyHuntedMotionTracker.StartSlowTimer()
	BountyHuntedMotionTracker.StartVerySlowTimer()
	BountyHuntedMotionTracker.StartVeryVerySlowTimer()
	BountyHuntedMotionTracker.BuildFrame()
end

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
			-- some sanity checking on the vignette
			name = vignette.vignetteInfo.atlasName
			if name == "poi-bountyplayer-alliance" or name == "poi-bountyplayer-horde" then
				vignette:UpdatePosition()
				vX, vY = vignette:GetPosition()
				distance = BountyHuntedMotionTracker.GetDistanceTo(zone, pX, pY, vX, vY)
				vignette.DistanceToPlayer = distance
				playerInfo = {}
				playerInfo.className, playerInfo.classId, playerInfo.raceName, playerInfo.raceId, playerInfo.gender, playerInfo.name, playerInfo.realm = GetPlayerInfoByGUID(vignette:GetObjectGUID())
				vignette.PlayerInfo = playerInfo
				table.insert(vignettes, vignette)
			end
		end
	end
	
	BountyHuntedMotionTracker.Bounties = vignettes
	return vignettes
	
	--if WorldMapFrame.pinPools and WorldMapFrame.pinPools.WorldMap_WorldQuestPinTemplate and WorldMapFrame.pinPools.WorldMap_WorldQuestPinTemplate.activeObjects then
	--	for vignette,_ in pairs(WorldMapFrame.pinPools.WorldMap_WorldQuestPinTemplate.activeObjects) do
	--		vX, vY = vignette:GetPosition()
	--		distance = BountyHuntedMotionTracker.GetDistanceTo(zone, pX, pY, vX, vY)
	--		vignette.DistanceToPlayer = distance
	--		table.insert(vignettes, vignette)
	--	end
	--end
end

function BountyHuntedMotionTracker.OrderVignettesByDistance()
	vignetteOrderDistance = {}
	
	for _, vignette in spairs(BountyHuntedMotionTracker.Bounties, function(t, a, b) return t[b].DistanceToPlayer > t[a].DistanceToPlayer end) do
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
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-5.mp3", BountyHuntedMotionTracker.db.profile.channel)
	end
end

function BountyHuntedMotionTracker.PlayFastSound()
	if BountyHuntedMotionTracker.ShouldPlayFastSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-4.mp3", BountyHuntedMotionTracker.db.profile.channel)
	end
end

function BountyHuntedMotionTracker.PlayNormalSound()
	if BountyHuntedMotionTracker.ShouldPlayNormalSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-3.mp3", BountyHuntedMotionTracker.db.profile.channel)
	end
end

function BountyHuntedMotionTracker.PlaySlowSound()
	if BountyHuntedMotionTracker.ShouldPlaySlowSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-2.mp3", BountyHuntedMotionTracker.db.profile.channel)
	end
end

function BountyHuntedMotionTracker.PlayVerySlowSound()
	if BountyHuntedMotionTracker.ShouldPlayVerySlowSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-1.mp3", BountyHuntedMotionTracker.db.profile.channel)
	end
end

function BountyHuntedMotionTracker.PlayVeryVerySlowSound()
	if BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound then
		PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-0.mp3", BountyHuntedMotionTracker.db.profile.channel)
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

local function getCoords(column, row)
	local xstart = (column * 56) / 512
	local ystart = (row * 42) / 512
	local xend = ((column + 1) * 56) / 512
	local yend = ((row + 1) * 42) / 512
	return xstart, xend, ystart, yend
end

local texcoords = setmetatable({}, {__index = function(t, k)
	local col,row = k:match("(%d+):(%d+)")
	col,row = tonumber(col), tonumber(row)
	local obj = {getCoords(col, row)}
	rawset(t, k, obj)
	return obj
end})

local TrackerOnTick = function (self, deltaTime)
	if (self.NextArrowUpdate < 0) then
	
		local pipi = math.pi*2

		local oX, oY = hbd:GetPlayerZonePosition()
		local angle, distance = hbd:GetWorldVector(_, 42.0, 71.0, oX * 100, oY * 100)
		local player = GetPlayerFacing()
		angle = angle - player
		
		local cell = floor(angle / pipi * 108 + 0.5) % 108
		local column = cell % 9
		local row = floor(cell / 9)

		local xstart = (column * 56) / 512
		local ystart = (row * 42) / 512
		local xend = ((column + 1) * 56) / 512
		local yend = ((row + 1) * 42) / 512
	
		self.arrow:SetTexCoord(xstart,xend,ystart,yend)
		self.playerDistance:SetText(floor(distance * 10) .. "y")
		self.NextArrowUpdate = 0.016
	else
		self.NextArrowUpdate = self.NextArrowUpdate - deltaTime
	end
end

function BountyHuntedMotionTracker.RefreshTrackerWidgets()

	if (BountyHuntedMotionTracker.LastTrackerRefresh and BountyHuntedMotionTracker.LastTrackerRefresh+0.2 > GetTime()) then
		return
	end
	BountyHuntedMotionTracker.LastTrackerRefresh = GetTime()
	
	local y = 0
	local nextWidget = 1
	
	local widget = BountyHuntedMotionTracker.GetOrCreateTrackerWidget(nextWidget)
	widget:ClearAllPoints()
	widget:SetPoint("TOP", BountyHuntedMotionTracker.Frame, "TOP", 0, y)
	widget.playerName:SetText("Player1")
	widget.playerRace:SetText("Undead")
	widget.playerDistance:SetText("150y")
	widget.playerClass:SetTexCoord(unpack(CLASS_ICON_TCOORDS["HUNTER"]));
	widget.NextArrowUpdate = -1
	widget:SetScript ("OnUpdate", TrackerOnTick)
	widget:Show()
	
	y = y - 50
	nextWidget = nextWidget + 1
	
	widget = BountyHuntedMotionTracker.GetOrCreateTrackerWidget(nextWidget)
	widget:ClearAllPoints()
	widget:SetPoint("TOP", BountyHuntedMotionTracker.Frame, "TOP", 0, y)
	widget.playerName:SetText("Player2")
	widget.playerRace:SetText("Tauren")
	widget.playerDistance:SetText("175y")
	widget.playerClass:SetTexCoord(unpack(CLASS_ICON_TCOORDS["PRIEST"]));
	widget.NextArrowUpdate = -1
	widget:SetScript ("OnUpdate", TrackerOnTick)
	widget:Show()
	
end

function BountyHuntedMotionTracker.GetOrCreateTrackerWidget(index)
	if (BountyHuntedMotionTracker.TrackerWidgetPool[index]) then
		return BountyHuntedMotionTracker.TrackerWidgetPool[index]
	end
	
	local f = CreateFrame("button", "BountyPanel" .. index, BountyHuntedMotionTracker.Frame)
	f:SetSize(230, 50)
	f:SetFrameStrata("LOW")
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
		tile = true, tileSize = 16, edgeSize = 16, 
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	f:SetBackdropColor(0, 0, 0)
	f:SetPoint("TOP", BountyHuntedMotionTracker.Frame, "TOP", 0, -30)

	f.playerName = f:CreateFontString("playerName", "OVERLAY")
	f.playerName:SetFontObject(ObjectiveFont)
	f.playerName:SetPoint("TOPLEFT", f, "TOPLEFT", 50, -12)
	f.playerName:SetText("NAME")
	
	f.playerRace = f:CreateFontString("playerRace", "OVERLAY")
	f.playerRace:SetFontObject(GameFontNormalSmall)
	f.playerRace:SetPoint("TOPLEFT", f, "TOPLEFT", 50, -27)
	f.playerRace:SetText("RACE")
	
	f.playerDistance = f:CreateFontString("playerRace", "OVERLAY")
	f.playerDistance:SetFontObject(GameFontNormalSmall)
	f.playerDistance:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 5)
	f.playerDistance:SetText("100y")
	f.playerDistance:SetAlpha(.5)
	
	f.playerClass = f:CreateTexture("playerClass", "ARTWORK")
    f.playerClass:SetWidth(25)
    f.playerClass:SetHeight(25)
    f.playerClass:SetPoint("TOPLEFT", 13, -12)
    f.playerClass:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
	f.playerClass:SetTexCoord(unpack(CLASS_ICON_TCOORDS["ROGUE"]));
	
	f.playerClassBorder = f:CreateTexture("playerClassBorder", "OVERLAY")
    f.playerClassBorder:SetWidth(64)
    f.playerClassBorder:SetHeight(64)
    f.playerClassBorder:SetPoint("TOPLEFT", 8, -7)
    f.playerClassBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	
	f.arrow = f:CreateTexture("playerArrow", "overlay")
	f.arrow:SetPoint("RIGHT", f, "RIGHT", -5, 1)
	f.arrow:SetSize(56, 42)
	f.arrow:SetAlpha(.6)
	f.arrow:SetTexture("Interface\\Addons\\\BountyHuntedMotionTracker\\images\\Arrow")
	
	return f
end


function BountyHuntedMotionTracker.BuildFrame()
	BountyHuntedMotionTracker.Frame = CreateFrame("frame", "BountyHuntedMotionTrackerScreenPanel", UIParent)
	BountyHuntedMotionTracker.Frame:SetSize(235, 175)
	BountyHuntedMotionTracker.Frame:SetFrameStrata("LOW")
	BountyHuntedMotionTracker.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	--BountyHuntedMotionTracker.Frame:SetBackdrop({
	--	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	--	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	--	tile = true, tileSize = 16, edgeSize = 16, 
	--	insets = { left = 4, right = 4, top = 4, bottom = 4 }
	--})
	BountyHuntedMotionTracker.Frame:SetBackdropColor(0, 0, 0)
	BountyHuntedMotionTracker.Frame:SetMovable(true)
	BountyHuntedMotionTracker.Frame:EnableMouse(true)
	
	BountyHuntedMotionTracker.Frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not self.isMoving then
			self:StartMoving();
			self.isMoving = true;
		end
	end)
	
	BountyHuntedMotionTracker.Frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and self.isMoving then
			self:StopMovingOrSizing();
			self.isMoving = false;
		end
	end)
	
	BountyHuntedMotionTracker.Frame:SetScript("OnHide", function(self)
		if ( self.isMoving ) then
			self:StopMovingOrSizing();
			self.isMoving = false;
		end
	end)
end