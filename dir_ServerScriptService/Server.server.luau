local ProfileService = require(script.Parent.Modules.ProfileService)

local repStore = game:GetService("ReplicatedStorage")
local Framework = require(repStore.FrameworkModules.Framework)
local DataModule = require("../dir_ServerScriptService/Modules/PlayerDataHandler")

local RaceHandler = require(repStore.Modules.RaceHandler)
local FaceHandler = require(repStore.Modules.FaceHandler)

local DataTemplateTypes = require(repStore.FrameworkModules.Types.DataTemplateTypes)
local RemotePayloadTypes = require(repStore.FrameworkModules.Types.RemotePayloads)


Framework.new()
Framework:Start()

local Services, Modules, Shared = Framework:Include({
	Services = {
		"RunService",
		"Players"	
	},
	
	Modules = {  
		"InventoryServer"
	},
	
	Shared = {
		
	}
})

local function useModules(Payload: {RemotePayloadTypes.tUseModule})
	if (typeof(Payload) ~= "table") then return end
	
	for i, v: RemotePayloadTypes.tUseModule in pairs(Payload) do

		local Module = Modules[v.module]
		for idx, func: string in pairs(v.functions) do
			Module[func](v.params[idx])
		end
	end
end


Framework:CreateRemoteChannel("StartUpConnections", 2)
Framework:CreateRemoteChannel("Combat", 3)
Framework:CreateRemoteChannel("Data", 3)
Framework:CreateRemote("InventoryRemote")

local MainGroup = Framework:NewConnectionGroup()
local StartUpGroup = Framework:NewConnectionGroup()


local ServerStart = Framework:NewSignal(StartUpGroup, Services.Players.PlayerAdded:Connect(function(player: Player)
	
	warn(`Player {player.Name}`)


	--Data Loading and Handling
	local Data: DataTemplateTypes.tDataTemplate = DataModule:PlayerAdded(player)
	
	while (player.Character == nil) do
		print("Waiting for character")
		task.wait(.1)
	end
	
	player.Character.Parent = game.Workspace.Active
	
	if not DataModule:WaitForProfile(player, 1) then return end
	
	DataModule:CheckData(player)
		
	if (Data.PlayerStatus.metadata.appearanceLoaded == false) then
		Data.PlayerStatus.metadata.appearanceLoaded = true
			
		RaceHandler:LoadRaceAppearance(player, Data.PlayerStatus)
		FaceHandler:LoadHead(player, Data.PlayerStatus)
	end
	
	Data = DataModule:getProfile(player).Data
	Modules.InventoryServer:StorePlayerInventory(player, Data.Inventory)
	
	--print(Data)
			
	Framework:FireRemoteChannel("StartUpConnections", player, Data)
end))

local ClientJoined = Framework:NewSignal(StartUpGroup, Services.Players.PlayerRemoving:Connect(function(player)
	
	local PlayerInv = Modules.InventoryServer:GetPlayerInventory(player)
	DataModule:Set(player, "Inventory", PlayerInv)
	DataModule:PlayerRemoving(player)
end))


Framework:Connect("InventoryRemote", function(player, Payload: RemotePayloadTypes.tInventoryRemotePayload | {RemotePayloadTypes.tInventoryRemotePayload})
	if not Framework:ValidateTypes(Payload) then return end
	
	useModules(Payload)
end)


Framework:ConnectToChannel("Combat", "Main", function(player, CombatData)
	
end)

Framework:ConnectToChannel("Data", "Main", function(player, Payload: RemotePayloadTypes.DataRemotePayload)
	
	if (Payload.Action == RemotePayloadTypes.DataRemoteActions.Set) then
		print(Payload.Action)
	end
	
	if (Payload.Action == RemotePayloadTypes.DataRemoteActions.Get) then
		print(Payload.Action)

		Framework:FireRemoteChannel("Data", player, {
			Action = "Get",
			Data = DataModule:GetProfile(player)
		})
	end
	
	if (Payload.Action == RemotePayloadTypes.DataRemoteActions.Respawn) then
		print(Payload.Action)
	end
	
end)