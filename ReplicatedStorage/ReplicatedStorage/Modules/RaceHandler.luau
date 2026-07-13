--local PlayerDataHandler = require(game:GetService("ServerScriptService"):WaitForChild("PlayerDataHandler")) -- adjust path as needed
local facehandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("FaceHandler"))
local serverstorage = game:GetService("ServerStorage")

local DataTemplateTypes = require("../FrameworkModules/Types/DataTemplateTypes")

local RaceHandler = {}

local ColorAppearances = {
	RegColors = {
		PastelBrown = Color3.fromRGB(255, 211, 172),
		NeonOrange = Color3.fromRGB(213, 115, 61),
		CGABROWN = Color3.fromRGB(170, 85, 0),
		Cork = Color3.fromRGB(188, 155, 93),
		ReddishBrown = Color3.fromRGB(105, 64, 40),
		PineCone = Color3.fromRGB(108, 88, 75),
		MediumBrown = Color3.fromRGB(86, 66, 54),
		Burlap = Color3.fromRGB(199, 172, 120),
		Cashmere = Color3.fromRGB(211, 190, 150),
		Khaki = Color3.fromRGB(226, 220, 188),
		Beige = Color3.fromRGB(202, 191, 163),
		FawnBrown = Color3.fromRGB(160, 132, 79),
		Linen = Color3.fromRGB(175, 148, 131),
		LightOrange = Color3.fromRGB(234, 184, 146),
		Nougat = Color3.fromRGB(204, 142, 105),
		Brown = Color3.fromRGB(124, 92, 70),
		DarkOrange = Color3.fromRGB(160, 95, 53),
		BurntSienna = Color3.fromRGB(106, 57, 9),
		DarkTaupe = Color3.fromRGB(90, 76, 66),
		SeaShell = Color3.fromRGB(233, 218, 218),
	},

	FishmanColors = {
		PastelBrown = Color3.fromRGB(255, 211, 172),
		NeonOrange = Color3.fromRGB(213, 115, 61),
		CGABROWN = Color3.fromRGB(170, 85, 0),
		Cork = Color3.fromRGB(188, 155, 93),
		ReddishBrown = Color3.fromRGB(105, 64, 40),
		PineCone = Color3.fromRGB(108, 88, 75),
		MediumBrown = Color3.fromRGB(86, 66, 54),
		Burlap = Color3.fromRGB(199, 172, 120),
		Cashmere = Color3.fromRGB(211, 190, 150),
		Khaki = Color3.fromRGB(226, 220, 188),
		Beige = Color3.fromRGB(202, 191, 163),
		FawnBrown = Color3.fromRGB(160, 132, 79),
		Linen = Color3.fromRGB(175, 148, 131),
		LightOrange = Color3.fromRGB(234, 184, 146),
		Nougat = Color3.fromRGB(204, 142, 105),
		Brown = Color3.fromRGB(124, 92, 70),
		DarkOrange = Color3.fromRGB(160, 95, 53),
		BurntSienna = Color3.fromRGB(106, 57, 9),
		DarkTaupe = Color3.fromRGB(90, 76, 66),
		SeaShell = Color3.fromRGB(233, 218, 218),
		StormBlue = Color3.fromRGB(51, 88, 130),
		Turquoise = Color3.fromRGB(130, 167, 188),
		DeepBlue = Color3.fromRGB(33, 84, 185),
		BabyBlue = Color3.fromRGB(152, 194, 219),
		CarnationPink = Color3.fromRGB(255, 152, 220),
		Lilac = Color3.fromRGB(167, 94, 155),
		Flint = Color3.fromRGB(105, 102, 92),
		SeaGreen = Color3.fromRGB(52, 142, 64),
		SandGreen = Color3.fromRGB(120, 144, 130),
		Cocoa = Color3.fromRGB(86, 36, 36),
		Maroon = Color3.fromRGB(117, 0, 0),
		Pearl = Color3.fromRGB(231, 231, 236),
		Alder = Color3.fromRGB(180, 128, 255),
		DaisyOrange = Color3.fromRGB(248, 217, 109),
		PastelLightBlue = Color3.fromRGB(175, 221, 255)
	}
}

local function RemoveRobloxDefaultAppearance(character)
	if not character then return end

	for _, inst in ipairs(character:GetChildren()) do
		if inst:IsA("Shirt") or inst:IsA("Pants") then
			inst:Destroy()
		end
	end

	for _, inst in ipairs(character:GetChildren()) do
		if inst:IsA("CharacterMesh") then
			inst:Destroy()
		end
	end

	for _, inst in ipairs(character:GetChildren()) do
		if inst:IsA("Accessory") then
			inst:Destroy()
		end
	end

	local head = character:FindFirstChild("Head")
	if head then
		for _, inst in ipairs(head:GetChildren()) do
			if inst:IsA("Decal") then
				inst:Destroy()
			end
		end
	end
