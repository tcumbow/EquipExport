-- Leaked for menu & data
EquipExport = {}
EquipExport.savedVars = {}
EquipExport.globalSavedVars = {}

local ADDON_NAME = "EquipExport"
EquipExport.name = "EquipExport"

EquipExport.doInviteGroupWhenLand = false

-- Libraries ------------------------------------------------------------------
local LR = LibResearch
-- local logger = LibDebugLogger("EquipExport")
local async = LibAsync

local subIdToQuality = { }

local function GetEnchantQuality(itemLink)
	local itemId, itemIdSub, enchantSub = itemLink:match("|H[^:]+:item:([^:]+):([^:]+):[^:]+:[^:]+:([^:]+):")
	if not itemId then return 0 end
	enchantSub = tonumber(enchantSub)
	if enchantSub == 0 and not IsItemLinkCrafted(itemLink) then
		local hasSet = GetItemLinkSetInfo(itemLink, false)
		-- For non-crafted sets, the "built-in" enchantment has the same quality as the item itself
		if hasSet then enchantSub = tonumber(itemIdSub) end
	end
	if enchantSub > 0 then
		local quality = subIdToQuality[enchantSub]
		if not quality then
			-- Create a fake itemLink to get the quality from built-in function
			local itemLink = string.format("|H1:item:%i:%i:50:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0:10000:0|h|h", itemId, enchantSub)
			quality = GetItemLinkQuality(itemLink)
			subIdToQuality[enchantSub] = quality
		end
		return quality
	end
	return 0
end



local ms_time = GetGameTimeMilliseconds()
local function dmsg(txt)
	d((GetGameTimeMilliseconds() - ms_time) .. ") " .. txt)
	--d(GetGameTimeMilliseconds() .. ") " .. txt)
	ms_time = GetGameTimeMilliseconds()
end
local function IsInList(list, item)
	for index, value in ipairs(list) do
		if value == item then return true end
	end
	return false
end


local function loopThruInventory(bagId)
    -- logger:Debug("starting bag loop")
    -- logger:Debug("SlotIndex,Property,Value")
	local displayName = GetDisplayName()
	local loc = ""
	if bagId==BAG_WORN then loc=GetUnitName("player").." - Equipped"
	elseif bagId==BAG_BACKPACK then loc=GetUnitName("player").." - Bag"
	elseif bagId==BAG_BANK then loc=displayName.." - Bank"
	elseif bagId==BAG_SUBSCRIBER_BANK then loc=displayName.." - Bank"
	elseif 7<=bagId and bagId<=16 then loc=displayName.." - Chest "..tostring(bagId-6)
	else loc="Uncategorized"..bagId
	end

	local hdr = "EquipExport,"..loc..",slot"
	if bagId==BAG_SUBSCRIBER_BANK then hdr = hdr.."+" end

    local bagSize = GetBagSize(bagId)
	local last = ""
    for slotIndex = 0, bagSize - 1 do
		local itemLink = GetItemLink(bagId,slotIndex)
		if itemLink == "" then
			EquipExport.sV[hdr..slotIndex..",LinkName"] = ""
			EquipExport.sV[hdr..slotIndex..",TypeId"] = 0
			EquipExport.sV[hdr..slotIndex..",ArmorTypeId"] = 0
			EquipExport.sV[hdr..slotIndex..",WeaponTypeId"] = 0
			EquipExport.sV[hdr..slotIndex..",Trait"] = "No Trait"
			EquipExport.sV[hdr..slotIndex..",QualityId"] = 1
			EquipExport.sV[hdr..slotIndex..",SetId"] = 0
			EquipExport.sV[hdr..slotIndex..",EquipTypeId"] = 0
			EquipExport.sV[hdr..slotIndex..",Account"] = displayName
			EquipExport.sV[hdr..slotIndex..",EnchantIdApplied"] = 0
			EquipExport.sV[hdr..slotIndex..",EnchantIdDefault"] = 0
			EquipExport.sV[hdr..slotIndex..",EnchantHeader"] = ""
			EquipExport.sV[hdr..slotIndex..",EnchantDescription"] = ""
			EquipExport.sV[hdr..slotIndex..",EnchantQualityId"] = 0
		else
			EquipExport.sV[hdr..slotIndex..",LinkName"] = GetItemLinkName(itemLink)
			EquipExport.sV[hdr..slotIndex..",TypeId"] = GetItemType(bagId,slotIndex)
			EquipExport.sV[hdr..slotIndex..",ArmorTypeId"] = GetItemArmorType(bagId,slotIndex)
			EquipExport.sV[hdr..slotIndex..",WeaponTypeId"] = GetItemWeaponType(bagId,slotIndex)
			EquipExport.sV[hdr..slotIndex..",Trait"] = GetString("SI_ITEMTRAITTYPE",GetItemTrait(bagId,slotIndex))
			EquipExport.sV[hdr..slotIndex..",QualityId"] = GetItemQuality(bagId,slotIndex)
			local isSet,setName,setId = LibSets.IsSetByItemLink(itemLink)
			EquipExport.sV[hdr..slotIndex..",SetId"] = setId
			EquipExport.sV[hdr..slotIndex..",EquipTypeId"] = GetItemLinkEquipType(itemLink)
			EquipExport.sV[hdr..slotIndex..",Account"] = displayName
			EquipExport.sV[hdr..slotIndex..",EnchantIdApplied"] = GetItemLinkAppliedEnchantId(itemLink)
			EquipExport.sV[hdr..slotIndex..",EnchantIdDefault"] = GetItemLinkDefaultEnchantId(itemLink)
			local hasCharges,enchantHeader,enchantDescription = GetItemLinkEnchantInfo(itemLink)
			EquipExport.sV[hdr..slotIndex..",EnchantHeader"] = enchantHeader
			EquipExport.sV[hdr..slotIndex..",EnchantDescription"] = enchantDescription
			EquipExport.sV[hdr..slotIndex..",EnchantQualityId"] = GetEnchantQuality(itemLink)
		end
    end
	--dmsg("Finish bag "..bagId.." "..loc.." of size "..bagSize)
	return bagSize
