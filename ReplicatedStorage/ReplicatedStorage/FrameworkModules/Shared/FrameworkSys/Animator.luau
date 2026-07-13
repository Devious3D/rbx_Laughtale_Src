local Framework = require("../../Framework")
local Services, Modules, Shared

local animationMode: string = nil

local tracks = {}


local module = {}

function module:Start()
	
	local sharedMod = {"Queue"}

	if (Framework:IsClient()) then
		
		Services, Modules, Shared = Framework:Include({
			Services = {},
			Modules = {"ClientFunctions"},
			Shared = sharedMod
		})
		
		
	end
	
	if (Framework:IsServer()) then
		
		
		Services, Modules, Shared = Framework:Include({
			Services = {"Players"},
			Modules = {},
			Shared = sharedMod
		})
				
	end

	warn(script.Name)
end

function module:SetMode(mode: string)
	assert(Framework.eAnimatorMode[mode] == nil, `{mode} is not a valid animation mode`)
	animationMode = mode
end


local function getPlayer(playerName: string): Player
	assert(Framework:IsServer() == false, "Context is not server")
	return Services.Players:FindFirstChild(playerName)
end

function module:LoadAnimations(player: string, Category: string, animationObjects: {Animation}): boolean
	
	
	if (Framework:IsClient()) then
		
		local 
		
		tracks.Tracks[Category] = {}

		
		local character = Modules.ClientFunctions:GetCharacter()
				
		for i, v in pairs(animationObjects) do
			if (v.ClassName ~= "Animation") then continue end
			
			if (v.AnimationId == nil) then 
				warn(`{v.Name} has no Animation Id`)	
				continue 
			end
			
			Tracks[Category][v.Name] = v.AnimationId
			character.Humanoid.Animator:LoadAnimation(v)		
			
			Framework:Print(`Animation[{Category}]: {v.Name} Loaded`, Framework.ePrintLevel.Warn)
		end
		
	end

	if (Framework:IsServer()) then
		
		local character = getPlayer().Character
		
		for i, v in pairs(animationObjects) do
			if (v.ClassName ~= "Animation") then continue end

			if (v.AnimationId == nil) then 
				warn(`{v.Name} has no Animation Id`)	
				continue 
			end

			Tracks[player][Category][v.Name] = v.AnimationId
			character.Humanoid.Animator:LoadAnimation(v)		

			Framework:Print(`Animation[{Category}]: {v.Name} Loaded`, Framework.ePrintLevel.Warn)
		end
	end
	
	return true
end

function module:Play()
	
	if (Framework:IsClient()) then

	end

	if (Framework:IsServer()) then

	end
	
end

function module:Stop()
	
	if (Framework:IsClient()) then

	end

	if (Framework:IsServer()) then

	end
	
end

function module:Reset()
	
	if (Framework:IsClient()) then

	end

	if (Framework:IsServer()) then

	end
	
end

function module:AttachToMarker()
	
	if (Framework:IsClient()) then

	end

	if (Framework:IsServer()) then

	end
	
end

function module:Queue()
	
	if (Framework:IsClient()) then

	end

	if (Framework:IsServer()) then

	end
	
end



return module