-- LocalScript: Place in StarterPlayerScripts
-- Movement controller using StatesHandler and PlayerDataHandler

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")
local root = char:WaitForChild("HumanoidRootPart")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StatesRemoteFunction")

----------------------------------------------------------------
-- ANIMATIONS
----------------------------------------------------------------
local animFolder = ReplicatedStorage:WaitForChild("Anims"):WaitForChild("Movement")

local dashAnims = {}
local sj1track, sj2track
local hj1track, hj2track
local crouchtrack, crouchlooptrack, crouchwalktrack
local slidetrack, runtrack

local function loadAnimations()
	dashAnims = {
		animator:LoadAnimation(animFolder:WaitForChild("FrontDash")),
		animator:LoadAnimation(animFolder:WaitForChild("BackDash")),
		animator:LoadAnimation(animFolder:WaitForChild("LeftDash")),
		animator:LoadAnimation(animFolder:WaitForChild("RightDash")),
	}
	sj1track = animator:LoadAnimation(animFolder:WaitForChild("SlideJump1"))
	sj2track = animator:LoadAnimation(animFolder:WaitForChild("SlideJump2"))
	hj1track = animator:LoadAnimation(animFolder:WaitForChild("HJ1"))
	hj2track = animator:LoadAnimation(animFolder:WaitForChild("HJ2"))
	crouchtrack = animator:LoadAnimation(animFolder:WaitForChild("Crouch"))
	crouchlooptrack = animator:LoadAnimation(animFolder:WaitForChild("CrouchLoop"))
	crouchwalktrack = animator:LoadAnimation(animFolder:WaitForChild("CrouchWalk"))
	slidetrack = animator:LoadAnimation(animFolder:WaitForChild("Slide"))
	runtrack = animator:LoadAnimation(animFolder:WaitForChild("Run"))
end

loadAnimations()

----------------------------------------------------------------
-- RAYCAST PARAMS
----------------------------------------------------------------
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {char}

----------------------------------------------------------------
-- KEYCODES
----------------------------------------------------------------
local W = Enum.KeyCode.W
local A = Enum.KeyCode.A
local S = Enum.KeyCode.S
local D = Enum.KeyCode.D

----------------------------------------------------------------
-- LOCAL STATE
----------------------------------------------------------------
local cachedStates = nil
local crouching = false
local sliding = nil -- RBXScriptConnection when active
local run = false
local lastw = nil
local time1 = nil
local stop = nil
local speed = 0
local decel = 40 / 3
local sprintAttributeConn = nil


--- Sprint attribute listener
local function disconnectSprintAttributeListener()
	if sprintAttributeConn then
		sprintAttributeConn:Disconnect()
		sprintAttributeConn = nil
	end
end

-- Reconnect on respawn
player.CharacterAdded:Connect(function(newChar)
	char = newChar
	hum = char:WaitForChild("Humanoid")
	animator = hum:WaitForChild("Animator")
	root = char:WaitForChild("HumanoidRootPart")

	-- Reload animations for new Animator
	loadAnimations()

	-- Update raycast filter for new character
	params.FilterDescendantsInstances = {char}

	-- Reset state
	cachedStates = nil
	crouching = false
	sliding = nil
	run = false
	lastw = nil
	time1 = nil
	stop = nil
	disconnectSprintAttributeListener()
end)

----------------------------------------------------------------
-- HELPER: State caching (avoids InvokeServer every frame)
----------------------------------------------------------------
local function getStates()
	cachedStates = remote:InvokeServer("get")
	return cachedStates
end

local function requestStateChange(key, value)
	local success = remote:InvokeServer("set", key, value)
	if success and cachedStates then
		cachedStates[key] = value
	end
	return success
end

local function canPerform(action)
	return remote:InvokeServer("canperform", action)
end

local function getData(key)
	return remote:InvokeServer("getdata", key)
end

----------------------------------------------------------------
-- HELPER: State checks using cached states
----------------------------------------------------------------
local function isStunned()
	if not cachedStates then return true end
	local ps = cachedStates.PrimaryState
	return ps == "TrueStunned" or ps == "SoftStunned" or ps == "BlockBroken"
end

local function isAttacking()
	return cachedStates and cachedStates.PrimaryState == "Attacking"
