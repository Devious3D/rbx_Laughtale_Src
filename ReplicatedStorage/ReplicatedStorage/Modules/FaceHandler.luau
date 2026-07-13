local ReplicatedService = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
--local PlayerDataHandler = require(game:GetService("ServerScriptService"):WaitForChild("PlayerDataHandler")) -- adjust path as needed
local HairColorTypes = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ColorTables"):WaitForChild("MultiColors"))
local Utility = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Utility"))
local boyngirlhairsfolder = ServerStorage.Hairs

local DataTemplateTypes = require("../FrameworkModules/Types/DataTemplateTypes")

local FaceHandler = {}

local function SetUniformPivotAndDirection(hairModel: Model, hairPartName: string?, yawOffsetDeg: number?)
	if not hairModel or not hairModel:IsA("Model") then
		warn("SetUniformPivotAndDirection: hairModel invalid")
		return
	end

	local yaw = math.rad(yawOffsetDeg or 0)

	local hairPart: BasePart? = nil
	if hairPartName and hairPartName ~= "" then
		local found = hairModel:FindFirstChild(hairPartName, true)
		if found and found:IsA("BasePart") then
			hairPart = found
		end
	end
	if not hairPart then
		local found = hairModel:FindFirstChild("Hair", true)
		if found and found:IsA("BasePart") then
			hairPart = found
		else
			hairPart = hairModel:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	if not hairPart then
		warn("SetUniformPivotAndDirection: no BasePart found in model")
		return
	end

	if not hairModel.PrimaryPart then
		hairModel.PrimaryPart = hairPart
	end

	local pos = hairModel:GetPivot().Position
	local uniformCF = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)

	hairModel:PivotTo(uniformCF)

	hairPart.CFrame = uniformCF
end


local function PickRandomChildAndSave(folder: Folder, value)
	if not folder or not folder:IsA("Folder") then
		warn("PickRandomChildAndSave: Invalid folder")
		return
	end

	if not value then
		warn("PickRandomChildAndSave: Invalid value object")
		return
	end

	local children = folder:GetChildren()
	if #children == 0 then
		warn("PickRandomChildAndSave: Folder is empty:", folder:GetFullName())
		return
	end

	local picked = children[math.random(1, #children)]
	value = picked.Name

	return picked
end


function FaceHandler:LoadHead(plr, PlayerStatusData:DataTemplateTypes.tPlayerStatusData): DataTemplateTypes.tAppearanceComponent
	local character = plr.Character
	local facesFolder = ServerStorage:FindFirstChild("Faces")
	local HairFolder
	
	--local PlayerStatusData: DataTemplateTypes.tPlayerStatusData = PlayerDataHandler:Get(plr, "PlayerStatus")

	if PlayerStatusData.Gender == "Male" then
		HairFolder = boyngirlhairsfolder.Boy
	else
		HairFolder = boyngirlhairsfolder.Girl
	end

	if not character then return end

	local RealHead = character:WaitForChild("Head")

	local FH = character:FindFirstChild("FakeHead")
	if FH then
		return
	end

	local Fakehead = RealHead:Clone()
	Fakehead.Name = "FakeHead"

	Fakehead.Transparency = 1
	Fakehead.CanCollide = false
	Fakehead.CanQuery = false
	Fakehead.CanTouch = false
	Fakehead.Massless = true
	Fakehead.Anchored = false

	Fakehead.Size = RealHead.Size

	Fakehead.Parent = character
	Fakehead.CFrame = RealHead.CFrame

	local weld = Instance.new("Weld")
	weld.Part0 = RealHead
	weld.Part1 = Fakehead
	weld.C0 = CFrame.new()
	weld.C1 = CFrame.new()
	weld.Parent = Fakehead

	local appearance = PlayerStatusData.Appearance
	local raceData = PlayerStatusData.Race
	local tempFace = appearance.TempFace
	local HairType = appearance.PrimaryHairType
	local HairColor = appearance.HairColor1

	if tempFace == nil or tempFace == "" then
		tempFace = tostring(math.random(1, 4))
		appearance.TempFace = tempFace
	else
		tempFace = tostring(tempFace)
	end

	if HairType == nil or HairType == "" then
		print(HairFolder)
		HairType = PickRandomChildAndSave(HairFolder, HairType)
		if typeof(HairType) == "string" then
			appearance.PrimaryHairType = HairType
		else
			appearance.PrimaryHairType = tostring(HairType)
		end
	end

	if HairColor == nil or HairColor == "" then
		warn("no hair color so Im rolling it rn")
		local sub = raceData.Sub

		if sub == "Nefertari" then
			HairColor = HairColorTypes.Nefertari
			warn("set it to nef")
		elseif sub == "Donquixote" then
			HairColor = HairColorTypes.Donquixote
			warn("set it to don")
		elseif sub == "Riku" then
			HairColor = HairColorTypes.Riku
			warn("set it to riku")
		elseif sub == "Kouzuki" then
			HairColor = HairColorTypes.Kouzuki
			warn("set it to kouz")
		else
			local rolledHcolor = Utility:randomKeyFromDict(HairColorTypes)
			print(rolledHcolor)
			HairColor = rolledHcolor
			if typeof(rolledHcolor) == "string" then
				appearance.HairColor1 = HairColor
			else
				appearance.HairColor1 = tostring(HairColor)
			end

			warn("set it to", HairColor)
		end
	end

	if not HairFolder then
		warn("FaceHandler: ServerStorage.Hairs missing")
		return
	end

	if not facesFolder then
		warn("FaceHandler: ServerStorage.Faces missing")
		return
	end

	local decalTemplate = facesFolder:FindFirstChild(tempFace)
	if not decalTemplate or not decalTemplate:IsA("Decal") then
		error("Missing/invalid decal for face:", tempFace)
		return
	end

	local actualface = decalTemplate:Clone()
	actualface.Parent = Fakehead

	print(HairType)
	local H = HairFolder[tostring(HairType)]:Clone()
	H:SetPrimaryPartCFrame(RealHead.CFrame)
	local NewHair = H.Head.Hair
	NewHair.Size *= raceData.Scale
	NewHair.Massless = true
	print(HairColor)
	NewHair.Name = tostring(HairType)

	if typeof(HairColor) == "string" then
		NewHair.Color = HairColorTypes[HairColor]
	elseif typeof(HairColor) == "Color3" then
		NewHair.Color = HairColor
	end

	local w = NewHair:FindFirstChild("Weld")
	w.Part0 = RealHead
	w.Part1 = NewHair
	w.Parent = w.Part1;

	NewHair.Parent = plr.Character

	plr.Character[NewHair.Name].Anchored = false
	
	
	--PlayerDataHandler:Set(plr, "PlayerStatus", PlayerStatusData)


	H:Destroy()
	
	return PlayerStatusData.Appearance
end

return FaceHandler