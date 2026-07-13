local Utility = {}
local Tweens = {}

Utility.__index = Utility

function Utility:randomKeyFromDict(dict)
	local keys = {}
	for k, _ in pairs(dict) do
		table.insert(keys, k)
	end
	if #keys == 0 then return nil end
	return keys[math.random(1, #keys)]
	
end

function Utility:randomValinFolder(folder: Folder, valueObj: ValueBase)
	if not folder or not folder:IsA("Folder") then
		warn("PickRandomChildAndSave: Invalid folder")
		return
	end

	if not valueObj or not valueObj:IsA("ValueBase") then
		warn("PickRandomChildAndSave: Invalid value object")
		return
	end

	local children = folder:GetChildren()
	if #children == 0 then
		warn("PickRandomChildAndSave: Folder is empty:", folder:GetFullName())
		return
	end

	local picked = children[math.random(1, #children)]
	valueObj.Value = picked.Name

	return picked
end

local Repstore = game:GetService("ReplicatedStorage")

--// Tables

local Tweens = {}


local module = {}
module.__index = module

-------------------------------------------------------------------------------------
function module:Tween(Object, Info, Data, func, Override)
	if (Tweens[Object]) or (type(Data) ~= "table") and not Override then return end

	Tweens[Object] = game:GetService("TweenService"):Create(Object, Info, Data)
	Tweens[Object]:Play()
	Tweens[Object].Completed:Connect(function()

		Tweens[Object] = nil
		if func and typeof(func) == "function" then func() end		

	end)

	return Tweens[Object]
end

function module:CancelTween(Object)
	if Tweens[Object] then
		Tweens[Object] = nil
	end
end


function module:GetCurrentTweens()
	return tostring(Tweens)
end

--------------------------------------------------------------------------------------
function module:PlaySound(Name: string, Parent, Time : number)

	local Sound = game:GetService("SoundService"):FindFirstChild(Name):Clone()

	if Parent then
		Sound.Parent = Parent
	else
		Sound.Parent = game.Workspace
	end

	Sound:Play()

	game:GetService("Debris"):AddItem(Sound, Time)
end


function module:PlaySoundLocally(Name : string, Parent, Time : number)

	local Sound = game:GetService("SoundService"):FindFirstChild(Name):Clone()
	Sound.Parent = Parent	
	game:GetService("SoundService"):PlayLocalSound(Sound)


	game:GetService("Debris"):AddItem(Sound, Time)
end
----------------------------------------------------------------------------------------
function module:Raycast(Ignore, Origin, Direction, RayOrRayCast)

	local filterTable = type(Ignore) == "table" and Ignore or {Ignore}

	if RayOrRayCast == "RayCast" then
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude 
		Params.FilterDescendantsInstances = filterTable
		Params.IgnoreWater = true

		local rayResult = workspace:Raycast(Origin, Direction, Params)
		return rayResult

	elseif RayOrRayCast == "Ray" then
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = filterTable
		Params.IgnoreWater = false 
		Params.BricksWithLocalSimulation = true

		local rayResult = workspace:Raycast(Origin, Direction, Params)

		if rayResult then
			return rayResult.Instance, rayResult.Position
		end

		return nil, Origin + Direction
	end
end


return Utility