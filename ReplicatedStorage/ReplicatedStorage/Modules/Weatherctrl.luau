local Weatherctrl = {}
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local RainToggler = RS.Remotes:WaitForChild("RainToggler")

local tweenInfo = TweenInfo.new(1.5)


local function TweenProperties(instance, properties)
	local tween = TS:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end


-- WEATHER TYPES
local WeatherPresets = {

	ClearSkies = {
		Rain = "off",
		Atmosphere = {
			Density = .323,
			Offset = .138,
			Color = Color3.fromRGB(89, 191, 255),
			Decay = Color3.fromRGB(55, 78, 112),
			Glare = 1.5,
			Haze = 1.85,
		},
		Bloom = {
			Intensity = 1,
			Size = 8,
			Threshold = 3
		},
		ColorCorrection = {
			Brightness = 0.05,
			Contrast = 0.1,
			Saturation = 0.2,
			TintColor = Color3.fromRGB(255,255,255)
		},
		SunRays = {
			Intensity = 0.25,
			Spread = 1
		},
		Clouds = {
			Cover = 0.585,
			Density = 0.1,
			Color = Color3.fromRGB(255,255,255)
		},
		DepthOfField = {
			FarIntensity = 0.75,
			FocusDistance = 0.05,
			InFocusRadius = 150,
			NearIntensity = 0.75
		}
	},

	RainyDay = {
		Rain = "on",
		Atmosphere = {
			Density = .538,
			Offset = .246,
			Color = Color3.fromRGB(79,84,97),
			Decay = Color3.fromRGB(34,34,34),
			Glare = 7.08,
			Haze = 2.92
		},
		Bloom = {
			Intensity = 1,
			Size = 0,
			Threshold = .8
		},
		ColorCorrection = {
			Brightness = 0.05,
			Contrast = 0.2,
			Saturation = -0.1,
			TintColor = Color3.fromRGB(175,175,175)
		},
		SunRays = {
			Intensity = 0.1,
			Spread = 1
		},
		Clouds = {
			Cover = 0.677,
			Density = 0.292,
			Color = Color3.fromRGB(36,36,36)
		},
		DepthOfField = {
			FarIntensity = 0.75,
			FocusDistance = 0.05,
			InFocusRadius = 150,
			NearIntensity = 0.75
		}
	},

	HeavyFog = {
		Rain = "off",
		Atmosphere = {
			Density = .708,
			Offset = .569,
			Color = Color3.fromRGB(255,255,255),
			Decay = Color3.fromRGB(230,230,230),
			Glare = 0,
			Haze = 3.23
		},
		Bloom = {
			Intensity = 1,
			Size = 8,
			Threshold = 1.539
		},
		ColorCorrection = {
			Brightness = 0.05,
			Contrast = 0.1,
			Saturation = -0.2,
			TintColor = Color3.fromRGB(255,255,255)
		},
		SunRays = {
			Intensity = 0.25,
			Spread = 1
		},
		Clouds = {
			Cover = 0.831,
			Density = 0.277,
			Color = Color3.fromRGB(255,255,255)
		},
		DepthOfField = {
			FarIntensity = 0.75,
			FocusDistance = 0.05,
			InFocusRadius = 150,
			NearIntensity = 0.75
		}
	},

	ThunderStorm = {
		Rain = "on",
		Atmosphere = {
			Density = .538,
			Offset = .246,
			Color = Color3.fromRGB(79,84,97),
			Decay = Color3.fromRGB(34,34,34),
			Glare = 7.08,
			Haze = 2.92
		},
		Bloom = {
			Intensity = 1,
			Size = 0,
			Threshold = 0.8
		},
		ColorCorrection = {
			Brightness = 0.05,
			Contrast = 0.2,
			Saturation = -0.1,
			TintColor = Color3.fromRGB(175,175,175)
		},
		SunRays = {
			Intensity = 0.25,
			Spread = 1
		},
		Clouds = {
			Cover = 0.677,
			Density = 0.292,
			Color = Color3.fromRGB(36,36,36)
		},
		DepthOfField = {
			FarIntensity = 0.75,
			FocusDistance = 0.05,
			InFocusRadius = 150,
			NearIntensity = 0.75
		}
	}
}



function Weatherctrl:Set(plr: Player, switch: boolean, weatherName: string)

	local preset = WeatherPresets[weatherName]
	if not preset then
		warn("Invalid weather preset:", weatherName)
		return
	end

	if switch == true then

		RainToggler:FireServer(preset.Rain)
		if game.Lighting.ClockTime >= 18 or game.Lighting.ClockTime < 6 then
			preset.Atmosphere.Color = Color3.fromRGB(0,0,0)
			preset.Atmosphere.Decay = Color3.fromRGB(0,0,0)
		end


		local Lighting = game.Lighting
		local Atmosphere = Lighting:FindFirstChild("Atmosphere")
		local Bloom = Lighting:FindFirstChild("Bloom")
		local ColorCorrection = Lighting:FindFirstChild("ColorCorrection")
		local SunRays = Lighting:FindFirstChild("SunRays")
		local Clouds = game.Workspace.Terrain:FindFirstChild("Clouds")
		local DepthOfField = Lighting:FindFirstChild("DepthOfField")


		TweenProperties(Atmosphere, preset.Atmosphere)
		TweenProperties(Bloom, preset.Bloom)
		TweenProperties(ColorCorrection, preset.ColorCorrection)
		TweenProperties(SunRays, preset.SunRays)
		TweenProperties(Clouds, preset.Clouds)
		TweenProperties(DepthOfField, preset.DepthOfField)

	else

		self:Set(plr, true, "ClearSkies")
	end
end


return Weatherctrl