end

local function getWeldPart(obj: Instance): BasePart?
	if not obj then return nil end

	if obj:IsA("BasePart") then
		return obj
	end

	if obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then
		return obj.PrimaryPart
	end

	local found = obj:FindFirstChildWhichIsA("BasePart", true)
	if found then
		if obj:IsA("Model") then
			pcall(function()
				obj.PrimaryPart = found
			end)
		end
		return found
	end

	return nil
end

local function weldTo(part0: BasePart, obj: Instance, c0: CFrame)
	local part1 = getWeldPart(obj)
	if not part1 then
		warn("weldTo: No BasePart found for", obj:GetFullName())
		return
	end

	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.Parent = part1
end

local WingedRaceFunctions = {
	Birkan = function(plr)
		local character = plr.Character
		if not character then return end

		local torso = character:FindFirstChild("Torso")
		if not torso then return end

		local WingsModel = serverstorage.RaceModels.WingedRaces.BirkanWingsModel:Clone()
		WingsModel.Parent = torso

		weldTo(torso, WingsModel:FindFirstChild("BirkanWings") or WingsModel, CFrame.new(0, -0.25, 0.65))
	end,

	Skypeian = function(plr)
		local character = plr.Character
		if not character then return end

		local torso = character:FindFirstChild("Torso")
		if not torso then return end

		local WingsModel = serverstorage.RaceModels.WingedRaces.SkypeianWingsModel:Clone()
		WingsModel.Parent = torso

		weldTo(torso, WingsModel:FindFirstChild("SkypeianWings") or WingsModel, CFrame.new(0, 0, 0.9))
	end,

	Shandian = function(plr)
		local character = plr.Character
		if not character then return end

		local torso = character:FindFirstChild("Torso")
		if not torso then return end

		local WingsModel = serverstorage.RaceModels.WingedRaces.ShandianWingsModel:Clone()
		WingsModel.Parent = torso

		weldTo(torso, WingsModel:FindFirstChild("ShandianWings") or WingsModel, CFrame.new(0, 0.325, 0.75))
	end,

	OneAttenna = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		local antenna = serverstorage.RaceModels.WingedRaces.SkypeianAntenna1:Clone()
		antenna.Parent = head

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.RegColors[skinKey]
		local part = getWeldPart(antenna)
		if part and col then part.Color = col end

		weldTo(head, antenna, CFrame.new(0, 0.775, 0))
	end,

	TwoAttenna = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		local antenna = serverstorage.RaceModels.WingedRaces.SkypeianAntenna2:Clone()
		antenna.Parent = head

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.RegColors[skinKey]
		local part = getWeldPart(antenna)
		if part and col then part.Color = col end

		weldTo(head, antenna, CFrame.new(0, 0.775, 0))
	end,
}

