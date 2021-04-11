local ADDON_NAME = "EquipExport"
local Sv = {}
local CharName
local AccountName

-- Begin local copies
local LR = LibResearch
local Task = LibAsync:Create("AsyncTask")
local Print = d

local subIdToQuality = { }
-- End local copies

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

local function loopThruInventory(bagId)
    -- logger:Debug("starting bag loop")
    -- logger:Debug("SlotIndex,Property,Value")
    local tmp = ""
    local bagSize = GetBagSize(bagId)
    for slotIndex = 0, bagSize - 1 do
        local loc = ""
        if bagId==BAG_WORN then loc=CharName.." - Equipped"
        elseif bagId==BAG_BACKPACK then loc=CharName.." - Bag"
        elseif bagId==BAG_BANK then loc=AccountName.." - Bank"
        elseif bagId==BAG_SUBSCRIBER_BANK then loc=AccountName.." - Bank"
        elseif 7<=bagId and bagId<=16 then loc=AccountName.." - Chest "..tostring(bagId-6)
        else loc="Uncategorized"..bagId
        end

        if bagId==BAG_SUBSCRIBER_BANK then
            tmp = "EquipExport,"..loc..",slot+"..slotIndex
        else
            tmp = "EquipExport,"..loc..",slot"..slotIndex
        end

        Sv[tmp..",LinkName"] = GetItemLinkName(GetItemLink(bagId,slotIndex))
        Sv[tmp..",TypeId"] = GetItemType(bagId,slotIndex)
        Sv[tmp..",ArmorTypeId"] = GetItemArmorType(bagId,slotIndex)
        Sv[tmp..",WeaponTypeId"] = GetItemWeaponType(bagId,slotIndex)
        Sv[tmp..",Trait"] = GetString("SI_ITEMTRAITTYPE",GetItemTrait(bagId,slotIndex))
        Sv[tmp..",QualityId"] = GetItemQuality(bagId,slotIndex)
        local isSet,setName,setId = LibSets.IsSetByItemLink(GetItemLink(bagId,slotIndex))
        Sv[tmp..",SetId"] = setId
        Sv[tmp..",EquipTypeId"] = GetItemLinkEquipType(GetItemLink(bagId,slotIndex))
        Sv[tmp..",Account"] = AccountName
        Sv[tmp..",EnchantIdApplied"] = GetItemLinkAppliedEnchantId(GetItemLink(bagId,slotIndex))
        Sv[tmp..",EnchantIdDefault"] = GetItemLinkDefaultEnchantId(GetItemLink(bagId,slotIndex))
        local hasCharges,enchantHeader,enchantDescription = GetItemLinkEnchantInfo(GetItemLink(bagId,slotIndex))
        Sv[tmp..",EnchantHeader"] = enchantHeader
        Sv[tmp..",EnchantDescription"] = enchantDescription
        Sv[tmp..",EnchantQualityId"] = GetEnchantQuality(GetItemLink(bagId,slotIndex))

    end
end

local function export()
    loopThruInventory(BAG_WORN)
    loopThruInventory(BAG_BACKPACK)
    loopThruInventory(BAG_BANK)
    loopThruInventory(BAG_SUBSCRIBER_BANK)
    if IsOwnerOfCurrentHouse() then
        loopThruInventory(BAG_HOUSE_BANK_ONE)
        loopThruInventory(BAG_HOUSE_BANK_TWO)
        loopThruInventory(BAG_HOUSE_BANK_THREE)
        loopThruInventory(BAG_HOUSE_BANK_FOUR)
        loopThruInventory(BAG_HOUSE_BANK_FIVE)
        loopThruInventory(BAG_HOUSE_BANK_SIX)
        loopThruInventory(BAG_HOUSE_BANK_SEVEN)
        loopThruInventory(BAG_HOUSE_BANK_EIGHT)
        loopThruInventory(BAG_HOUSE_BANK_NINE)
        loopThruInventory(BAG_HOUSE_BANK_TEN)
    end
end

local function ExportAll()
    Task:Call(export())
end

local function ExportAllDelay()
    zo_callLater(function() ExportAll() end,1*1000)
end

