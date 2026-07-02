local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS              = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- Bootstrap: wait for framework + CombatClient to be ready
---------------------------------------------------------------------------
local framework = require(ReplicatedStorage.FrameworkModules.Framework)
local RemotePayloadTypes = require(ReplicatedStorage.FrameworkModules.Types.RemotePayloads)

local functionClientStart = function(Table)
	
	-- CombatClient is loaded by the framework on Start(), so we wait for it
	-- via the StartUpConnections channel (same as the Central script does).
	
	framework.new()
	
	local Services, Modules, Shared = framework:Include({
		Services = {},
		Modules = { "CombatClient", "ClientFunctions" },
		Shared = {}
	})

	local ComabtClient = Modules.CombatClient
	local ClientFunctions = Modules.ClientFunctions

	ClientFunctions.PlayerData = Table

	-- Give CombatClient a reference to the local character once it exists
	local char = player.Character
	ClientFunctions.Character = char
	ClientFunctions.Player = player
	
	--print(ClientFunctions.Player.Name)
	
	framework:Start()

	ComabtClient:Init(char)

	--framework:NewSignal("Client_CharacterAdded", nil, player.CharacterAdded:Connect(function(newChar)
	--	ComabtClient:Init(newChar)
	--end))


	local Keybinds = Table.KeybindData
	---------------------------------------------------------------------------
	-- INPUT
	---------------------------------------------------------------------------
	local InputObjects = ReplicatedStorage.FrameworkModules.Inputs.GameplayInputs
	InputObjects.TestKey.Pressed:Connect(function()
		
	end)
	
	
	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		
		-- ATTACK (Left Click)
		if input.UserInputType == Enum.UserInputType[Keybinds.Attack] then
			ComabtClient:DoAttack()
		end

		-- BLOCK (F) hold
		if input.KeyCode == Enum.KeyCode[Keybinds.Block] then
			ComabtClient:StartBlock()
		end

		-- EQUIP (E)
		if input.KeyCode == Enum.KeyCode[Keybinds.Equip] then
			--print("Combat")
			ComabtClient:ToggleEquip()
		end

		-- DASH (Q)
		if input.KeyCode == Enum.KeyCode[Keybinds.Dash] then
			ComabtClient:TryDash()
		end

		-- HIGH JUMP charge (T)
		if input.KeyCode == Enum.KeyCode[Keybinds.HighJump] then
			ComabtClient:StartHighJump()
		end

		-- SLIDE JUMP (Space while sliding)
		if input.KeyCode == Enum.KeyCode.Space then
			ComabtClient:TrySlideJump()
		end

		-- CROUCH / SLIDE (LeftControl)
		if input.KeyCode == Enum.KeyCode.LeftControl then
			ComabtClient:TryCrouchOrSlide()
		end

		-- DOUBLE TAP W TO RUN
		if input.KeyCode == Enum.KeyCode.W then
			ComabtClient:TryRun()
		end
	end)

	UIS.InputEnded:Connect(function(input, gpe)
		if gpe then return end

		-- RELEASE BLOCK
		if input.KeyCode == Enum.KeyCode.F then
			ComabtClient:EndBlock()
		end

		-- RELEASE HIGH JUMP
		if input.KeyCode == Enum.KeyCode.T then
			ComabtClient:ReleaseHighJump()
		end

		-- STOP RUNNING
		if input.KeyCode == Enum.KeyCode.W then
			ComabtClient:TryStopRun()
		end
	end)
	
	
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



framework:ConnectToChannel("StartUpConnections", "LocalScriptStartup", functionClientStart)

framework:ConnectToChannel("Data", "Main", function(Payload : RemotePayloadTypes.DataRemotePayload)
	
	print(Payload)
	
	if (Payload.Action == "Get")  then
		print(Payload.Data)
	end
end)
