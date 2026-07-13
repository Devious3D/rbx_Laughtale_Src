local Framework = require("../Framework")
local DataModule = require("../../../ServerScriptService/dir_ServerScriptService/Modules/PlayerDataHandler")

local InventoryTypes = require("../Types/InventoryTypes")
local PayloadTypes = require("../Types/RemotePayloads")
local DataTemplateTypes = require("../Types/DataTemplateTypes")

local Services, Modules, Shared
local Inventories: {DataTemplateTypes.tInventory} = {}


const restrictedNames: {string} = {
	Hotbar = 1,
	metadata = 1
}

local function isRestrictedItemName(name: string): boolean
	return (restrictedNames[name] ~= nil)
end

local function isValidItem(name: string): boolean
	return (Shared.ItemMetadata[name] ~= nil)
end

local function getThisPlayer(player: string): Player
	return Services.Players:FindFirstChild(player)
end

local function isOverWeight(player: Player): boolean
	return (Inventories[player].metadata.InvWeight >= Inventories[player].metadata.MaxInvWeight)
end

local function isOverStacked(player: Player, item: string): boolean
	return (Inventories[player][item] >= InventoryTypes.maxStack)
end

local module = {}

function module:Start()
	
	Services, Modules, Shared = Framework:Include({
		Services = {
			"Players"	
		},
		Modules = {},
		Shared = {
			"ItemMetadata"
		}
	})
	
end


function module:StorePlayerInventory(player, Inventory)
	assert(Framework:IsServer(), "Not Server")
	if (Inventories[player] ~= nil) then return end
	Inventories[player] = Inventory
	
	module:SetPlayerInventoryWeight(player)
end

function module:GetPlayerInventory(player): DataTemplateTypes.tInventory
	assert(Framework:IsServer(), "Not Server")
	return Inventories[player]
end

function module:HasItem(player: Player, itemName: string): boolean
	assert(Framework:IsServer(), "Not Server")
	return (Inventories[player][itemName] ~= nil)
end

function module:GetItem(player, itemName: string): InventoryTypes.InventoryItem
	assert(Framework:IsServer(), "Not Server")
	return Inventories[player][itemName]
end

function module:UpdateClient(player)
	assert(Framework:IsServer(), "Not Server")
	DataModule:Set(player, "Inventory", Inventories[player])
	
	Framework:Fire("InventoryRemote", player, Inventories[player])
end


function module:SetPlayerInventoryWeight(player)
	assert(Framework:IsServer(), "Not Server")

	local PlayerInventory: DataTemplateTypes.tInventory = Inventories[player]
	local newWeight: number = 0
		
	for itemName, itemAmount in pairs(PlayerInventory) do
		if (isRestrictedItemName(itemName)) then continue end
	
		local itemInIndex = Shared.ItemMetadata[itemName]
		newWeight += (itemAmount) * itemInIndex.weight
	end
	
	Inventories[player].metadata.InvWeight = newWeight
	print(`{player}: new Inv Weight: {newWeight}`)
end


function module.Add(Data: PayloadTypes.tInventoryRemotePayload)
	assert(Framework:IsServer(), "Not Server")
	assert(isValidItem(Data.item.name), "Not a valid item")
	
	Data.player = getThisPlayer(Data.player)
	if (isOverWeight(Data.player)) then return end
	
	if (module:HasItem(Data.player, Data.item.name)) then 
		
		if isOverStacked(Data.player, Data.item.name) then warn("Overstacked") return end
		Inventories[Data.player][Data.item.name] += Data.item.amount
		print("Has item, adding")	
	else 
		
		Inventories[Data.player][Data.item.name] = Data.item.amount
	end
		
	module:SetPlayerInventoryWeight(Data.player)
	module:UpdateClient(Data.player)
end

function module.Remove(Data: PayloadTypes.tInventoryRemotePayload)
	assert(Framework:IsServer(), "Not Server")
	assert(isValidItem(Data.item.name), "Not a valid item")
	
	Data.player = getThisPlayer(Data.player)
	
	if (not module:HasItem(Data.player, Data.item.name)) then return end
	Inventories[Data.player][Data.item.name] -= Data.item.amount	
	
	module:SetPlayerInventoryWeight(Data.player)
	module:UpdateClient(Data.player)
end

function module.Drop()
	print("Drop")
end

return module
