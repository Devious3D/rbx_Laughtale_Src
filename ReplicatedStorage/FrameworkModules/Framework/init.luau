export type FrameworkIncludeHandle = {
	Services: {string} | {ModuleScript},
	Modules: {string} | {ModuleScript},
	Shared: {string} | {ModuleScript}
}

export type FrameworkPacket = {
	Modules: {string},
	Functions: {string},
	Params: {any}
}

--Example
--[[
	local Data = {
		Actions = {
			[1] = "TestFunction"
		}
		Params = {
			[1] = {
				Value1 = 1,
				Value2 = "Foo bar",
				Value3 = true
			}
		}
	}
]]
export type CallStruct_AP = {
	Actions: {string},
	Params: {any}
}

--Modules, Functions, Params

--Example
--[[
	local Data = {
	
		--List of modules
		Modules = {
			"TestModule"
		},
		
		--A list of functions to use in the module
		Functions = {
			TestModule = {
				"TestFunction"
			}
		},
		
		--Params listed with Modules as the table name;  for each function use the name of the function as an index and list the params in the table
		Params = {
			TestModule = {
				TestFunction = {
					Value1 = 1,
					Value2 = "Hello World",
					Value3 = true
				}
			}
		}
	}
]]
export type CallStruct_MFP = {
	Modules: {string},
	Functions: any,
	Params: any
}


--Gui Collision
export type tGuiCollisionType = {
	Include: boolean,
	Exclude: boolean
}

export type tGuiCollisionParams = {
	targetGUI: Frame?,
	DistanceRequired: number,
	collisionType: tGuiCollisionType,
	
	filteredInstances: {Frame?}
}

export type tGuiCollisionResult = {
	Hit: Frame? | {Frame?},
	Position: Vector2
}

--Timer

export type tTimerMetadata = {
	paused: boolean,
	stopOnTick: boolean,
	Listeners: {() -> ()}
}

export type tTimer = {
	id: string,
	currentTime: number,
	defaultTime: number,
	targetTime: number,
	noramlized: number,
	type: number,
	
	metadata: tTimerMetadata
}
 

export type tQueueMetadata = {
	freezeQueue: boolean
}

export type tQueue = {
	id: string,
	current: any,
	line:{any},
	
	metadata: tQueueMetadata 
}

export type tAnimationInfo = {
	track: AnimationTrack,
	markerGroupId: string	
}

export type tAnimatorHandle = {
	currentTracks: {tAnimationInfo},
	trackQueueId: string,
	animations: {string}
}


export type tAnimationPlayData = {
	fadeInSpeed: number,
	weight: number,
	speed: number
}

export type tQueuedAnimation = {
	track: AnimationTrack,
	playData: tAnimationPlayData
}



--// Local Variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require("../FrameworkModules/Shared/Services")


local Client = Services.RunService:IsClient()
local Server = Services.RunService:IsServer()
local IsStudio = Services.RunService:IsStudio()

local ServerStarted = script:GetAttribute("ServerStarted")
local ClientStarted = script:GetAttribute("ClientStarted")



--// TweenInfo or Tables

local Modules = {
	
	["Server"] = {},
	["Client"] = {},
	["Shared"] = {},
	
}


local ActiveRemotes: {RemoteEvent} = {
	Channels = {}
}
local RemoteSignals: {RemoteEvent} = {
}
local Connections: {RBXScriptConnection?} = {
	Groups = {}
}

--// Values (Bool, Strings, Int, etc.)

--// Main Functions

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteChannelsFolder = RemotesFolder.Channels


local module = {}
module.__index = module

module.ClientDebugMode = false
module.ServerDebugMode = false 
module.BlockConsolePrints = false

module.eTimerType = {
	tickUp = 1,
	tickDown = 2
}

module.eAnimatorMode = {
	client = 1,
	server = 2
}

module.ePrintLevel = {
	Warn = 1,
	Error = 2,
}