end

function EquipExport:ExportAll()
	--local task = async:Create("AsyncTask1")
    -- task:Call(export())
	dmsg("Begin ExportAll")

	--baglist = {BAG_WORN, BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TWO, BAG_HOUSE_BANK_THREE, BAG_HOUSE_BANK_FOUR, BAG_HOUSE_BANK_FIVE, BAG_HOUSE_BANK_SIX, BAG_HOUSE_BANK_SEVEN, BAG_HOUSE_BANK_EIGHT, BAG_HOUSE_BANK_NINE, BAG_HOUSE_BANK_TEN}
	--local task = async:Create("AsyncTask1")
	--task:For(pairs(baglist)):Do(loopThruInventoryNew):Then((function() dmsg("End ExportAll 1") end))

	--local task2 = async:Create("AsyncTask2")
	--task2:Call(export()):Then((function() dmsg("End ExportAll 2") end))

	baglist = {BAG_WORN, BAG_BACKPACK, BAG_BANK, BAG_SUBSCRIBER_BANK, BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TWO, BAG_HOUSE_BANK_THREE, BAG_HOUSE_BANK_FOUR, BAG_HOUSE_BANK_FIVE, BAG_HOUSE_BANK_SIX, BAG_HOUSE_BANK_SEVEN, BAG_HOUSE_BANK_EIGHT, BAG_HOUSE_BANK_NINE, BAG_HOUSE_BANK_TEN}
	for index, bag in ipairs(baglist) do
		loopThruInventory(bag)
	end

	dmsg("End ExportAll")
	EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_ACTIVATED)
end

--function EquipExport:ExportAllDelay()
--    zo_callLater(function() self:ExportAll() end,1*1000)
--end


function EquipExport:Initialize()
    -- ...but we don't have anything to initialize yet. We'll come back to this.
    -- logger:Debug("--------------initializing--------------")
    self.sV = ZO_SavedVars:NewAccountWide("EquipExportSavedVariables", 8, nil, {})
    --zo_callLater(function() self:ExportAll() end,20*1000)
    --EVENT_MANAGER:RegisterForUpdate(self.name, 5*60*1000, function() self:ExportAll() end)

    --EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, function() self:ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEACTIVATED, function() self:ExportAll() end)
    --EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_BANK, function() self:ExportAll() end)
    --EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_STORE, function() self:ExportAll() end)
    --EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOGOUT_DEFERRED, function() self:ExportAll() end)
    --EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTIVITY_FINDER_ACTIVITY_COMPLETE, function() self:ExportAllDelay() end)
	SLASH_COMMANDS["/eea"] = EquipExport.ExportAll

    -- logger:Debug("done with initialization")
    
end