local function BuildLocString(bagId,slotId) --pure function except CharName and AccountName
    local tmp=""
    local loc = ""
    if bagId==BAG_WORN then loc=CharName.." - Equipped"
    elseif bagId==BAG_BACKPACK then loc=CharName.." - Bag"
    elseif bagId==BAG_BANK then loc=AccountName.." - Bank"
    elseif bagId==BAG_SUBSCRIBER_BANK then loc=AccountName.." - Bank"
    elseif bagId==5 then loc=AccountName.." - Craft Bag"
    elseif 7<=bagId and bagId<=16 then loc=AccountName.." - Chest "..tostring(bagId-6)
    else loc="Uncategorized"..bagId
    end

    if bagId==BAG_SUBSCRIBER_BANK then
        tmp = "LegitRow*"..loc..",slot+"..slotId
    else
        tmp = "LegitRow*"..loc..",slot"..slotId
    end

    return tmp
end

local function ExportSingleItem(bagId,slotId)
    local dataString = ""
    local key = BuildLocString(bagId,slotId)
    local separator = ","

    dataString = "||"
    dataString = dataString .. GetItemLinkName(GetItemLink(bagId,slotId)) --LinkName
    dataString = dataString .. separator
    dataString = dataString .. GetItemType(bagId,slotId) --TypeId
    dataString = dataString .. separator
    dataString = dataString .. GetItemArmorType(bagId,slotId) --ArmorTypeId
    dataString = dataString .. separator
    dataString = dataString .. GetItemWeaponType(bagId,slotId) --WeaponTypeId
    dataString = dataString .. separator
    dataString = dataString .. GetString("SI_ITEMTRAITTYPE",GetItemTrait(bagId,slotId)) --Trait
    dataString = dataString .. separator
    dataString = dataString .. GetItemQuality(bagId,slotId) --QualityId
    dataString = dataString .. separator
    local isSet,setName,setId = LibSets.IsSetByItemLink(GetItemLink(bagId,slotId))
    dataString = dataString .. setId --SetId
    dataString = dataString .. separator
    dataString = dataString .. GetItemLinkEquipType(GetItemLink(bagId,slotId)) --EquipTypeId
    dataString = dataString .. separator
    dataString = dataString .. AccountName --Account
    dataString = dataString .. separator
    dataString = dataString .. GetItemLinkAppliedEnchantId(GetItemLink(bagId,slotId)) --EnchantIdApplied
    dataString = dataString .. separator
    dataString = dataString .. GetItemLinkDefaultEnchantId(GetItemLink(bagId,slotId)) --EnchantIdDefault
    dataString = dataString .. separator
    local hasCharges,enchantHeader,enchantDescription = GetItemLinkEnchantInfo(GetItemLink(bagId,slotId))
    dataString = dataString .. enchantHeader --EnchantHeader
    dataString = dataString .. separator
    dataString = dataString .. enchantDescription --EnchantDescription
    dataString = dataString .. separator
    dataString = dataString .. GetEnchantQuality(GetItemLink(bagId,slotId)) --EnchantQualityId
    dataString = dataString .. "||"

    Sv[key] = dataString
end

local function SetHeaderRow()
    Sv["LegitRow*AAAAA"] = "||LinkName,TypeId,ArmorTypeId,WeaponTypeId,Trait,QualityId,SetId,EquipTypeId,Account,EnchantIdApplied,EnchantIdDefault,EnchantHeader,EnchantDescription,EnchantQualityId||"
end

local function OnInventorySingleSlotUpdate(_, bagId, slotId, _)
    ExportSingleItem(bagId,slotId)
end

local function Initialize()
    CharName = GetUnitName("player")
    AccountName = GetDisplayName()
    Sv = ZO_SavedVars:NewAccountWide("EquipExportSavedVariables", 13, nil, {})
    SetHeaderRow()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    --zo_callLater(function() ExportAll() end,20*1000)
    --EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, 5*60*1000, function() ExportAll() end)
    -- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, function() ExportAll() end)
    -- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CLOSE_BANK, function() ExportAll() end)
    -- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CLOSE_STORE, function() ExportAll() end)
    -- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_LOGOUT_DEFERRED, function() ExportAll() end)
    -- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTIVITY_FINDER_ACTIVITY_COMPLETE, function() ExportAllDelay() end)
end

local function OnAddOnLoaded(event, addonName)
    if addonName == ADDON_NAME then
        Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
