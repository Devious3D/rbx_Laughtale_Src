-- HitboxModule: Place in ServerScriptService.Modules
-- Handles per-frame hitbox detection for attacks using HitboxInfo tables

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local HitboxModule = {}
HitboxModule.Visible = false

function HitboxModule:RunHitDetection(attacker, hitboxInfo, duration, onHit)
	local character = attacker.Character
	if not character then return nil end

	local alreadyHit = {}
	local startTime = os.clock()

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {character}

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if os.clock() - startTime >= duration then
			connection:Disconnect()
			return
		end

		-- Loop through each hitbox entry defined in HitboxInfo
		for partName, info in pairs(hitboxInfo) do
			-- Find the referenced part (body part or weapon mesh, recursive search)
			local part = character:FindFirstChild(partName, true)
			if not part or not part:IsA("BasePart") then continue end

			-- Build hitbox CFrame relative to the part
			local offset = info.HitboxPosition or Vector3.zero
			local orient = info.HitboxOrientation or Vector3.zero
			local size = info.HitboxSize or part.Size

			local hitboxCF = part.CFrame
				* CFrame.new(offset)
				* CFrame.Angles(
					math.rad(orient.X),
					math.rad(orient.Y),
					math.rad(orient.Z)
				)

			-- Visualize hitbox if enabled
			if HitboxModule.Visible then
				local visual = Instance.new("Part")
				visual.Name = "HitboxVisual"
				visual.Size = size
				visual.CFrame = hitboxCF
				visual.Anchored = true
				visual.CanCollide = false
				visual.CanQuery = false
				visual.CanTouch = false
				visual.Transparency = 0.6
				visual.Color = Color3.fromRGB(255, 0, 0)
				visual.Material = Enum.Material.Neon
				visual.Parent = workspace
				Debris:AddItem(visual, 0.5)
			end

			-- Spatial query at the hitbox location
			local results = workspace:GetPartBoundsInBox(hitboxCF, size, overlapParams)
			for _, hitPart in ipairs(results) do
				local hitChar = hitPart.Parent
				if not hitChar then continue end

				local hitHumanoid = hitChar:FindFirstChildOfClass("Humanoid")
				if not hitHumanoid then continue end

				-- Don't hit yourself
				if hitChar == character then continue end

				-- Only hit each character once per attack regardless of how many hitboxes overlap
				if not alreadyHit[hitChar] then
					alreadyHit[hitChar] = true
					local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
					onHit(hitPlayer, hitChar, hitHumanoid)
				end
				
			end
		end
	end)

	return connection
end

return HitboxModule