function module.new()
	Modules = {
		Server = {},
		Client =  {},
		Shared = {}
	}
	
	local ModulesFolder = Services.ReplicatedStorage.FrameworkModules

	for _, v in pairs(ModulesFolder.Shared:GetDescendants()) do
		if not v:IsA("ModuleScript") then continue end
		
		Modules.Shared[v.Name] = require(v)
	end
		
	if Server then	
		-- Gather
		for _, v in pairs(ModulesFolder.Server:GetDescendants()) do
			if not v:IsA("ModuleScript") then continue end
			--print(v.Name)
			Modules.Server[v.Name] = require(v)
		end

		table.freeze(Modules.Server)
	end

	if Client then
		
		--Gather
		for _, v in pairs(ModulesFolder.Client:GetDescendants()) do
			if not v:IsA("ModuleScript") then continue end
			--print(v.Name)
			Modules.Client[v.Name] = require(v)
		end
		
		table.freeze(Modules.Client)
	end

end

function module:Start(Callback)


	if ServerStarted  and  ClientStarted then
		return
	end	

	for _, v in pairs(Modules.Shared) do
		if v["Start"] then
			v:Start()
		end
	end

	if Server then

		for _, v in pairs(Modules.Server) do
			if v["Start"] then
				v:Start()
			end
		end

		script:SetAttribute("ServerStarted", true)
		if Callback then task.defer(function() Callback() end) end

		local ServerTickFunctionId = module:NewConnectionGroup("ServerTickFunctions")

		module:NewSignal(ServerTickFunctionId,  Services.RunService.Heartbeat:Connect(function(delta)

			for i, v in pairs(Modules.Server) do
				if v.Tick == nil then continue end
				task.spawn(function() v.Tick(delta) end)
			end

			 for i, v in pairs(Modules.Shared) do
			 	if v.Tick == nil then continue end
			 	task.spawn(function() v.Tick(delta) end)
			 end
			 			
		end))
		
		module:NewSignal(ServerTickFunctionId, Services.RunService.PreSimulation:Connect(function(deltaSim)
			
			for i, v in pairs(Modules.Server) do
				if v.PreTick == nil then continue end
				task.spawn(function() v.PreTick(deltaSim) end)
			end

			for i, v in pairs(Modules.Shared) do
				if v.PreTick == nil then continue end
				task.spawn(function() v.PreTick(deltaSim) end)
			end
			
			
			
		end))

	end

	if Client then
		

		for _, v in pairs(Modules.Client) do		
			if v["Start"] then
				v:Start()
			end
 		end

		script:SetAttribute("ClientStarted", true)	
		
		if Callback then task.defer(function() Callback() end) end
		
		module:NewSignal(nil, Services.RunService.Heartbeat:Connect(function(delta)	
			--if Modules.Client.ClientFunctions.DataLoaded == nil then return end
			--if Modules.Client.ClientFunctions.DataLoaded == false then return end



			for i, v in pairs(Modules.Client) do
				if v.Tick == nil then continue end
				task.spawn(function() v.Tick(delta) end)
			end

			for i, v in pairs(Modules.Shared) do
				if v.Tick == nil then continue end
				task.spawn(function() v.Tick(delta) end)
			end

			--print(`Client: {gcinfo()}`)
		end))
		
		module:NewSignal(nil, Services.RunService.PreRender:Connect(function(delta)
			--if Modules.Client.ClientFunctions.DataLoaded == nil then return end
			--if Modules.Client.ClientFunctions.DataLoaded == false then return end

			for i, v in pairs(Modules.Client) do
				if v.RenderTick == nil then continue end
				task.spawn(function() v.RenderTick(delta) end)
			end
		end))

	end

end


local aplhabet = require(script.Alphabet)
function module:GenerateID(): string
		
	const length = 10
	local id = ""
	
	for i=0, length  do 
		local letterOrNum = math.random(0, 1)
		
		if (letterOrNum == 0) then id = `{id}{aplhabet[math.random(1, #aplhabet)]}` end
		if (letterOrNum == 1) then id = `{id}{tostring(math.random(0, 9))}` end
	end
	
	return id
end

function module:BenchmarkSpeed(func)
	
	const Then = os.clock()
	
	func()
	
	const Now = os.clock()
	
	--not accurate
	print(math.abs(Then - Now))	
end


function module:GetModule(ModuleName: string): ModuleScript
	local Modules = ReplicatedStorage.Modules:GetDescendants()
	local RequestedModule: ModuleScript

	for i, v in pairs(Modules) do
		if v.ClassName ~= "ModuleScript" then continue end
		if v.Name ~= ModuleName then continue end
		
		if v.Parent.ClassName ~= "Folder" then continue end

		RequestedModule = v
		break
	end

	return RequestedModule
end


