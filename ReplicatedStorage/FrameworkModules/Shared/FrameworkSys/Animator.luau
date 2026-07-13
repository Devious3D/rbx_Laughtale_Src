local Framework = require("../../Framework")
local Services, Modules, Shared

local markerGroupIds: {string} = {}
local tracks: Framework.tAnimatorHandle | {Framework.tAnimatorHandle} = nil

--Client
local character: Model = nil
local characterAnimator: Animator = nil

local module = {}

function module:Start()
	
	local sharedMod = {"Queue"}

	if (Framework:IsClient()) then
		
		Services, Modules, Shared = Framework:Include({
			Services = {"Players"},
			Modules = {},
			Shared = sharedMod
		})
		
		character = Services.Players.LocalPlayer.Character
		characterAnimator = character.Humanoid.Animator
		
		tracks = {}
		tracks["currentTracks"] = {}
		tracks["trackQueueId"] = Shared.Queue:new({})
		tracks["animations"] = {}
		
		--print(tracks)
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


function module:getPlayingAnimation(player: Player, animName: string)
	
end



function module:debug_getTrackHandle()
	return tracks
end


local function getPlayer(playerName: string): Player
	assert(Framework:IsServer() == false, "Context is not server")
	return Services.Players:FindFirstChild(playerName)
end

local function checkForCachedID(player: Player, animName: string)
	if (Framework:IsClient()) then
		if (markerGroupIds[animName] == nil) then markerGroupIds[animName] = Framework:NewConnectionGroup() end
	end
	
	if (Framework:IsServer()) then
		if (markerGroupIds[player.Name][animName] == nil) then markerGroupIds[player.Name][animName] = Framework:NewConnectionGroup() end
	end
end


function module:LoadAnimations(player: Player, Category: string, animationObjects: {Animation}): boolean
		
	if (Framework:IsClient()) then 
		

		tracks["animations"][Category] = {}
							
		for i, v in pairs(animationObjects) do
			if (v.ClassName ~= "Animation") then continue end
			
			if (v.AnimationId == nil) then 
				warn(`{v.Name} has no Animation Id`)	
				continue 
			end
			
			tracks["animations"][Category][v.Name] = characterAnimator:LoadAnimation(v)		
			Framework:Print(`Animation[{Category}]: {v.Name} Loaded`, Framework.ePrintLevel.Warn)
		end		
	end

	if (Framework:IsServer()) then
		
		--local character = getPlayer().Character
		
		--for i, v in pairs(animationObjects) do
		--	if (v.ClassName ~= "Animation") then continue end

		--	if (v.AnimationId == nil) then 
		--		warn(`{v.Name} has no Animation Id`)	
		--		continue 
		--	end

		--	Tracks[player][Category][v.Name] = v.AnimationId
		--	character.Humanoid.Animator:LoadAnimation(v)		

		--	Framework:Print(`Animation[{Category}]: {v.Name} Loaded`, Framework.ePrintLevel.Warn)
		--end
	end
		
	return true
end



function module:Play(player: Player, category: string, animName: string, playData: Framework.tAnimationPlayData)
		
	module:ClearQueue(player)
	
	local track: AnimationTrack = nil
	
	if (Framework:IsClient()) then
		track = tracks.animations[category][animName]
		checkForCachedID(nil, animName)


		if (playData ~= nil) then track:Play(playData.fadeInSpeed, playData.weight, playData.speed) 
		else track:Play() end		
	end


	if (Framework:IsServer()) then

	end	
	
	return
end

function module:Stop(player: Player, animName: string, fadeOutTime: number)
	
	if (Framework:IsClient()) then
		local trackInfo = tracks["currentTracks"][animName]
		if (fadeOutTime ~= nil) then trackInfo.track:Stop(fadeOutTime) else trackInfo.track:Stop() end
	end

	if (Framework:IsServer()) then

	end
	
end

function module:Reset(player: Player, animName: string)
	
	if (Framework:IsClient()) then
		print(tracks["currentTracks"])
		tracks["currentTracks"][animName].track.TimePosition = 0
	end

	if (Framework:IsServer()) then

	end
	
end

function module:AttachToMarker(player: Player, category: string, animName: string, marker: string, func: () -> ())
	
	if (Framework:IsClient()) then	
		checkForCachedID(nil, animName)
		
		const groupId: string = markerGroupIds[animName]
		local track: Framework.tAnimationInfo = tracks["animations"][category][animName]
		
		Framework:NewSignal(groupId, track:GetMarkerReachedSignal(marker):Connect(func))		
	end

	if (Framework:IsServer()) then

	end
	
end

function module:ClearMarkerAttachments(player: Player, animName: string)
	
	if (Framework:IsClient()) then
		checkForCachedID(nil, animName)
		Framework:ClearGroup(markerGroupIds[animName])
	end
	
	if (Framework:IsServer()) then
		
	end
end

function module:Queue(player: Player, category: string, animName: string, playData: Framework.tAnimationPlayData): AnimationTrack
		
	if (Framework:IsClient()) then
		checkForCachedID(nil, animName)
		
		local newQueuedAnimation: Framework.tQueuedAnimation = {
			track = tracks["animations"][category][animName],
			playData = playData
		}
		Shared.Queue:insert(tracks["trackQueueId"], {newQueuedAnimation})
		
		--print(Shared.Queue:get(tracks["trackQueueId"]))\
		return newQueuedAnimation.track
	end


	if (Framework:IsServer()) then

	end
end

function module:ClearQueue(player: Player)
	
	if (Framework:IsClient()) then 
		
		Shared.Queue:getCurrent(tracks["trackQueueId"]).track:Stop(0)
		Shared.Queue:clear(tracks["trackQueueId"]) 
	end
	
	if (Framework:IsServer()) then
		
	end
	
end


function module.Tick(delta)
	
	if (tracks == nil) then return end
	
	if (Framework:IsClient()) then		

		if ( Shared.Queue:size(tracks["trackQueueId"]) > 0 ) then
			
			local queue: Framework.tQueue = Shared.Queue:get(tracks["trackQueueId"])

			if (queue.metadata["freezeQueue"] == true) then return end
			--print(queue.metadata.freezeQueue)

			local nextAnimation: Framework.tQueuedAnimation = Shared.Queue:next(tracks["trackQueueId"])
			nextAnimation.track:Play(
				nextAnimation.playData.fadeInSpeed,
				nextAnimation.playData.weight,
				nextAnimation.playData.speed 
			)

			Framework:NewSignal(markerGroupIds[tostring(nextAnimation.track)], nextAnimation.track.Ended:Connect(function()
				Shared.Queue:setMetadata(queue.id, {})
			end))
			
			queue.metadata.freezeQueue = true
		end


		local currentAnimatorTracks: {AnimationTrack} = characterAnimator:GetPlayingAnimationTracks()
		local formattedAnimations: {AnimationTrack} = {}

		for i, v in pairs(currentAnimatorTracks) do
			if (tracks["currentTracks"][tostring(v)] ~= nil) then continue end

			const trackAsString = tostring(v)
			
			checkForCachedID(nil, trackAsString)

			local newInfo: Framework.tAnimationInfo = {
				track = v,
				markerGroupId = markerGroupIds[trackAsString]
			}

			tracks["currentTracks"][trackAsString] = newInfo

			--Framework:NewSignal(newInfo.markerGroupId, v.Ended:Connect(function()
			--	--print(trackAsString)
				
			--	--print(Framework:FindGroup(newInfo.markerGroupId))
			--	Framework:ClearGroup(newInfo.markerGroupId)
			--end))
		end
		
	end


	if (Framework:IsServer()) then

	end
end


return module