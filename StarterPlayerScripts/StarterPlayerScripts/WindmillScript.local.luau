local RunService = game:GetService("RunService")


local cachedMills = {}


for _, v in ipairs(workspace:GetDescendants()) do
	if v.Name == "FooshaWIndmill" then
		local windmillsails = v:WaitForChild("Mill",5)
		if windmillsails == nil then
			print(v)
			print(windmillsails:WaitForChild("Mill"))
			print(v:GetDescendants())
		end

		if not cachedMills[windmillsails] then
			cachedMills[windmillsails] = (math.random(1, 2) == 1) and 10 or -10
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	for windmillsails, RotationSpeed in pairs(cachedMills) do
		if windmillsails and windmillsails.Parent then
			local pivot = windmillsails:GetPivot()
			pivot *= CFrame.Angles(0, 0, math.rad(RotationSpeed * dt))
			windmillsails:PivotTo(pivot)
		else

			cachedMills[windmillsails] = nil
		end
	end
end)