function module:Include(tbl: FrameworkIncludeHandle)

	local RequestedServices: {ServiceProvider} = {}
	if tbl.Services ~= nil then
		for i, v in pairs(tbl.Services) do
			if Services[v] == nil then continue end
			RequestedServices[v] = Services[v]
		end 
	end

	local RequestedModules: {ModuleScript?} = {}
	if tbl.Modules ~= nil then

		for i, v in pairs(tbl.Modules) do
	
			if Server and Modules.Server[v]  then	
				if Modules.Server[v] == nil then continue end			
				RequestedModules[v] = Modules.Server[v]
			end
	
			if Client and Modules.Client[v] then
				if Modules.Client[v] == nil then continue end			
				RequestedModules[v] = Modules.Client[v]
			end

		end
	end

	local RequestedSharedModules: {ModuleScript?} = {}
	if tbl.Shared ~= nil then
		for i, v in pairs(tbl.Shared) do
			if Modules.Shared[v] == nil then continue end			
			RequestedSharedModules[v] = Modules.Shared[v]
		end
	end
	--print(Modules)
	
	return RequestedServices, RequestedModules, RequestedSharedModules
end

function module:IsServer(): boolean
	return Services.RunService:IsServer();
end

function module:IsClient(): boolean
	return Services.RunService:IsClient();
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

function module:MakeWeakTable(tbl)
	if type(tbl) ~= "table" then return end
	return setmetatable(tbl, {__mode = "kv"})
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

--[[
	This Creates a new Script Signal
	<code>Group</code>: connection group, if nil, it will be added to the main connection list
	<code>Thread</code>: the signal to connect too
]]
function module:NewSignal(GroupId: string, Thread: RBXScriptConnection): string
	local connectionId = module:GenerateID()
	
	
	if GroupId ~= nil and Connections.Groups[GroupId] ~= nil then
			
		local GroupToAddToo = Connections.Groups[GroupId]
		if GroupToAddToo[connectionId] ~= nil then return nil end

		GroupToAddToo[connectionId] = Thread

		return connectionId
	end

	if Connections[connectionId] ~= nil then return nil end
	Connections[connectionId] = Thread
	
	
	return connectionId
end


function module:GetGroupFromConnection(id: string): string

	local ConnectionGroup: RBXScriptConnection? = nil

	for i, v in pairs(Connections.Groups) do
		for SigName, Connection in pairs(v) do
			if SigName ~= id then continue end

			ConnectionGroup = i

			break
		end
	end

	return ConnectionGroup
end

function module:DestroyConnection(id): boolean

	if typeof(id) == "string" then
		if Connections[id] == nil then 

			local ConnectionGroup =  module:GetGroupFromConnection(id)
			if ConnectionGroup == nil then return end 

			Connections.Groups[ConnectionGroup][id]:Disconnect()
			Connections.Groups[ConnectionGroup][id] = nil
			
			return 
		end	

		Connections[id]:Disconnect()
		Connections[id] = nil
		
	elseif typeof(id) == "table" then

		for i, v in pairs(id) do
			if Connections[v] == nil then

				local Group =  module:GetGroupFromConnection(i)
				if Group == nil then return end 
	
				Connections.Groups[Group][i]:Disconnect()
				Connections.Groups[Group][i] = nil

				continue
			end
		
			Connections[v]:Disconnect()
			Connections[v] = nil
		end

	end

end

function module:FindConnection(id) 
	local IsInGroup = module:GetGroupFromConnection(id)
	if IsInGroup ~= nil then return true end

	if Connections[id] ~= nil then return true end

	return false
end

function module:NewConnectionGroup(): string
	local newGroupId = module:GenerateID()
	
	if Connections.Groups[newGroupId] ~= nil then return end
	Connections.Groups[newGroupId] = {}
	
	--print(Connections.Groups)
	return newGroupId
end

function module:FindGroup(id: string): boolean
	if Connections.Groups[id] == nil then return false end
	if Connections.Groups[id] ~= nil then return true end

	return false
end

function module:ClearGroup(id: string)
	assert(Connections.Groups[id] ~= nil, `{id} does not exsist`)
	
	--print(id)
	--print(Connections.Groups)
	
	for i, v in pairs(Connections.Groups[id]) do
		module:DestroyConnection(v)
	end
end