local FishmanRaceFunctions = {
	Shark = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local torso = character:FindFirstChild("Torso")
		local leftArm = character:FindFirstChild("Left Arm")
		local rightArm = character:FindFirstChild("Right Arm")
		if not (torso and leftArm and rightArm) then return end

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.FishmanColors[skinKey]

		local sharkFolder = serverstorage.RaceModels.Fishman.SharkFishmanModel

		local backFin = sharkFolder:FindFirstChild("Back Fin 1"):Clone()
		local leftFin = sharkFolder:FindFirstChild("Arm Fin Left"):Clone()
		local rightFin = sharkFolder:FindFirstChild("Arm Fin Right"):Clone()

		backFin.Parent = torso
		leftFin.Parent = leftArm
		rightFin.Parent = rightArm

		if col then
			if backFin:IsA("BasePart") then backFin.Color = col end
			if leftFin:IsA("BasePart") then leftFin.Color = col end
			if rightFin:IsA("BasePart") then rightFin.Color = col end
		end

		weldTo(torso, backFin, CFrame.new(0, -0.1, 0.55))
		weldTo(leftArm, leftFin, CFrame.new(-0.75, 0.1, 0) * CFrame.Angles(0, math.rad(-180), 0))
		weldTo(rightArm, rightFin, CFrame.new(0.75, 0.1, 0))
	end,

	SawNose = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.FishmanColors[skinKey]

		local nose = serverstorage.RaceModels.Fishman.Sawnose:FindFirstChild("ArlongNose"):Clone()
		nose.Parent = head

		if nose:IsA("BasePart") and col then
			nose.Color = col
		end

		weldTo(head, nose, CFrame.new(0, 0, -1.05))
	end,

	LongMouth = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.FishmanColors[skinKey]

		local mouth = serverstorage.RaceModels.Fishman.LongMouth:FindFirstChild("OctopusMouth"):Clone()
		mouth.Parent = head

		if mouth:IsA("BasePart") and col then
			mouth.Color = col
		end

		weldTo(head, mouth, CFrame.new(0, -0.2, -0.79))
	end,

	CroakerFish = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.FishmanColors[skinKey]

		local fins = serverstorage.RaceModels.Fishman.Croaker:FindFirstChild("HeadFins"):Clone()
		fins.Parent = head

		if fins:IsA("BasePart") and col then
			fins.Color = col
		end

		weldTo(head, fins, CFrame.new(0, 0.45, 0))
	end,

	GillHandler = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		local torso = character:FindFirstChild("Torso")
		if not (head and torso) then return end

		local tertiary = raceData.Tertiary
		local skinKey = raceData.SkinColor
		local col = ColorAppearances.FishmanColors[skinKey]

		local gillFolder = serverstorage.RaceModels.Fishman.GillTypes

		if tertiary == "TorsoGill" then
			torso.Transparency = 1

			local torsoGills = gillFolder:FindFirstChild("FishmanTorso1"):Clone()
			torsoGills.Parent = torso
			if torsoGills:IsA("BasePart") and col then torsoGills.Color = col end

			weldTo(torso, torsoGills, CFrame.new(0, 0, 0))

		elseif tertiary == "FaceGill" then
			local faceGills = gillFolder:FindFirstChild("FaceGills1"):Clone()
			local actualgills = faceGills.FaceGillsModel1
			faceGills:ScaleTo(raceData.Scale)
			faceGills.Parent = head
			if faceGills:IsA("BasePart") and col then faceGills.Color = col end

			weldTo(head, actualgills, CFrame.new(0, -0.175, -0.325))
		end
	end,
}

local GiantFunctions = {
	Ogre = function(plr, raceData)
		local character = plr.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		local torso = character:FindFirstChild("Torso")
		if not (head and torso) then return end

		local oni = serverstorage.RaceModels.Giant.Oni:FindFirstChild("OgreHorns1")
		if not oni then
			warn("GiantFunctions.Ogre: Missing OgreHorns1 in ServerStorage.RaceModels.Giant.Oni")
			return
		end


		local hornObj = oni:Clone()
		hornObj:ScaleTo(raceData.Scale)
		local HornModel = hornObj.OgreHornsModel1
		hornObj.Parent = head

		local skinKey = raceData.SkinColor
		local col = ColorAppearances.RegColors[skinKey]
		local hornPart = getWeldPart(HornModel)
		if hornPart and col then
			hornPart.Color = Color3.fromRGB(0, 0, 0)
		end

		weldTo(torso, HornModel, CFrame.new(0, 0.56, -0.233) * CFrame.Angles(0, math.rad(180), 0))
	end,
}

