local ADDON_NAME = "EquipExport"
local sV = {}

-- Begin local copies
local LR = LibResearch
local task = LibAsync:Create("AsyncTask")

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
        
        EquipExport.sV[tmp..",LinkName"] = GetItemLinkName(GetItemLink(bagId,slotIndex))
        EquipExport.sV[tmp..",TypeId"] = GetItemType(bagId,slotIndex)
        EquipExport.sV[tmp..",ArmorTypeId"] = GetItemArmorType(bagId,slotIndex)
        EquipExport.sV[tmp..",WeaponTypeId"] = GetItemWeaponType(bagId,slotIndex)
        EquipExport.sV[tmp..",Trait"] = GetString("SI_ITEMTRAITTYPE",GetItemTrait(bagId,slotIndex))
        EquipExport.sV[tmp..",QualityId"] = GetItemQuality(bagId,slotIndex)
        local isSet,setName,setId = LibSets.IsSetByItemLink(GetItemLink(bagId,slotIndex))
        EquipExport.sV[tmp..",SetId"] = setId
        EquipExport.sV[tmp..",EquipTypeId"] = GetItemLinkEquipType(GetItemLink(bagId,slotIndex))
        EquipExport.sV[tmp..",Account"] = GetDisplayName()
        EquipExport.sV[tmp..",EnchantIdApplied"] = GetItemLinkAppliedEnchantId(GetItemLink(bagId,slotIndex))
        EquipExport.sV[tmp..",EnchantIdDefault"] = GetItemLinkDefaultEnchantId(GetItemLink(bagId,slotIndex))
        local hasCharges,enchantHeader,enchantDescription = GetItemLinkEnchantInfo(GetItemLink(bagId,slotIndex))
        EquipExport.sV[tmp..",EnchantHeader"] = enchantHeader
        EquipExport.sV[tmp..",EnchantDescription"] = enchantDescription
        EquipExport.sV[tmp..",EnchantQualityId"] = GetEnchantQuality(GetItemLink(bagId,slotIndex))
        
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

function EquipExport:ExportAll()
    task:Call(export())
end

function EquipExport:ExportAllDelay()
    zo_callLater(function() self:ExportAll() end,1*1000)
end

function EquipExport:Initialize()
    sV = ZO_SavedVars:NewAccountWide("EquipExportSavedVariables", 9, nil, {})
    --zo_callLater(function() self:ExportAll() end,20*1000)
    --EVENT_MANAGER:RegisterForUpdate(self.name, 5*60*1000, function() self:ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, function() self:ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_BANK, function() self:ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_STORE, function() self:ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LOGOUT_DEFERRED, function() self:ExportAll() end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTIVITY_FINDER_ACTIVITY_COMPLETE, function() self:ExportAllDelay() end)
end





-- Then we create an event handler function which will be called when the "addon loaded" event
-- occurs. We'll use this to initialize our addon after all of its resources are fully loaded.
function EquipExport.OnAddOnLoaded(event, addonName)
    -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == EquipExport.name then
        EquipExport:Initialize()
    end
end

-- Register our event handler function to be called when the proper event occurs.
EVENT_MANAGER:RegisterForEvent(EquipExport.name, EVENT_ADD_ON_LOADED, EquipExport.OnAddOnLoaded)