function module:DestroyGroup(id: string)
	if Connections.Groups[id] == nil then return end
	module:DestroyConnection(Connections.Groups[id])
	Connections.Groups[id] = nil
	--print(Connections.Groups)
end

function module:DestroyAllGroups()
	for i, v in pairs(Connections.Groups) do
		module:DestroyGroup(i)
	end
end

--function module:BindRender(Name, Priority, Action, Thread )
--	if not Client or Connections[Name] or type(Name) ~= "string" or type(Priority) ~= "number" then
				
--		error("Check Here")
--		return 
--	end
	
--	if Action == "Make" then		
--		Connections[Name] = Services.RunService:BindToRenderStep(Name, Priority, Thread)				
--	elseif Action == "Destroy" then		
--		Services.RunService:UnbindFromRenderStep(Name)
--	end
	
--end




------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Remote Channel System

function module:CreateRemoteChannel(Name: string, AmountOfChannels: number): nil
	if not Server then return end
	if  module:FindChannel(Name) then return end
	if AmountOfChannels > 5 then error("Too Many Channels") return end

	--Create the folder
	--Create the remotes with the # of channels

	local NewFolder = Instance.new("Folder")
	NewFolder.Name = `{Name}Channels`
	NewFolder.Parent = RemoteChannelsFolder
	NewFolder:SetAttribute("ChannelAmount", AmountOfChannels)
	NewFolder:SetAttribute("CurrentRemoteUsed", 1)

	ActiveRemotes.Channels[Name] = NewFolder

	for i = 1, AmountOfChannels, 1 do
		
		local NewRemote = Instance.new("RemoteEvent")
		NewRemote.Name = `{Name}Channel{i}`
		NewRemote.Parent = NewFolder

	end

	module:NewConnectionGroup(`{Name}Channels`)
end

function module:ConnectToChannel(ChannelName: string, ConnectionName: string, Thread: (any) -> (nil)): boolean
	if not module:FindChannel(ChannelName) then return nil end

	local Remotes: {RemoteEvent} = module:GetChannel(ChannelName)
	
	--if ConnectionName == "WaitingForMicSword" then print("WaitingForMicSword") end

	for i = 1, module:GetNumChannels(ChannelName), 1 do
		if Client then module:NewSignal(`{ConnectionName}{ChannelName}ChannelConnection{i}`, `{ChannelName}Channels`, Remotes[i].OnClientEvent:Connect(Thread)) end
		if Server then module:NewSignal(`{ConnectionName}{ChannelName}ChannelConnection{i}`, `{ChannelName}Channels`, Remotes[i].OnServerEvent:Connect(Thread)) end
	end

	return true
end

function module:DisconnectFromChannel(ChannelName: string, ConnectionName: string)
	if not module:FindChannel(ChannelName) then return nil end

	local Remotes: {RemoteEvent} = module:GetChannel(ChannelName)

	for i = 1, module:GetNumChannels(ChannelName), 1 do
		if Client then module:DestroyConnection(`{ConnectionName}{ChannelName}ChannelConnection{i}`) end
		if Server then module:NewSignal(`{ConnectionName}{ChannelName}ChannelConnection{i}`) end
	end
end

--function module:DisconnectAllChannels()
--	local Remotes: {RemoteEvent} = module:GetChannel(ChannelName)

--	--if ConnectionName == "WaitingForMicSword" then print("WaitingForMicSword") end

--	for i = 1, module:GetNumChannels(ChannelName), 1 do
--		if Client then module:NewSignal(`{ConnectionName}{ChannelName}ChannelConnection{i}`, `{ChannelName}Channels`, Remotes[i].OnClientEvent:Connect(Thread)) end
--		if Server then module:NewSignal(`{ConnectionName}{ChannelName}ChannelConnection{i}`, `{ChannelName}Channels`, Remotes[i].OnServerEvent:Connect(Thread)) end
--	end

--	return true
--end

function module:DestroyChannel(Name: string): number | nil
	if not Server then return nil end
	if not module:FindChannel(Name) then return nil end

	if module:FindGroup(`{Name}Channel`) then module:DestroyGroup(`{Name}Channel`) end
	ActiveRemotes.Channels[Name] = nil

	RemoteChannelsFolder[`{Name}Channels`]:Destroy()
end 


function module:FireRemoteChannel(Name: string, ...): nil
	if not module:FindChannel(Name) then return nil end
	local RandomChannel = module:GetRandomChannel(Name)


	if Server then RandomChannel:FireClient(...) end
	if Client then RandomChannel:FireServer(...) end
