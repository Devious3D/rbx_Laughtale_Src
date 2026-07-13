local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS              = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- Bootstrap: wait for framework + CombatClient to be ready
---------------------------------------------------------------------------
local framework = require(ReplicatedStorage.FrameworkModules.Framework)
local RemotePayloadTypes = require(ReplicatedStorage.FrameworkModules.Types.RemotePayloads)

local main = function(Table)
	
	-- CombatClient is loaded by the framework on Start(), so we wait for it
	-- via the StartUpConnections channel (same as the Central script does).
	
	framework.new()

	local Services, Modules, Shared = framework:Include({
		Services = {
			"RunService",
			"ContentProvider"
		},
		Modules = {"ClientFunctions", "Keybinds"},
		Shared = {"Timer", "Queue", "Animator"}
	})

	local ComabtClient = Modules.CombatClient
	local ClientFunctions = Modules.ClientFunctions

	ClientFunctions.PlayerData = Table

	-- Give CombatClient a reference to the local character once it exists
	ClientFunctions.Character = player.Character
	ClientFunctions.Player = player

	framework:Start()
	
	local LoadQueueId = Shared.Queue:new({
		--1 Load Character
		function (): boolean
			return Modules.ClientFunctions:SecondaryStart()
		end,
		
		--2 Load Animations
		function(): boolean
			print("Animations")
			return false
		end,
		--3 Load Keybinds
		
		function(): boolean
			print("Keybinds")
			return Modules.Keybinds:CreateKeybinds()
		end,
	})
	
	Shared.Queue:delete(LoadQueueId)
	
	local Animations = ReplicatedStorage.Assets.Animations:GetDescendants()
	Shared.Animator:SetMode(framework.eAnimatorMode.client)
	local succ = Shared.Animator:LoadAnimations(nil, "Movement", Animations)
	Modules.Keybinds:CreateKeybinds()
		
	--while (Shared.Queue:find(LoadQueueId)) do
	--	local item: () -> (boolean) = Shared.Queue:next(LoadQueueId)
	--	local result = item()
	--	if result == false then 
			
	--		local queueObj: framework.tQueue = Shared.Queue:get(LoadQueueId)
	--		error(`("Load Failed {queueObj}`)
	--	end
		
	--	task.wait(.1)
	--end
	

	do
		local InputObjects = ReplicatedStorage.FrameworkModules.Inputs.GameplayInputs
		InputObjects.TestKey.Pressed:Connect(function()

			local newQueueId: framework.tQueue = Shared.Queue:new({1, 2, 3, 4, 5})
			print(Shared.Queue:get(newQueueId))

			local id: framework.tTimer = Shared.Timer:new(1, framework.eTimerType.tickDown)
			Shared.Timer:start(id)

			local connectionId		
			connectionId = Shared.Timer:connect(id, function()
				--Shared.Timer:disconnect(connectionId, id)		
				print(Shared.Queue:next(newQueueId))
				
				if (Shared.Queue:size(newQueueId) == 0)  then
					Shared.Queue:insert(newQueueId, {1, 2, 3, 4, 5})
				end
			end)
			
		end)
	end
	
		
	do
		--UIS.InputBegan:Connect(function(input, gpe)
		--	if gpe then return end

		--	-- ATTACK (Left Click)
		--	if input.UserInputType == Enum.UserInputType[Keybinds.Attack] then
		--		ComabtClient:DoAttack()
		--		warn("you clicked m1")
		--	end

		--	-- BLOCK (F) hold
		--	if input.KeyCode == Enum.KeyCode[Keybinds.Block] then
		--		ComabtClient:StartBlock()
		--	end

		--	-- EQUIP (E)
		--	if input.KeyCode == Enum.KeyCode[Keybinds.Equip] then
		--		--print("Combat")
		--		ComabtClient:ToggleEquip()
		--	end

		--	-- DASH (Q)
		--	if input.KeyCode == Enum.KeyCode[Keybinds.Dash] then
		--		ComabtClient:TryDash()
		--	end

		--	-- HIGH JUMP charge (T)
		--	if input.KeyCode == Enum.KeyCode[Keybinds.HighJump] then
		--		ComabtClient:StartHighJump()
		--	end

		--	-- SLIDE JUMP (Space while sliding)
		--	if input.KeyCode == Enum.KeyCode.Space then
		--		ComabtClient:TrySlideJump()
		--	end

		--	-- CROUCH / SLIDE (LeftControl)
		--	if input.KeyCode == Enum.KeyCode.LeftControl then
		--		ComabtClient:TryCrouchOrSlide()
		--	end

		--	-- DOUBLE TAP W TO RUN
		--	if input.KeyCode == Enum.KeyCode.W then
		--		ComabtClient:TryRun()
		--	end
		--end)

		--UIS.InputEnded:Connect(function(input, gpe)
		--	if gpe then return end

		--	-- RELEASE BLOCK
		--	if input.KeyCode == Enum.KeyCode.F then
		--		ComabtClient:EndBlock()
		--	end

		--	-- RELEASE HIGH JUMP
		--	if input.KeyCode == Enum.KeyCode.T then
		--		ComabtClient:ReleaseHighJump()
		--	end

		--	-- STOP RUNNING
		--	if input.KeyCode == Enum.KeyCode.W then
		--		ComabtClient:TryStopRun()
		--	end
		--end)


		--framework:FireRemoteChannel("Data", {
		--	Action = "Set",
		--	Data = {}
		--})

		--framework:FireRemoteChannel("Data", {
		--	Action = "Get",
		--	Data = {}
		--})

		--framework:FireRemoteChannel("Data", {
		--	Action = "Respawn",
		--	Data = {}
		--})
	end
	
	warn("Client Init")
end



framework:ConnectToChannel("StartUpConnections", "LocalScriptStartup", main)

framework:ConnectToChannel("Data", "Main", function(Payload : RemotePayloadTypes.DataRemotePayload)
	
	print(Payload)
	
	if (Payload.Action == "Get")  then
		print(Payload.Data)
	end
end)
