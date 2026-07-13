local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local GameRemotes = ReplicatedStorage:WaitForChild("Remotes")
local RunService = game:GetService("RunService")


local EventHandler = {}

local function NightLights(toggle)
	local NightLights = Color3.fromRGB(213, 115, 61)
	local DayLights = Color3.fromRGB(103, 114, 127)
	local FadeTime = 5

	if toggle == true then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and v.Name == "houseWindowPart" then
				local meh = math.random(1, 2)
				if meh == 2 then
					v.Material = Enum.Material.Neon
					v.Color = NightLights

					local windowlight = v:FindFirstChild("windowlight")
					if not windowlight then
						windowlight = Instance.new("SpotLight")
						windowlight.Name = "windowlight"
						windowlight.Color = NightLights
						windowlight.Brightness = 0 
						windowlight.Range = 18
						windowlight.Angle = 90
						windowlight.Face = Enum.NormalId.Front
						windowlight.Parent = v
					end

					TweenService:Create(
						windowlight,
						TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Brightness = 10 }
					):Play()
				end
			end
		end
	elseif toggle == false then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and v.Name == "houseWindowPart" then
				v.Material = Enum.Material.Neon
				v.Color = DayLights

				local windowlight = v:FindFirstChild("windowlight")
				if windowlight then
					local tween = TweenService:Create(
						windowlight,
						TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Brightness = 0 }
					)

					tween.Completed:Once(function()
						windowlight:Destroy()
					end)

					tween:Play()
				end
			end
		end
	end


end

function EventHandler:NightEvents(toggle, location)
	if toggle == true then
		NightLights(true)
	elseif toggle == false then
		NightLights(false)
	end
end

return EventHandler