end

function module:Channel_FireAll(Name: string, ...): nil
	if not Server then return end
	if not module:FindChannel(Name) then return nil end
	local RandomChannel = module:GetRandomChannel(Name)

	RandomChannel:FireAllClients(...)
end


--[[
	Make sure the player has a tag called ReplicationReady

	local Data = {
		ReplicationRange
		Modules = {},   (EX: Modules = {"TestModule"})
		Functions = {}, (EX:  Functions = {TestModule = {"DoFunction"}})
		Params = {}     (EX: Params  = {TestModule = {DoFunction = {MyVar = 10} }})
	}
]]
function module:ChannelReplication(Name: string, ReplicateFor: string | {string}, Data: {any}): string | nil
	if not Server then return end
	if not module:FindChannel(Name) then return nil end
	
	if  ReplicateFor == "Server" then	
		return "Server"
	end

	if ReplicateFor == "All" then
		module:Channel_FireAll(Name, Data)
		return
	end
	
	if ReplicateFor == "InRange" then
			
		--local PlayersMentioned = {}

		--for i, v in pairs(ReplicateFor) do

		--	local playerInService = Services.Players:FindFirstChild(v)
		--	if playerInService:HasTag('ReplicationReady') == false then continue end
			
			

		--	PlayersMentioned[v] = playerInService
		--end

		--for i, player in pairs(PlayersMentioned) do
		--	module:FireRemoteChannel(Name, player, Data)
		--end
			
	end

	if typeof(ReplicateFor) == "table" then

		local PlayersMentioned = {}

		for i, v in pairs(ReplicateFor) do
			
			local playerInService = Services.Players:FindFirstChild(v)
			--if playerInService:HasTag('ReplicationReady') == false then continue end
			
			PlayersMentioned[v] = playerInService
		end

		for i, player in pairs(PlayersMentioned) do
			module:FireRemoteChannel(Name, player, Data)
		end

		return
	end

end


function module:FindChannel(Name: string): boolean
	local IsFound = false

	pcall(function()
		local Channel = RemoteChannelsFolder[`{Name}Channels`]
		if Channel ~= nil then IsFound = true end
	end)

	return IsFound
