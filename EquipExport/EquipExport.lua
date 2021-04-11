local ADDON_NAME = "EquipExport"
local Sv = {}

-- Begin local copies
local LR = LibResearch
local Task = LibAsync:Create("AsyncTask")
local Print = d

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

local function loopThruInventory(bagId)
    -- logger:Debug("starting bag loop")
    -- logger:Debug("SlotIndex,Property,Value")
    local tmp = ""
    local bagSize = GetBagSize(bagId)
    for slotIndex = 0, bagSize - 1 do
        local loc = ""
        if bagId==BAG_WORN then loc=GetUnitName("player").." - Equipped"
        elseif bagId==BAG_BACKPACK then loc=GetUnitName("player").." - Bag"
        elseif bagId==BAG_BANK then loc=GetDisplayName().." - Bank"
        elseif bagId==BAG_SUBSCRIBER_BANK then loc=GetDisplayName().." - Bank"
        elseif 7<=bagId and bagId<=16 then loc=GetDisplayName().." - Chest "..tostring(bagId-6)
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
        Sv[tmp..",Account"] = GetDisplayName()
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

local function ExportSingleItem(bagId,slotId)
    local tmp = ""
    local loc = ""
    if bagId==BAG_WORN then loc=GetUnitName("player").." - Equipped"
    elseif bagId==BAG_BACKPACK then loc=GetUnitName("player").." - Bag"
    elseif bagId==BAG_BANK then loc=GetDisplayName().." - Bank"
    elseif bagId==BAG_SUBSCRIBER_BANK then loc=GetDisplayName().." - Bank"
    elseif 7<=bagId and bagId<=16 then loc=GetDisplayName().." - Chest "..tostring(bagId-6)
    else loc="Uncategorized"..bagId
    end

    if bagId==BAG_SUBSCRIBER_BANK then
        tmp = "EquipExport,"..loc..",slot+"..slotId
    else
        tmp = "EquipExport,"..loc..",slot"..slotId
    end

    Sv[tmp..",LinkName"] = GetItemLinkName(GetItemLink(bagId,slotId))
    Sv[tmp..",TypeId"] = GetItemType(bagId,slotId)
    Sv[tmp..",ArmorTypeId"] = GetItemArmorType(bagId,slotId)
    Sv[tmp..",WeaponTypeId"] = GetItemWeaponType(bagId,slotId)
    Sv[tmp..",Trait"] = GetString("SI_ITEMTRAITTYPE",GetItemTrait(bagId,slotId))
    Sv[tmp..",QualityId"] = GetItemQuality(bagId,slotId)
    local isSet,setName,setId = LibSets.IsSetByItemLink(GetItemLink(bagId,slotId))
    Sv[tmp..",SetId"] = setId
    Sv[tmp..",EquipTypeId"] = GetItemLinkEquipType(GetItemLink(bagId,slotId))
    Sv[tmp..",Account"] = GetDisplayName()
    Sv[tmp..",EnchantIdApplied"] = GetItemLinkAppliedEnchantId(GetItemLink(bagId,slotId))
    Sv[tmp..",EnchantIdDefault"] = GetItemLinkDefaultEnchantId(GetItemLink(bagId,slotId))
    local hasCharges,enchantHeader,enchantDescription = GetItemLinkEnchantInfo(GetItemLink(bagId,slotId))
    Sv[tmp..",EnchantHeader"] = enchantHeader
    Sv[tmp..",EnchantDescription"] = enchantDescription
    Sv[tmp..",EnchantQualityId"] = GetEnchantQuality(GetItemLink(bagId,slotId))
end

local function OnInventorySingleSlotUpdate(_, bagId, slotId, _)
    ExportSingleItem(bagId,slotId)
end

local function Initialize()
    Sv = ZO_SavedVars:NewAccountWide("EquipExportSavedVariables", 9, nil, {})
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    --zo_callLater(function() ExportAll() end,20*1000)
    --EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, 5*60*1000, function() ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, function() ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CLOSE_BANK, function() ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CLOSE_STORE, function() ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_LOGOUT_DEFERRED, function() ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTIVITY_FINDER_ACTIVITY_COMPLETE, function() ExportAllDelay() end)
end

local function OnAddOnLoaded(event, addonName)
    if addonName == ADDON_NAME then
        Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
