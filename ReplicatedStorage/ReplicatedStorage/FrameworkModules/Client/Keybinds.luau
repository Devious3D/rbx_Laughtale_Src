local Framework = require("../Framework")
local Services, Modules, Shared

local DataTemplateTypes = require("../Types/DataTemplateTypes")

local module = {}

function module:Start()
			  			
	Services, Modules, Shared = Framework:Include({
		Services = {"ReplicatedStorage"},
		Modules = {"ClientFunctions"},
		Shared = {}
	})
	
	warn(script.Name)
end



--Core Load Process
function module:CreateKeybinds(): boolean
	local ClientFunctions = Modules.ClientFunctions
	
	local keybinds: DataTemplateTypes.tKeybinds = ClientFunctions:GetPlayerData().KeybindData
	local ReplicatedStorage = Services.ReplicatedStorage
	local InputFolder = ReplicatedStorage.FrameworkModules.Inputs
	local GameplayInputs: InputContext = InputFolder.GameplayInputs
	
	for i, Action: InputAction in pairs(GameplayInputs:GetChildren()) do
		for e, Binding: InputBinding in pairs(Action:GetChildren()) do
			Binding:Destroy()
		end
	end
	
	for i:string , bindings: string in pairs(keybinds) do
		local inputAction: InputAction = GameplayInputs:FindFirstChild(i)
		
		for a, bind: string in pairs(bindings) do
			local inputbind = Instance.new("InputBinding")
			inputbind.Name = bind
						
			inputbind.KeyCode = Enum.KeyCode[bind]
			inputbind.Parent = inputAction
		end
		
		
	end
	
	return true
end

return module