end

 
function module:GetRandomChannel(Name: string): RemoteEvent | nil
	if not module:FindChannel(Name) then return nil end

	local Remotes = RemoteChannelsFolder[`{Name}Channels`]:GetChildren()
	
	local Channel: Folder = RemoteChannelsFolder[`{Name}Channels`]
	local NextRoundRobinIndex = (Channel:GetAttribute("CurrentRemoteUsed") % #Channel:GetChildren()) + 1
	Channel:SetAttribute("CurrentRemoteUsed", NextRoundRobinIndex)

	return Remotes[NextRoundRobinIndex]
end

--Returns all the remotes
function module:GetChannel(Name: string): {RemoteEvent} | nil
	if not module:FindChannel(Name) then return nil end
	return RemoteChannelsFolder[`{Name}Channels`]:GetChildren()
end

function module:GetNumChannels(Name: string): number | nil
	if not module:FindChannel(Name) then print(Name) return nil end
	return RemoteChannelsFolder[`{Name}Channels`]:GetAttribute("ChannelAmount")
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

function module:CreateRemote(Name)
	if not Server then return end
	if typeof(Name) ~= "string" then return end
	if ActiveRemotes[Name] then return end
	
	local NewRemote = Instance.new("RemoteEvent")
	NewRemote.Name = Name
	NewRemote.Parent = RemotesFolder
	ActiveRemotes[Name] = NewRemote
	
	return NewRemote
end

function module:CreateBindable(Name)	
	if not Server then return end
	if typeof(Name) ~= "string" then return end
	if ActiveRemotes[Name] then return end

	local NewRemote = Instance.new("BindableEvent")
	NewRemote.Name = Name
	NewRemote.Parent = RemotesFolder
	ActiveRemotes[Name] = NewRemote

	return NewRemote	
end

function module:CreateInvoke(Name) 
	if not Server then return end
	if typeof(Name) ~= "string" then return end
	if ActiveRemotes[Name] then return end
	
	local newRf = Instance.new("RemoteFunction")
	newRf.Name = Name
	newRf.Parent = RemotesFolder
	ActiveRemotes[Name] = newRf
	
	return newRf
end

function module:Fire(Name, ...)
	if typeof(Name) ~= "string" then error("Name is not a string") return end	
	local Signal = RemotesFolder[Name]	
	if Signal == nil then print(Name .. " is nil") return end


	if Server then
		
		if Signal:IsA("RemoteFunction") then
			Signal:InvokeClient(...)
		else
			Signal:FireClient(...)
		end
		
	elseif Client then
		
		if Signal:IsA("RemoteFunction") then
			Signal:InvokeServer(...)
		else
			Signal:FireServer(...)
		end
		
	end
end

function module:Connect(Name, func)
	if type(Name) ~= "string" then return end
	local Signal = RemotesFolder[Name]
	if Signal == nil then return end
	
	if Server then
		
		if Signal.ClassName ~= "RemoteEvent" then
			Signal.OnServerInvoke = func
			--print("Connected " .. Name)

		else
			Signal.OnServerEvent:Connect(func)		
			--print("Connected " .. Name)
		end
		
	elseif Client then
				
		if  Signal.ClassName ~= "RemoteEvent" then
			Signal.OnClientInvoke = func
			--print("Connected " .. Name)

		else
			Signal.OnClientEvent:Connect(func)		
			--print("Connected " .. Name)
		end
		
	end
end

function module:GetRemote(RemoteName: string): RemoteEvent?
	if (not module:ValidateTypes({RemoteName})) then return end
	if (RemotesFolder:WaitForChild(RemoteName) == nil) then return end
	
	local Remote: RemoteEvent? = RemotesFolder:WaitForChild(RemoteName)
	return Remote
end

function module:FireAll(Name, ...)
	if typeof(Name) ~= "string" then return end
	
	local Signal = RemotesFolder[Name]
	if Signal == nil then return end
	
	Signal:FireAllClients(...)
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

function module:adp_CreateTimer(): tTimer
	
end

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------


function module:ValidateTypes(Data: {any}): boolean
	if (type(Data) ~= "table") then 
		module:Print(`{script.Name} [405]: Has to be a table`, "Warn")
		return 	
	end

	local TypesAreValid = true

	local function NumberIsValid(n :number):boolean
		local Invalid = true

		if (n ~= n) then
			Invalid = false
			module:Print(`{script.Name} [416]: Case 1`, "Warn")
		end

		if (math.abs(n) >= math.huge) then
			module:Print(`{math.abs(n)} >= {math.huge}`, "Warn ")
			Invalid = false
		end

		return Invalid
	end

	local function ReadTypes(Value)
		if (type(Value) == "nil") then return end
		if (typeof(Value) == "number" and not NumberIsValid(Value)) then
			TypesAreValid = false			
		end
	end

	for i, v in pairs(Data) do
		ReadTypes(v)

		if type(v) == "table"  then
		
			for e, r in pairs(v) do
				ReadTypes(v)
			end
		end

	end

	return TypesAreValid
end
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function module:Debug_GetModules():  {any}
	if (Services.RunService:IsClient()) then
		return Modules.Client
	end
end

function module:Debug_GetConnections(): {any}
	return Connections
end

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--function module:NewLinkedList()
--	return require(script.LinkedList)
--end
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function module:Print(Message: string, Level:number)
	if module.BlockConsolePrints then return end
	--if (IsStudio) then return end

	local printlevels = {

		[module.ePrintLevel.Warn] = function()
			warn(Message)
		end,

		[module.ePrintLevel.Error] = function()
			error(Message)
		end
	}

	if (printlevels[Level]) then printlevels[Level]() return end

	print(Message)
end

function module:ClearMind()
	
	if (Services.RunService:IsClient()) then

		Modules.Client = {}
		script:SetAttribute("ClientStarted", false)
		module:DestroyConnection(`{script.Name}ClientHeartbeat`)
		--print(Modules.Client)
	end

	if (Services.RunService:IsServer()) then
		Modules.Server = {}
		script:SetAttribute("ServerStarted", false)
		module:DestroyConnection(`{script.Name}ServerHeartbeat`)
	end
	
	module:DestroyAllGroups()

	for Name, v in pairs(Connections) do
		if typeof(v) == "table" then continue end
		--if Connections[Name] == nil then continue end
	
		v:Disconnect()
	end
	

	--Make the game kick the player if they are still in the game
end

return module