local Players = game:GetService("Players")
local repStore = game:GetService("ReplicatedStorage")

local CharacterLoader = require(repStore.Modules.RaceHandler)
local FaceHandler = require(repStore.Modules.FaceHandler)

local DataTemplateTypes = require(repStore.FrameworkModules.Types.DataTemplateTypes)
local DataTemplate: DataTemplateTypes.tDataTemplate = require(script.Template)
local InventoryTypes = require(repStore.FrameworkModules.Types.InventoryTypes)
local ItemMetadata = require(repStore.FrameworkModules.Shared.ItemMetadata)

local serverscriptservice = game:GetService("ServerScriptService")
local StatesHandler = require(script.Parent.StatesHandler)
local ProfileService = require(script.Parent.ProfileService)

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerProfile",
	DataTemplate
)

local Profiles = {}

local PlayerDataHandler = {}

function PlayerDataHandler:PlayerAdded(player: Player): DataTemplateTypes.tDataTemplate
	
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile then
		
		profile:AddUserId(player.UserId)
		StatesHandler.AddPlayerToStatesTable(player)
		profile:Reconcile()
		
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick()
		end)
		
		if not player:IsDescendantOf(Players) then
			profile:Release()
		else
			Profiles[player] = profile
			--print(Profiles[player].Data)
		end
	else
		player:Kick()
	end
	
	return Profiles[player].Data
end

function PlayerDataHandler:PlayerRemoving(player: Player)
	local prof = Profiles[player]
	local Data: DataTemplateTypes.tDataTemplate = prof.Data
	Data.PlayerStatus.metadata.appearanceLoaded = false
	
	PlayerDataHandler:Set(player, "PlayerStatus", Data.PlayerStatus)
	
	print(prof.Data)
	prof:Release()
	
	Profiles[player] = nil
end


function PlayerDataHandler:getProfile(player)
	assert(Profiles[player], string.format("Profile does not exist for %s", player.UserId))

	return Profiles[player]
end

function PlayerDataHandler:Get(player, key)
	local profile = PlayerDataHandler:getProfile(player)
	assert(profile.Data[key], string.format("Data does not exist for key: %s", key))

	return profile.Data[key]
end


function PlayerDataHandler:Set(player, key, value)
	local profile = PlayerDataHandler:getProfile(player)
	assert(profile.Data[key], string.format("Data does not exist for key: %s", key))

	assert(type(profile.Data[key]) == type(value))

	profile.Data[key] = value

end


function PlayerDataHandler:Update(player, key, callback)
	local profile = PlayerDataHandler:getProfile(player)

	local oldData = self:Get(player, key)
	local newData = callback(oldData)

	self:Set(player, key, newData)
end


function PlayerDataHandler:WaitForProfile(player, timeout)
	timeout = timeout or 10
	local start = os.clock()
	while not Profiles[player] do
		if os.clock() - start > timeout then
			warn("Profile load timed out for", player.UserId)
			return false
		end
		task.wait(0.1)
	end
	return true
end

function PlayerDataHandler:CheckData(player)
	local prof:DataTemplateTypes.tDataTemplate = Profiles[player].Data
	
	for itemName, itemAmount in pairs(prof.Inventory) do
		if (itemName == "Hotbar" or itemName == "metadata") then continue end
		if (ItemMetadata[itemName] == nil) then prof[itemName] = nil continue end
		--if (itemAmount > InventoryTypes.maxStack) then itemAmount = InventoryTypes.maxStack end
	end
	
	PlayerDataHandler:Set(player, "Inventory", prof.Inventory)
	
	if (prof.PlayerStatus.metadata["raceSet"] == false) then
		prof.PlayerStatus.metadata["raceSet"] = true

		local newRaceData = CharacterLoader:RollRace(player)
		prof.PlayerStatus.Race = newRaceData

		warn(`{player.Name} has no race, rerolling...`)
		PlayerDataHandler:Set(player, "PlayerStatus", prof.PlayerStatus)
	end
	
	if (prof.PlayerStatus.metadata["appearanceSet"] == false) then
		prof.PlayerStatus.metadata["appearanceSet"] = true
		prof.PlayerStatus.metadata.appearanceLoaded = true
		
		
		CharacterLoader:LoadRaceAppearance(player, prof.PlayerStatus)
		local newApperance = FaceHandler:LoadHead(player, prof.PlayerStatus)
		prof.PlayerStatus.Appearance = newApperance
		
		warn(`{player.Name}: Appearance unset, configuring...`)
		PlayerDataHandler:Set(player, "PlayerStatus", prof.PlayerStatus)
	end
	
end

return PlayerDataHandler