---- Begin GroupStart -------------------------------------------------
--EquipExport.dungeons = {
--	[ 98] = {fullname="Dungeon: Fungal Grotto I",       shortname="FG"},
--	[184] = {fullname="Dungeon: Vaults of Madness",     shortname="VM"},
--	[185] = {fullname="Dungeon: Selene's Web",          shortname="SW"},
--	[186] = {fullname="Dungeon: Blackheart Haven",      shortname="BH"},
--	[187] = {fullname="Dungeon: Blessed Crucible",      shortname="BC"},
--	[188] = {fullname="Dungeon: Tempest Island",        shortname="TI"},
--	[189] = {fullname="Dungeon: Wayrest Sewers I",      shortname="WS"},
--	[190] = {fullname="Dungeon: Crypt of Hearts I",     shortname=""},
--	[191] = {fullname="Dungeon: Elden Hollow I",        shortname=""},
--	[192] = {fullname="Dungeon: Arx Corinium",          shortname=""},
--	[193] = {fullname="Dungeon: Spindleclutch I",       shortname=""},
--	[194] = {fullname="Dungeon: The Banished Cells I",  shortname=""},
--	[195] = {fullname="Dungeon: Direfrost Keep",        shortname=""},
--	[196] = {fullname="Dungeon: Volenfell",             shortname=""},
--	[197] = {fullname="Dungeon: City of Ash I",         shortname=""},
--	[198] = {fullname="Dungeon: Darkshade Caverns I",   shortname=""},
--	[230] = {fullname="Trial: Hel Ra Citadel",          shortname=""},
--	[231] = {fullname="Trial: Aetherian Archive",       shortname=""},
--	[232] = {fullname="Trial: Sanctum Ophidia",         shortname=""},
--	[236] = {fullname="Dungeon: Imperial City Prison",  shortname=""},
--	[247] = {fullname="Dungeon: White-Gold Tower",      shortname=""},
--	[258] = {fullname="Trial: Maw of Lorkhaj",          shortname=""},
--	[260] = {fullname="Dungeon: Ruins of Mazzatun",     shortname=""},
--	[261] = {fullname="Dungeon: Cradle of Shadows",     shortname=""},
--	[262] = {fullname="Dungeon: The Banished Cells II", shortname=""},
--	[263] = {fullname="Dungeon: Wayrest Sewers II",     shortname=""},
--	[264] = {fullname="Dungeon: Darkshade Caverns II",  shortname=""},
--	[265] = {fullname="Dungeon: Elden Hollow II",       shortname=""},
--	[266] = {fullname="Dungeon: Fungal Grotto II",      shortname=""},
--	[267] = {fullname="Dungeon: Spindleclutch II",      shortname=""},
--	[268] = {fullname="Dungeon: City of Ash II",        shortname=""},
--	[269] = {fullname="Dungeon: Crypt of Hearts II",    shortname=""},
--	[326] = {fullname="Dungeon: Bloodroot Forge",       shortname=""},
--	[331] = {fullname="Trial: Halls of Fabrication",    shortname=""},
--	[332] = {fullname="Dungeon: Falkreath Hold",        shortname=""},
--	[341] = {fullname="Dungeon: Fang Lair",             shortname=""},
--	[346] = {fullname="Trial: Asylum Sanctorium",       shortname=""},
--	[363] = {fullname="Dungeon: Scalecaller Peak",      shortname=""},
--	[364] = {fullname="Trial: Cloudrest",               shortname=""},
--	[370] = {fullname="Dungeon: March of Sacrifices",   shortname=""},
--	[371] = {fullname="Dungeon: Moon Hunter Keep",      shortname=""},
--	[389] = {fullname="Dungeon: Frostvault",            shortname=""},
--	[390] = {fullname="Dungeon: Depths of Malatar",     shortname=""},
--	[391] = {fullname="Dungeon: Moongrave Fane",        shortname=""},
--	[398] = {fullname="Dungeon: Lair of Maarselok",     shortname=""},
--	[399] = {fullname="Trial: Sunspire",                shortname=""},
--	[424] = {fullname="Dungeon: Icereach",              shortname=""},
--	[425] = {fullname="Dungeon: Unhallowed Grave",      shortname=""}}
--EquipExport.makegrouplist = {"@Samantha.C", "@Tommy.C", "@Jenniami", "@Phrosty1"}
--local function traveltoplace(location)
--	d("location:"..location)
--	for nodeIndex, dungeon in pairs(EquipExport.dungeons) do
--		if string.find(string.upper(dungeon.shortname), string.upper(location)) then
--			d("Traveling to "..dungeon.fullname)
--			FastTravelToNode(nodeIndex)
--			return true
--		end
--	end
--	for nodeIndex, dungeon in pairs(EquipExport.dungeons) do
--		if string.find(string.upper(dungeon.fullname), string.upper(location)) then
--			d("Traveling to "..dungeon.fullname)
--			FastTravelToNode(nodeIndex)
--			return true
--		end
--	end
--	return false
--end
--local function OnGroupInviteReceived(eventCode, inviteCharacterName, inviterDisplayName)
--	d("OnGroupInviteReceived".." eventCode:"..eventCode.." inviteCharacterName:"..inviteCharacterName.." inviterDisplayName:"..inviterDisplayName)
--	-- eventCode: 131191 inviteCharacterName: Hadara Hazelwood inviterDisplayName: @Samantha.C
--	if IsInList (EquipExport.makegrouplist, inviterDisplayName) then
--        AcceptGroupInvite()
--    end
--end
--local function OnGroupInviteReceivedAlt(eventCode, inviteCharacterName, inviterDisplayName)
--	d("ASDFASDF OnGroupInviteReceivedAlt".." eventCode:"..eventCode.." inviteCharacterName:"..inviteCharacterName.." inviterDisplayName:"..inviterDisplayName)
--	-- eventCode: 131191 inviteCharacterName: Hadara Hazelwood inviterDisplayName: @Samantha.C
--end
--EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_GROUP_INVITE_RECEIVED, OnGroupInviteReceived)
--
--local function OnGroupInviteTimeout(eventCode) d("OnGroupInviteTimeout".." eventCode:"..eventCode) end
--EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_GROUP_INVITE_ACCEPT_RESPONSE_TIMEOUT, OnGroupInviteTimeout)
--local function OnTest1(eventCode, reason) d("EVENT_JUMP_FAILED".." reason:"..reason) end
--EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_JUMP_FAILED, OnTest1)
----local function OnTest2(eventCode, nodeIndex) d("EVENT_START_FAST_TRAVEL_INTERACTION".." nodeIndex:"..nodeIndex) end
----EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_START_FAST_TRAVEL_INTERACTION, OnTest2) -- When using a shrine
--local function OnTest3(eventCode, keepId) d("EVENT_START_FAST_TRAVEL_KEEP_INTERACTION".." keepId:"..keepId) end
--EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_START_FAST_TRAVEL_KEEP_INTERACTION, OnTest3)
--
--local function OnEVENT_ZONE_CHANGED( eventCode, zoneName, subZoneName, newSubzone, zoneId, subZoneId )
--	d("alt EVENT_ZONE_CHANGED".." zoneId:"..zoneId)
--	d(zoneName, subZoneName, newSubzone, zoneId, subZoneId)
--end
--EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_ZONE_CHANGED, OnEVENT_ZONE_CHANGED)
--function EquipExport.OnZoneChanged( eventCode, zoneName, subZoneName, newSubzone, zoneId, subZoneId ) d("EVENT_ZONE_CHANGED".." zoneId:"..zoneId) end
--EVENT_MANAGER:RegisterForEvent( EquipExport.name, EVENT_ZONE_CHANGED, EquipExport.OnZoneChanged )
--
--
--function EquipExport.groupstart(location)
--	if location == "" then else
--		indVet = false
--		if string.find(location, "+") or string.find(string.upper(location), "VET") then indVet = true end
--		SetVeteranDifficulty(indVet)
--		traveltoplace(location)
--	end
--
--end
--function EquipExport.groupstartvet(location)
--	function trim(s)
--	   return (s:gsub("^%s*(.-)%s*$", "%1"))
--	end
--	if string.find(location, "2") then location = string.gsub(location, "2", "") end
--	if string.find(location, "II") then location = string.gsub(location, "II", "") end
--	location = trim(location)
--
--	SetVeteranDifficulty(true)
--	d("Set to Veteran")
--	EquipExport.doInviteGroupWhenLand = true
--	traveltoplace(location)
--
--	--d("GetActivityGroupType.. ")
--	--d(GetActivityGroupType()) -- 0=not in group -- if not in group then 0 elseif leader then 0 else 0
--	--d("CanPlayerChangeGroupDifficulty.. ")
--	--d(CanPlayerChangeGroupDifficulty()) -- if not in group then true/0 elseif leader then true/0 else false/2
--
--end
-- 
--SLASH_COMMANDS["/ee"] = EquipExport.ExportAll
----SLASH_COMMANDS["/gs"] = EquipExport.groupstart
--SLASH_COMMANDS["/gsv"] = EquipExport.groupstartvet
--
--function EquipExport.doEVENT_ACTIVITY_FINDER_STATUS_UPDATE (eventCode, result)
--	d("doEVENT_ACTIVITY_FINDER_STATUS_UPDATE 123")
--	d(result)
--	if EquipExport.doInviteGroupWhenLand then
--		user = GetDisplayName()
--		for index, invitee in pairs(EquipExport.makegrouplist) do
--			if invitee == user then else
--				d("inviting "..invitee)
--				GroupInviteByName(invitee)
--			end
--		end
--		d("GetGroupSize.. "..GetGroupSize())
--	end
--	EquipExport.doInviteGroupWhenLand = false -- consider just triggers
--	--EVENT_MANAGER:UnRegisterForEvent(EquipExport.name, EVENT_ACTIVITY_FINDER_STATUS_UPDATE)
--end
--EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_ACTIVITY_FINDER_STATUS_UPDATE, EquipExport.doEVENT_ACTIVITY_FINDER_STATUS_UPDATE)
--
---- End GroupStart -------------------------------------------------

-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function EquipExport.OnAddOnLoaded(event, addonName)
    -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == EquipExport.name then
        EquipExport:Initialize()
    end
end

-- Finally, we'll register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_ADD_ON_LOADED, EquipExport.OnAddOnLoaded)

