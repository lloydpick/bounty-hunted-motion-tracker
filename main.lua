BountyHuntedMotionTracker = LibStub("AceAddon-3.0"):NewAddon("BountyHuntedMotionTracker", "AceConsole-3.0", "AceEvent-3.0")

BountyHuntedMotionTracker.ShouldPlayVeryFastSound 	  = false
BountyHuntedMotionTracker.ShouldPlayFastSound 		  = false
BountyHuntedMotionTracker.ShouldPlayNormalSound 	  = false
BountyHuntedMotionTracker.ShouldPlaySlowSound 		  = false
BountyHuntedMotionTracker.ShouldPlayVerySlowSound 	  = false
BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound = false

BountyHuntedMotionTracker.Bounties			 = {}
BountyHuntedMotionTracker.Frame			     = nil
BountyHuntedMotionTracker.LastTrackerRefresh = 0
BountyHuntedMotionTracker.TrackerWidgetPool  = {}
BountyHuntedMotionTracker.MaxBounties		 = 10

local defaults = {
    profile = {
		channel = "Master",
		locked = false,
		sounds = false,
		veryfastsound = false,
		fastsound = true,
		normalsound = true,
		slowsound = true,
		veryslowsound = true,
		veryveryslowsound = true
    }
}

local options = { 
    name = "Bounty Hunted Motion Tracker",
    handler = BountyHuntedMotionTracker,
    type = "group",
    args = {
		ui = {
			type = "group",
			name = "User Interface",
			order = 1,
			args = {
				locked = {
					type = "toggle",
					width = "full",
					name = "Locked",
					desc = "Locks/Unlocks the Frame",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.locked end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.locked = val; BountyHuntedMotionTracker:ToggleFrame(); end
				}
			}
		},
		sound = {
			type = "group",
			name = "Sounds",
			order = 2,
			args = {
				sounds = {
					order = 1,
					type = "toggle",
					width = "full",
					name = "Enabled",
					desc = "Enables/Disables all the sounds",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.sounds end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.sounds = val end
				},
				channel = {
					order = 2,
					type = "select",
					width = "full",
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
				channeltext = {
					order = 3,
					type = "description",
					width = "full",
					name = "Select which sound channel you want alerts to be played through"
				},
				spacer = {
					order = 4,
					type = "description",
					width = "full",
					fontSize = "large",
					name = ""
				},
				soundsheader = {
					order = 5,
					type = "header",
					width = "full",
					name = "Individual Sound Effects"
				},
				veryfastsound = {
					order = 7,
					type = "toggle",
					width = "full",
					name = "Under 50 yards",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.veryfastsound end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.veryfastsound = val end
				},
				fastsound = {
					order = 8,
					type = "toggle",
					width = "full",
					name = "50-150 yards",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.fastsound end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.fastsound = val end
				},
				normalsound = {
					order = 9,
					type = "toggle",
					width = "full",
					name = "150-250 yards",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.normalsound end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.normalsound = val end
				},
				slowsound = {
					order = 10,
					type = "toggle",
					width = "full",
					name = "250-350 yards",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.slowsound end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.slowsound = val end
				},
				veryslowsound = {
					order = 11,
					type = "toggle",
					width = "full",
					name = "350-450 yards",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.veryslowsound end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.veryslowsound = val end
				},
				veryveryslowsound = {
					order = 12,
					type = "toggle",
					width = "full",
					name = "Over 450 yards",
					descStyle = "inline",
					get = function(info) return BountyHuntedMotionTracker.db.profile.veryveryslowsound end,
					set = function(info,val) BountyHuntedMotionTracker.db.profile.veryveryslowsound = val end
				}
			}
		},
		profiles = {
			type = "group",
			name = "Profiles",
			order = 3,
			args = {}
		}
    }
}

local hbd = LibStub("HereBeDragons-2.0")

function BountyHuntedMotionTracker:ToggleFrame()
	if BountyHuntedMotionTracker.db.profile.locked == true then
		BountyHuntedMotionTracker.Frame:SetBackdrop({})
		BountyHuntedMotionTracker.Frame:SetMovable(false)
		BountyHuntedMotionTracker.Frame:EnableMouse(false)
		BountyHuntedMotionTracker.Frame:RegisterForDrag(nil)
	else
		BountyHuntedMotionTracker.Frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = true, tileSize = 16, edgeSize = 16, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		BountyHuntedMotionTracker.Frame:SetBackdropColor(0, 0, 0)
		BountyHuntedMotionTracker.Frame:SetMovable(true)
		BountyHuntedMotionTracker.Frame:EnableMouse(true)
		BountyHuntedMotionTracker.Frame:RegisterForDrag("LeftButton")
	end
end

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
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("VIGNETTES_UPDATED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function BountyHuntedMotionTracker:OnDisable()
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
		BountyHuntedMotionTracker.GetVignettes()
		BountyHuntedMotionTracker.GetClosestVignette()
		BountyHuntedMotionTracker.RefreshTrackerWidgets()
	end
end

function BountyHuntedMotionTracker:ZONE_CHANGED_NEW_AREA()
	if (C_PvP.IsWarModeActive() == true) then
		BountyHuntedMotionTracker.Bounties = {}
		BountyHuntedMotionTracker.StopAllSounds()
				
		i = 1
		while i <= BountyHuntedMotionTracker.MaxBounties do
			local widget = BountyHuntedMotionTracker.GetOrCreateTrackerWidget(i)
			widget:Hide()
			i = i + 1
		end
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
				playerInfo.zoneId = vignette.owningMap:GetMapID()
				playerInfo.className, playerInfo.classId, playerInfo.raceName, playerInfo.raceId, playerInfo.gender, playerInfo.name, playerInfo.realm = GetPlayerInfoByGUID(vignette:GetObjectGUID())
				vignette.PlayerInfo = playerInfo
				table.insert(vignettes, vignette)
			end
		end
	end
	
	BountyHuntedMotionTracker.Bounties = vignettes
	return vignettes
end

function BountyHuntedMotionTracker.OrderVignettesByDistance()
	vignetteOrderDistance = {}
	
	for _, vignette in spairs(BountyHuntedMotionTracker.Bounties, function(t, a, b) return t[b].DistanceToPlayer > t[a].DistanceToPlayer end) do
	
		-- only return bounties in our current zone
		_, _, myPlayerZone = BountyHuntedMotionTracker.GetPlayerPosition()
		if vignette.PlayerInfo.zoneId == myPlayerZone then
			table.insert(vignetteOrderDistance, vignette)
		end
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
	if BountyHuntedMotionTracker.db.profile.sounds and BountyHuntedMotionTracker.db.profile.veryfastsound then
		if BountyHuntedMotionTracker.ShouldPlayVeryFastSound then
			PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-5.mp3", BountyHuntedMotionTracker.db.profile.channel)
		end
	end
end

function BountyHuntedMotionTracker.PlayFastSound()
	if BountyHuntedMotionTracker.db.profile.sounds and BountyHuntedMotionTracker.db.profile.fastsound then
		if BountyHuntedMotionTracker.ShouldPlayFastSound then
			PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-4.mp3", BountyHuntedMotionTracker.db.profile.channel)
		end
	end
end

function BountyHuntedMotionTracker.PlayNormalSound()
	if BountyHuntedMotionTracker.db.profile.sounds and BountyHuntedMotionTracker.db.profile.normalsound then
		if BountyHuntedMotionTracker.ShouldPlayNormalSound then
			PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-3.mp3", BountyHuntedMotionTracker.db.profile.channel)
		end
	end
end

function BountyHuntedMotionTracker.PlaySlowSound()
	if BountyHuntedMotionTracker.db.profile.sounds and BountyHuntedMotionTracker.db.profile.slowsound then
		if BountyHuntedMotionTracker.ShouldPlaySlowSound then
			PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-2.mp3", BountyHuntedMotionTracker.db.profile.channel)
		end
	end
end

function BountyHuntedMotionTracker.PlayVerySlowSound()
	if BountyHuntedMotionTracker.db.profile.sounds and BountyHuntedMotionTracker.db.profile.veryslowsound then
		if BountyHuntedMotionTracker.ShouldPlayVerySlowSound then
			PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-1.mp3", BountyHuntedMotionTracker.db.profile.channel)
		end
	end
end

function BountyHuntedMotionTracker.PlayVeryVerySlowSound()
	if BountyHuntedMotionTracker.db.profile.sounds and BountyHuntedMotionTracker.db.profile.veryveryslowsound then
		if BountyHuntedMotionTracker.ShouldPlayVeryVerySlowSound then
			PlaySoundFile("Interface\\AddOns\\BountyHuntedMotionTracker\\sound\\aliens-0.mp3", BountyHuntedMotionTracker.db.profile.channel)
		end
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
		bX, bY = self.bountyVignette:GetPosition()
		if bX ~= nil and bY ~= nil then
			local angle, distance = hbd:GetWorldVector(_, bX * 100, bY * 100, oX * 100, oY * 100)
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
		end
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
	
	for index, vignette in ipairs (BountyHuntedMotionTracker.OrderVignettesByDistance()) do
		local widget = BountyHuntedMotionTracker.GetOrCreateTrackerWidget(nextWidget)
		widget:ClearAllPoints()
		widget.bountyVignette = vignette
		widget:SetPoint("TOP", BountyHuntedMotionTracker.Frame, "TOP", 0, y)
		widget.playerName:SetText(vignette.PlayerInfo.name)
		widget.playerRace:SetText(vignette.PlayerInfo.raceName)
		if (vignette.PlayerInfo.classId ~= nil) then
			widget.playerClass:SetTexCoord(unpack(CLASS_ICON_TCOORDS[vignette.PlayerInfo.classId]));
		end
		widget.NextArrowUpdate = -1
		widget:SetScript("OnUpdate", TrackerOnTick)
		widget:Show()
	
		y = y - 50
		nextWidget = nextWidget + 1
	end	
	
	while nextWidget <= BountyHuntedMotionTracker.MaxBounties do
		local widget = BountyHuntedMotionTracker.GetOrCreateTrackerWidget(nextWidget)
		widget:Hide()
		nextWidget = nextWidget + 1
	end
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
	
	BountyHuntedMotionTracker.TrackerWidgetPool[index] = f
	return f
end


function BountyHuntedMotionTracker.BuildFrame()
	if (BountyHuntedMotionTracker.Frame) then
		return BountyHuntedMotionTracker.Frame
	end
	
	BountyHuntedMotionTracker.Frame = CreateFrame("frame", "BountyHuntedMotionTrackerScreenPanel", UIParent)
	BountyHuntedMotionTracker.Frame:SetSize(235, 500)
	BountyHuntedMotionTracker.Frame:SetFrameStrata("LOW")
	BountyHuntedMotionTracker.Frame:ClearAllPoints()
	
	if BountyHuntedMotionTracker.db.profile.XPos then
		BountyHuntedMotionTracker.Frame:SetPoint("BOTTOMLEFT", BountyHuntedMotionTracker.db.profile.XPos, BountyHuntedMotionTracker.db.profile.YPos)
	else
		BountyHuntedMotionTracker.Frame:SetPoint("CENTER")
	end
	
	if BountyHuntedMotionTracker.db.profile.locked == false then
		BountyHuntedMotionTracker.Frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = true, tileSize = 16, edgeSize = 16, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		BountyHuntedMotionTracker.Frame:SetBackdropColor(0, 0, 0)
		BountyHuntedMotionTracker.Frame:SetMovable(true)
		BountyHuntedMotionTracker.Frame:EnableMouse(true)
		BountyHuntedMotionTracker.Frame:RegisterForDrag("LeftButton")
	end
	
	BountyHuntedMotionTracker.Frame:SetScript("OnDragStart", BountyHuntedMotionTracker.Frame.StartMoving)
	BountyHuntedMotionTracker.Frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		BountyHuntedMotionTracker.db.profile.XPos = self:GetLeft()
		BountyHuntedMotionTracker.db.profile.YPos = self:GetBottom()
	end)
end