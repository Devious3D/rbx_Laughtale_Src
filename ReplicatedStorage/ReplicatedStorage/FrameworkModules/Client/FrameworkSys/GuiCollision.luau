
local Framework = require("../../Framework")
local Services, Modules, Shared

local Player: Player
local PlayerGui: PlayerGui

local RestrictedClasses = {
	UIListLayout = 1,
	UIGridLayout = 1,
	UIPageLayout = 1,
	UITableLayout = 1,
	UISizeConstraint = 1,
	UITextSizeConstraint = 1,
	UIPadding = 1,
	UIScale = 1,
	UIFlexItem = 1,
}

local module = {}

function module:Start()

	Services, Modules, Shared = Framework:Include({
		Services = {},
		Modules = {
			"ClientFunctions"	
		},
		Shared = {}
	})

	Player = Modules.ClientFunctions:GetPlayer()
	PlayerGui=  Player.PlayerGui

	--warn(script.Name)
end

function module:DistanceCollision(params: Framework.tGuiCollisionParams): Framework.tGuiCollisionResult
	
	local result: Framework.tGuiCollisionResult = {}
	result.Hit = {}
	
	if (params.collisionType.Include ~= nil) then
		
		for i, v in pairs(params.filteredInstances) do
			if (RestrictedClasses[v.ClassName] ~= nil) then continue end
			
			local Distance = (v.AbsolutePosition - params.targetGUI.AbsolutePosition).Magnitude
			--print(`{v.Name}: {Distance}`)
			if (Distance > params.DistanceRequired) then continue end
			
			const isAlreadyDetected = table.find(result.Hit, v, 1)
			if (isAlreadyDetected) then result.Hit[isAlreadyDetected] = v continue end
			
			result.Hit[#result.Hit + 1] = v
		end
		
	elseif (params.collisionType.Exclude ~= nil)  then
		print("Implement Exclude")
	end
		
	if (#result.Hit == 1) then result.Hit = result.Hit[1] end
	return result
end

return module