local ADDON_NAME = "EquipExport"
local Sv = {}
local CharName
local AccountName
local subIdToQuality = { } -- goes with GetEnchantQuality function

-- Begin local copies
local LR = LibResearch
local Task = LibAsync:Create("AsyncTask")
local Print = d

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

local function TransformBagId(bagId)
    return BuildLocString(bagId,0)
end

local function ExportSingleItem(bagId,slotId)
    local dataString = ""
    local key = BuildLocString(bagId,slotId)
    local separator = ";"

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
    dataString = dataString .. separator
    local itemCount,_ = GetSlotStackSize(bagId,slotId)
    dataString = dataString .. itemCount --StackCount

    Sv[key] = dataString
end

local function SetHeaderRow()
    Sv["LegitRow*!!!!!"] = "LinkName;TypeId;ArmorTypeId;WeaponTypeId;Trait;QualityId;SetId;EquipTypeId;Account;EnchantIdApplied;EnchantIdDefault;EnchantHeader;EnchantDescription;EnchantQualityId;StackCount"
end

local function OnInventorySingleSlotUpdate(_, bagId, slotId, _)
    ExportSingleItem(bagId,slotId)
end

local function ExportWholeBag(bagId)
    local bagSize = GetBagSize(bagId)
    for slotIndex = 0, bagSize - 1 do
        ExportSingleItem(bagId,slotIndex)
    end
    Sv.BagInitialized[TransformBagId(bagId)] = true
    Print("EquipExport ran on BagId: "..tostring(bagId))
end

local function ExportWholeBagAsync(bagId)
    Task:Call(ExportWholeBag(bagId))
end

local function OnEventCloseBank()
    if IsOwnerOfCurrentHouse() then
        ExportWholeBag(BAG_HOUSE_BANK_ONE)
        ExportWholeBag(BAG_HOUSE_BANK_TWO)
        ExportWholeBag(BAG_HOUSE_BANK_THREE)
        ExportWholeBag(BAG_HOUSE_BANK_FOUR)
        ExportWholeBag(BAG_HOUSE_BANK_FIVE)
        ExportWholeBag(BAG_HOUSE_BANK_SIX)
        ExportWholeBag(BAG_HOUSE_BANK_SEVEN)
        ExportWholeBag(BAG_HOUSE_BANK_EIGHT)
        ExportWholeBag(BAG_HOUSE_BANK_NINE)
        ExportWholeBag(BAG_HOUSE_BANK_TEN)
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_CLOSE_BANK, OnEventCloseBank)
    end
    Print("EquipExport ran on storage chests")
end

local function Initialize()
    CharName = GetUnitName("player")
    AccountName = GetDisplayName()
    Sv = ZO_SavedVars:NewAccountWide("EquipExportSavedVariables", 22, nil, {})
    SetHeaderRow()
    Sv.BagInitialized = Sv.BagInitialized or {}
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)

    if not Sv.BagInitialized[TransformBagId(BAG_WORN)] then
        zo_callLater(function() ExportWholeBag(BAG_WORN) end,20*1000)
        zo_callLater(function() ExportWholeBag(BAG_BACKPACK) end,22*1000)
        zo_callLater(function() ExportWholeBag(BAG_BANK) end,24*1000)
        zo_callLater(function() ExportWholeBag(BAG_SUBSCRIBER_BANK) end,26*1000)
    end

    if not Sv.BagInitialized[TransformBagId(BAG_HOUSE_BANK_ONE)] then
        EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_CLOSE_BANK, OnEventCloseBank)
    end

end

local function OnAddOnLoaded(event, addonName)
    if addonName == ADDON_NAME then
        EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event)
        Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