end

local function isBlocking()
	return cachedStates and cachedStates.PrimaryState == "Blocking"
end

local function isBusy()
	return isStunned() or isAttacking() or isBlocking()
end

local function mobilityIs(state)
	return cachedStates and cachedStates.MobilityState == state
end

----------------------------------------------------------------
-- HELPER: Load appropriate run animation based on equipped state
----------------------------------------------------------------
local function loadSprintAnimation()
	local sprintAnimId = char:GetAttribute("EquippedSprintAnim")
	if sprintAnimId and sprintAnimId ~= "" then
		local animObj = Instance.new("Animation")
		animObj.AnimationId = sprintAnimId
		return animator:LoadAnimation(animObj)
	else
		return animator:LoadAnimation(animFolder:WaitForChild("Run"))
	end
end

local function connectSprintAttributeListener()
	-- Disconnect old listener
	if sprintAttributeConn then
		sprintAttributeConn:Disconnect()
		sprintAttributeConn = nil
	end

	-- Listen for equip/unequip while running to swap run animation
	sprintAttributeConn = char:GetAttributeChangedSignal("EquippedSprintAnim"):Connect(function()
		if not run then return end
		if runtrack and runtrack.IsPlaying then
			runtrack:Stop()
		end
		runtrack = loadSprintAnimation()
		runtrack:Play()
	end)
end

----------------------------------------------------------------
-- HELPER: Get dash animation index based on movement keys
----------------------------------------------------------------
local function getDashAnimIndex()
	if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		return 1 -- default forward when not in shiftlock
	end

	local z = 0
	local x = 0
	if UIS:IsKeyDown(W) then z -= 1 end
	if UIS:IsKeyDown(S) then z += 1 end
	if UIS:IsKeyDown(A) then x -= 1 end
	if UIS:IsKeyDown(D) then x += 1 end

	if z <= -1 then return 1 end  -- forward (W takes priority)
	if z >= 1 then return 2 end   -- backward
	if x <= -1 then return 3 end  -- left
	if x >= 1 then return 4 end   -- right

	return 1 -- default forward
end

----------------------------------------------------------------
-- HIGH JUMP
----------------------------------------------------------------
local function performHighJump(chargeTime, rootpart)
	hj1track:Stop()
	hj2track:Play()
	task.wait(0.3)

	local at = Instance.new("Attachment")
	at.Parent = rootpart

	local v = Instance.new("LinearVelocity")
	v.Attachment0 = at
	v.MaxForce = math.huge
	v.VectorVelocity = rootpart.CFrame.UpVector * (80 + chargeTime * 14)
	v.Parent = root

	hum.WalkSpeed = 14
	hum.JumpPower = 40

	game.Debris:AddItem(v, 0.2)
	game.Debris:AddItem(at, 0.2)
end

----------------------------------------------------------------
-- SLIDE CLEANUP
----------------------------------------------------------------
local function cleanupSlide()
	if sliding and typeof(sliding) == "RBXScriptConnection" then
		sliding:Disconnect()
	end
	sliding = nil
	slidetrack:Stop()
	hum.AutoRotate = true
	hum.JumpPower = 50

	if root:FindFirstChild("SlideVelocity") then
		root.SlideVelocity:Destroy()
	end
	if root:FindFirstChild("SlideAngularVelocity") then
		root.SlideAngularVelocity:Destroy()
	end

	requestStateChange("MobilityState", "Idle")
end

----------------------------------------------------------------
-- CROUCH ANIMATION LOOP (RenderStepped)
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not crouching then return end
	if not cachedStates or cachedStates.MobilityState ~= "Crouching" then
		crouching = false
		crouchlooptrack:Stop()
		crouchwalktrack:Stop()
		return
	end

	if hum.MoveDirection == Vector3.zero then
		if crouchlooptrack.IsPlaying and not crouchwalktrack.IsPlaying then return end
		crouchlooptrack:Play()
		crouchwalktrack:Stop()
	else
		if not crouchlooptrack.IsPlaying and crouchwalktrack.IsPlaying then return end
		crouchwalktrack:Play()
		crouchlooptrack:Stop()
	end
end)