function RaceHandler:RollRace(plr): DataTemplateTypes.tRaceComponent

	
	local raceData: DataTemplateTypes.tRaceComponent = {}

	local rng = Random.new(os.clock() * 1e6 + plr.UserId)

	local function weightedPick(options)
		if not options or #options == 0 then
			warn("Not Options for sum reason")
			return
		end
		local total = 0
		for _, opt in ipairs(options) do
			total += opt.Weight
		end
		if total <= 0 then
			return nil
		end

		local roll = rng:NextNumber(0, total)
		local acc = 0
		for _, opt in ipairs(options) do
			acc += opt.Weight
			if roll <= acc then
				return opt.Name
			end
		end
		return options[#options].Name
	end

	local function randomKeyFromDict(dict)
		local keys = {}
		for k, _ in pairs(dict) do
			table.insert(keys, k)
		end
		if #keys == 0 then
			return nil
		end
		return keys[rng:NextInteger(1, #keys)]
	end

	-- MAIN RACE
	local mainRace = weightedPick({
		{Name = "Human",     Weight = 50},
		{Name = "Fishman",   Weight = 20},
		{Name = "Wingedman", Weight = 20},
		{Name = "Giant",     Weight = 20},
	})

	-- SUB RACE
	local subRace
	if mainRace == "Human" then
		subRace = weightedPick({
			{Name = "Regular",     Weight = 80},
			{Name = "Nefertari",   Weight = 5},
			{Name = "Donquixote",  Weight = 5},
			{Name = "Kouzuki",     Weight = 7},
			{Name = "Riku",        Weight = 5},
			{Name = "Vinsmoke",    Weight = 6},
		})
	elseif mainRace == "Fishman" then
		subRace = weightedPick({
			{Name = "Shark",       Weight = 40},
			{Name = "SawNose",     Weight = 10},
			{Name = "LongMouth",   Weight = 10},
			{Name = "CroakerFish", Weight = 40},
		})
	elseif mainRace == "Wingedman" then
		subRace = weightedPick({
			{Name = "Birkan",    Weight = 20},
			{Name = "Skypeian",  Weight = 60},
			{Name = "Shandian",  Weight = 20},
		})
	elseif mainRace == "Giant" then
		subRace = weightedPick({
			{Name = "Regular", Weight = 80},
			{Name = "Ogre",    Weight = 20},
		})
	end

	local MiddleName = weightedPick({
		{Name = "None", Weight = 99},
		{Name = "D.",   Weight = .5},
		{Name = "M.",   Weight = .05},
		{Name = "A.",   Weight = .2},
		{Name = "I.",   Weight = .15},
		{Name = "T.",   Weight = .1}
	})

	local tertiary = ""

	if subRace == "Skypeian" then
		tertiary = weightedPick({
			{Name = "OneAttenna", Weight = 50},
			{Name = "TwoAttenna", Weight = 50},
		})
	elseif mainRace == "Fishman" then
		tertiary = weightedPick({
			{Name = "FaceGill",  Weight = 50},
			{Name = "TorsoGill", Weight = 50},
		})
	end

	local skinColorKey
	local HairColorKey
	if mainRace == "Fishman" then
		skinColorKey = randomKeyFromDict(ColorAppearances.FishmanColors)
		HairColorKey = randomKeyFromDict(ColorAppearances.FishmanColors)
	else
		skinColorKey = randomKeyFromDict(ColorAppearances.RegColors)
	end

	local scale = 1
	if mainRace == "Giant" then
		scale = 1.4
	elseif mainRace == "Fishman" or subRace == "Birkan" then
		scale = 1.1
	end

	-- Save all race data at once using Set
	raceData.Main = mainRace or "Human"
	raceData.Sub = subRace or "Regular"
	raceData.Tertiary = tertiary or ""
	raceData.SkinColor = skinColorKey or "PastelBrown"
	--raceData.SkinColor = HairColorKey or "ReddishBrown"
	raceData.Scale = scale
	raceData.Clan = MiddleName
	
	--print(raceData)
	return raceData	
end

function RaceHandler:LoadRaceAppearance(plr, playerStatusData: DataTemplateTypes.tPlayerStatusData)
	--print("Hello I just entered the module")
	--print(PlayerDataHandler:Get(plr, "PlayerStatus"))

	--local ok, raceData = pcall(function()
	--	return PlayerDataHandler:Get(plr, "PlayerStatus").Race
	--end)
	--if not ok or not raceData then
	--	warn("LoadRaceAppearance - No race data for", plr)
	--	return
	--end
	
	
	
	local raceData = playerStatusData.Race
	local MainRaceInfo = raceData.Main
	local SubRaceInfo = raceData.Sub
	local SkinColorInfo = raceData.SkinColor
	local TertiaryInfo = raceData.Tertiary
	local ScaleInfo = raceData.Scale
	
	--print(raceData)


	local character = plr.Character
	character.Torso.CanCollide = false
	if not character or not character.Parent then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("Torso")
	local la = character:FindFirstChild("Left Arm")
	local ra = character:FindFirstChild("Right Arm")
	local ll = character:FindFirstChild("Left Leg")
	local rl = character:FindFirstChild("Right Leg")
	if not (head and torso and la and ra and ll and rl) then return end

	----------------------------------------------------------------
	-- CLEANUP (remove previous race cosmetics + reset body changes)
	----------------------------------------------------------------
	do
		torso.Transparency = 0

		local oldFolder = character:FindFirstChild("RaceCosmetics")
		if oldFolder then
			oldFolder:Destroy()
		end
	end

	local cosmeticsFolder = Instance.new("Folder")
	cosmeticsFolder.Name = "RaceCosmetics"
	cosmeticsFolder.Parent = character

	local beforeSet = {}
	for _, inst in ipairs(character:GetDescendants()) do
		beforeSet[inst] = true
	end
	

	----------------------------------------------------------------
	-- 1) Apply skin color to base R6 parts
	----------------------------------------------------------------
	do
		local colorTable = (MainRaceInfo == "Fishman") and ColorAppearances.FishmanColors or ColorAppearances.RegColors
		local c3 = colorTable[SkinColorInfo]

		if c3 then
			task.wait(.3)
			local bc = character:FindFirstChild("Body Colors")
			--print(bc)
			if not bc then
				bc = Instance.new("BodyColors")
				--print("I made a body colors")
				bc.Parent = character
			end

			--print("doing da colors")
			local brick = BrickColor.new(c3)
			--print(brick.Color)
			bc.HeadColor3 = brick.Color
			bc.TorsoColor3 = brick.Color
			bc.LeftArmColor3 = brick.Color
			bc.RightArmColor3 = brick.Color
			bc.LeftLegColor3 = brick.Color
			bc.RightLegColor3 = brick.Color
			--print("setdacolors")

			character.Head.Color = brick.Color
			character.Torso.Color = brick.Color
			character["Left Arm"].Color = brick.Color
			character["Right Arm"].Color = brick.Color
			character["Left Leg"].Color = brick.Color
			character["Right Leg"].Color = brick.Color

			for _, part in ipairs({head, torso, la, ra, ll, rl}) do
				if part and part:IsA("BasePart") then
					part.Color = c3
				end
			end
		else
			warn("LoadRaceAppearance: No Color3 found for SkinColorInfo:", SkinColorInfo, "MainRaceInfo:", MainRaceInfo)
		end
	end

	----------------------------------------------------------------
	-- 3) Apply cosmetics based on race/sub/tertiary
	----------------------------------------------------------------
	local function safeCall(fn, label)
		if not fn then return end
		local ok, err = pcall(fn, plr, raceData)
		if not ok then
			warn(`Race cosmetic error ({label}): {err}`)
		end
	end

	if MainRaceInfo == "Wingedman" then
		safeCall(WingedRaceFunctions[SubRaceInfo], "Winged:" .. tostring(SubRaceInfo))

		if SubRaceInfo == "Skypeian" and TertiaryInfo and TertiaryInfo ~= "" then
			safeCall(WingedRaceFunctions[TertiaryInfo], "WingedTertiary:" .. tostring(TertiaryInfo))
		end

	elseif MainRaceInfo == "Fishman" then
		safeCall(FishmanRaceFunctions[SubRaceInfo], "Fishman:" .. tostring(SubRaceInfo))

		if TertiaryInfo and TertiaryInfo ~= "" then
			safeCall(FishmanRaceFunctions.GillHandler, "FishmanGillHandler")
		end

	elseif MainRaceInfo == "Giant" then
		if SubRaceInfo == "Ogre" then
			safeCall(GiantFunctions.Ogre, "Giant:Ogre")
		end
	end

	----------------------------------------------------------------
	-- 2) Apply R6 scaling once
	----------------------------------------------------------------
	do
		task.wait(1)
		RemoveRobloxDefaultAppearance(character)
		if ScaleInfo ~= 1 then
			local scaleTag = character:FindFirstChild("RaceScaleApplied")
			if not scaleTag then
				scaleTag = Instance.new("NumberValue")
				scaleTag.Name = "RaceScaleApplied"
				scaleTag.Value = 1
				scaleTag.Parent = character
			end

			if scaleTag.Value ~= ScaleInfo then
				character:ScaleTo(ScaleInfo)
				scaleTag.Value = ScaleInfo
			end
		end
	end

	----------------------------------------------------------------
	-- 4) Collect new instances into RaceCosmetics folder
	----------------------------------------------------------------
	do
		local function isCoreRigPart(inst)
			return inst == head or inst == torso or inst == la or inst == ra or inst == ll or inst == rl
		end

		local function topNewContainer(inst)
			local cur = inst
			while cur and cur.Parent and cur.Parent ~= character do
				if isCoreRigPart(cur) or cur:IsA("Humanoid") then
					return nil
				end
				cur = cur.Parent
			end
			if not cur then return nil end
			if isCoreRigPart(cur) or cur:IsA("Humanoid") then return nil end
			if cur == cosmeticsFolder then return nil end
			return cur
		end

		local moved = {}
		for _, inst in ipairs(character:GetDescendants()) do
			if not beforeSet[inst] then
				local container = topNewContainer(inst)
				if container and not moved[container] then
					moved[container] = true
					container.Parent = cosmeticsFolder
				end
			end
		end
	end
	task.wait(.5)

	--facehandler:LoadHead(plr, playerStatusData)
end

return RaceHandler