----------------------------------------------------------------
-- INPUT BEGAN
----------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	local states = getStates()
	if not states then return end

	------------------------------------------------------
	-- DASH (Q)
	------------------------------------------------------
	if input.KeyCode == Enum.KeyCode.Q then
		if isBusy() then return end
		if mobilityIs("Crouching") or mobilityIs("Swimming") or mobilityIs("Dashing") then return end
		if not canPerform("Dash") then return end
		if hum.MoveDirection == Vector3.zero then return end

		local at = Instance.new("Attachment")
		at.Parent = root

		local v = Instance.new("LinearVelocity")
		v.Attachment0 = at
		v.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		v.VectorVelocity = hum.MoveDirection * 70
		v.MaxAxesForce = Vector3.new(100000, 0, 100000)
		v.Parent = root

		game.Debris:AddItem(v, 0.2)
		game.Debris:AddItem(at, 0.2)

		requestStateChange("MobilityState", "Dashing")

		local animIndex = getDashAnimIndex()
		dashAnims[animIndex]:Play(0.1, 1, 1.5)

		task.delay(0.3, function()
			if cachedStates and cachedStates.MobilityState == "Dashing" then
				requestStateChange("MobilityState", "Idle")
			end
		end)
	end

	------------------------------------------------------
	-- HIGH JUMP CHARGE (T)
	------------------------------------------------------
	if input.KeyCode == Enum.KeyCode.T then
		if isBusy() then return end
		if mobilityIs("Crouching") then return end

		local humState = hum:GetState()
		local inAir = humState == Enum.HumanoidStateType.Freefall or humState == Enum.HumanoidStateType.Jumping
		if inAir and not mobilityIs("Swimming") then return end

		time1 = os.clock()
		hum.WalkSpeed = 7
		hum.JumpPower = 0
		hj1track:Play()

		stop = task.delay(5, function()
			performHighJump(5, root)
			time1 = nil
			stop = nil
		end)
	end

	------------------------------------------------------
	-- SLIDE JUMP (Space while sliding)
	------------------------------------------------------
	if input.KeyCode == Enum.KeyCode.Space then
		if mobilityIs("Sliding") and sliding then
			local v = root:FindFirstChild("SlideVelocity")
			if not v then return end

			sliding:Disconnect()
			slidetrack:Stop()
			sj1track:Play()
			hum.AutoRotate = true

			if root:FindFirstChild("SlideAngularVelocity") then
				root.SlideAngularVelocity:Destroy()
			end

			local t = os.clock()
			local runConn
			local u = 0
			local played = false
			v.MaxAxesForce = Vector3.new(100000, 100000, 100000)

			runConn = RunService.Heartbeat:Connect(function()
				local look = root.CFrame.LookVector
				root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))

				if os.clock() - t <= 0.5 then
					local n = speed + 20
					v.VectorVelocity = (root.CFrame.LookVector + root.CFrame.UpVector).Unit * n - Vector3.new(0, u * n / 30, 0)

					if v.VectorVelocity.Y <= 0 and not played then
						played = true
						sj1track:Stop()
						sj2track:Play()
					end
					u += 1
				else
					sj2track:Stop()
					hum.JumpPower = 50
					v:Destroy()
					runConn:Disconnect()
					requestStateChange("MobilityState", "Idle")
				end
			end)
		end
	end

	------------------------------------------------------
	-- CROUCH / SLIDE (LeftControl)
	------------------------------------------------------
	if input.KeyCode == Enum.KeyCode.LeftControl then
		if mobilityIs("Swimming") then return end

		-- Toggle crouch off
		if crouching then
			crouching = false
			crouchtrack:Stop()
			crouchlooptrack:Stop()
			crouchwalktrack:Stop()
			hum.WalkSpeed = 15
			hum.JumpPower = 40
			requestStateChange("MobilityState", "Idle")
			return
		end

		local humState = hum:GetState()
		local inAir = humState == Enum.HumanoidStateType.Jumping or humState == Enum.HumanoidStateType.Freefall
		if inAir then return end

		-- SLIDE (if running)
		if mobilityIs("Running") then
			hum.WalkSpeed = 15
			hum.JumpPower = 0
			hum.AutoRotate = false
			runtrack:Stop()
			slidetrack:Play()
			run = false
			disconnectSprintAttributeListener()

			requestStateChange("MobilityState", "Sliding")

			local angVel = Instance.new("AngularVelocity")
			angVel.Name = "SlideAngularVelocity"
			angVel.Attachment0 = root.RootAttachment
			angVel.AngularVelocity = Vector3.zero
			angVel.MaxTorque = 0
			angVel.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
			angVel.Parent = root

			local linVel = Instance.new("LinearVelocity")
			linVel.Name = "SlideVelocity"
			linVel.Attachment0 = root.RootAttachment
			linVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
			linVel.Parent = root

			speed = 30
			local c = 1

			sliding = RunService.Heartbeat:Connect(function(dt)
				local c1 = hum:GetState() == Enum.HumanoidStateType.Jumping
				local c2 = hum:GetState() == Enum.HumanoidStateType.Freefall
				if not sliding or c1 or c2 then return end

				local r1 = workspace:Raycast(root.Position, -Vector3.yAxis * 7, params)
				if not r1 then return end

				local scale = math.deg(r1.Normal:Angle(Vector3.yAxis))
				linVel.MaxAxesForce = Vector3.new(100000, 0, 100000)
				angVel.MaxTorque = math.huge

				if scale == 0 then
					-- Flat ground: decelerate
					local look = root.CFrame.LookVector
					linVel.VectorVelocity = Vector3.new(look.X, 0, look.Z) * speed

					if speed - decel * dt <= 0 then
						cleanupSlide()
					else
						speed -= decel * dt
					end
				else
					-- Slope
					local ns
					if math.deg(r1.Normal:Angle(root.CFrame.LookVector)) > 100 then
						-- Going uphill
						ns = 30 - 20 * math.sin(math.rad(scale)) - decel * dt * c
						if ns <= 0 then
							cleanupSlide()
							return
						end
					else
						-- Going downhill
						ns = 30 + 20 * math.sin(math.rad(scale))
					end

					linVel.VectorVelocity = root.CFrame.LookVector * ns
					speed = ns
				end

				c += 1
			end)

			-- CROUCH (if not running)
		else
			if isBusy() then return end

			crouching = true
			hum.WalkSpeed = 7
			hum.JumpPower = 0
			crouchtrack:Play()

			requestStateChange("MobilityState", "Crouching")

			task.delay(crouchtrack.Length, function()
				if not crouching then return end
				crouchlooptrack:Play()
			end)
		end
	end

	------------------------------------------------------
	-- DOUBLE TAP W TO RUN
	------------------------------------------------------
	if input.KeyCode == W then
		if isBusy() or mobilityIs("Crouching") then return end

		if not lastw then
			lastw = os.clock()
		else
			if os.clock() - lastw <= 0.2 then
				if not canPerform("Run") then
					lastw = nil
					return
				end

				run = true

				-- Load sprint animation (checks EquippedSprintAnim attribute from combat script)
				runtrack = loadSprintAnimation()
				runtrack:Play()

				-- Listen for equip/unequip changes while running
				connectSprintAttributeListener()

				requestStateChange("MobilityState", "Running")
				hum.WalkSpeed = 30
			else
				lastw = os.clock()
			end
		end
	end
end)

----------------------------------------------------------------
-- INPUT ENDED
----------------------------------------------------------------
UIS.InputEnded:Connect(function(input, gpe)
	if gpe then return end

	------------------------------------------------------
	-- RELEASE HIGH JUMP (T)
	------------------------------------------------------
	if input.KeyCode == Enum.KeyCode.T then
		if isBusy() then
			if stop then
				task.cancel(stop)
				stop = nil
			end
			time1 = nil
			return
		end

		if time1 then
			local chargeTime = os.clock() - time1
			time1 = nil

			if stop then
				task.cancel(stop)
				stop = nil
			end

			performHighJump(chargeTime, root)
		end

		------------------------------------------------------
		-- STOP RUNNING (release W)
		------------------------------------------------------
	elseif input.KeyCode == W then
		if lastw and run then
			if isBusy() then
				lastw = nil
				run = false
				disconnectSprintAttributeListener()
				return
			end

			runtrack:Stop()
			requestStateChange("MobilityState", "Idle")
			hum.WalkSpeed = 15
			run = false
			lastw = nil
			disconnectSprintAttributeListener()
		end
	end
end)