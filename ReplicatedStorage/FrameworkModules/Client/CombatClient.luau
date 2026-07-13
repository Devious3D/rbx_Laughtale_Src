-- ModuleScript: ReplicatedStorage/FrameworkModules/Client/CombatClient
-- Contains ALL combat and movement logic.
-- The LocalScript only handles input and calls into this module.
-- Server → client events arrive via the "CombatSetUp" remote channel.

local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = require(ReplicatedStorage.FrameworkModules.Framework)
local Services, Modules, Shared

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- Keycodes referenced during input checks
---------------------------------------------------------------------------
local W = Enum.KeyCode.W
local A = Enum.KeyCode.A
local S = Enum.KeyCode.S
local D = Enum.KeyCode.D

---------------------------------------------------------------------------
-- Speed / physics constants
---------------------------------------------------------------------------
local DEFAULT_JUMP_POWER = 50
local DEFAULT_WALK_SPEED = 15
local SPRINT_WALK_SPEED  = 30
local CROUCH_WALK_SPEED  = 7
local SLIDE_DECEL        = 40 / 3
local SPEED_KEYS = { "First","Second","Third","Fourth","Fifth","Sixth","Seventh","Eighth","Ninth","Tenth" }

---------------------------------------------------------------------------
-- MODULE
---------------------------------------------------------------------------
local module = {}
module.__index = module

---------------------------------------------------------------------------
-- CHARACTER / ANIMATOR REFERENCES  (refreshed by Init on respawn)
---------------------------------------------------------------------------
local char, hum, animator, root

---------------------------------------------------------------------------
-- COMBAT STATE
---------------------------------------------------------------------------
local combo           = 0
local lastAttackTime  = 0
local attacking       = false
local blocking        = false
local equipped        = false
local blocklocked     = false
local blocklockThread = nil

local styleInfo  = nil
local weaponInfo = nil
local styleName  = ""
local weaponName = ""

-- Animation tracks
local attackAnims      = {}
local blockTrack       = nil
local blockBrokenTrack = nil
local equipTrack       = nil
local idleTrack        = nil
local stunTrack        = nil

-- Block bar GUI
local activeBlockBar   = nil
local blockBarTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("BlockBar")

---------------------------------------------------------------------------
-- MOVEMENT STATE
---------------------------------------------------------------------------
local cachedStates        = nil
local crouching           = false
local sliding             = nil   -- RBXScriptConnection when active
local run                 = false
local lastw               = nil
local time1               = nil   -- high jump charge start
local stop                = nil   -- high jump auto-release task
local slideSpeed          = 0
local sprintAttributeConn = nil

-- Movement animation tracks
local dashAnims        = {}
local sj1track, sj2track
local hj1track, hj2track
local crouchtrack, crouchlooptrack, crouchwalktrack
local slidetrack, runtrack

-- Raycast params (exclude character)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

---------------------------------------------------------------------------
-- REMOTE NAMES
---------------------------------------------------------------------------
local STATES_REMOTE  = "StatesRemoteFunction"
local COMBAT_RF      = "CombatRemoteFunction"
local COMBAT_CHANNEL = "CombatSetUp"   -- Channel for server → client events

---------------------------------------------------------------------------
-- INTERNAL HELPERS: REMOTES
---------------------------------------------------------------------------

local function invokeRemote(name, ...)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name)
	return remote:InvokeServer(...)
end

local DATA_REMOTE = "DataRemoteFunction"

local function statesInvoke(...)
	return invokeRemote(STATES_REMOTE, ...)
end

local function dataInvoke(...)
	return invokeRemote(DATA_REMOTE, ...)
end

local function combatInvoke(...)
	return invokeRemote(COMBAT_RF, ...)
end

---------------------------------------------------------------------------
-- INTERNAL HELPERS: STATE CHECKS
---------------------------------------------------------------------------

local function _getStates()
	cachedStates = statesInvoke("get")
	return cachedStates
end

local function _requestStateChange(key, value)
	local success = statesInvoke("set", key, value)
	if success and cachedStates then
		cachedStates[key] = value
	end
	return success
end

local function _canPerform(action)
	return statesInvoke("canperform", action)
end

local function _isStunned()
	if not cachedStates then return true end
	local ps = cachedStates.PrimaryState
	return ps == "TrueStunned" or ps == "SoftStunned" or ps == "BlockBroken"
end

local function _isAttacking()
	return cachedStates and cachedStates.PrimaryState == "Attacking"
end

local function _isBlocking()
	return cachedStates and cachedStates.PrimaryState == "Blocking"
end

local function _isBusy()
	return _isStunned() or _isAttacking() or _isBlocking()
end

local function _mobilityIs(state)
	return cachedStates and cachedStates.MobilityState == state
end

---------------------------------------------------------------------------
-- INTERNAL HELPERS: JUMP STATE
---------------------------------------------------------------------------

local function _updateJumpState()
	if not hum then return end
	if blocking or attacking or equipped then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		hum.JumpPower = 0
	else
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hum.JumpPower = DEFAULT_JUMP_POWER
	end
end

---------------------------------------------------------------------------
-- INTERNAL HELPERS: ANIMATIONS
---------------------------------------------------------------------------

local function _loadAnimFromId(animId)
	if not animId or animId == "" then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	return animator:LoadAnimation(anim)
end

local function _stopAllAttackAnims()
	for _, track in ipairs(attackAnims) do
		if track and track.IsPlaying then track:Stop() end
	end
end

local function _stopCombatAnims()
	_stopAllAttackAnims()
	if blockTrack       and blockTrack.IsPlaying       then blockTrack:Stop()       end
	if blockBrokenTrack and blockBrokenTrack.IsPlaying then blockBrokenTrack:Stop() end
	if equipTrack       and equipTrack.IsPlaying       then equipTrack:Stop()       end
	if idleTrack        and idleTrack.IsPlaying        then idleTrack:Stop()        end
	if stunTrack        and stunTrack.IsPlaying        then stunTrack:Stop()        end
end

local function _loadMovementAnims()
	local animFolder = ReplicatedStorage:WaitForChild("Anims"):WaitForChild("Movement")
	dashAnims = {
		animator:LoadAnimation(animFolder:WaitForChild("FrontDash")),
		animator:LoadAnimation(animFolder:WaitForChild("BackDash")),
		animator:LoadAnimation(animFolder:WaitForChild("LeftDash")),
		animator:LoadAnimation(animFolder:WaitForChild("RightDash")),
	}
	sj1track        = animator:LoadAnimation(animFolder:WaitForChild("SlideJump1"))
	sj2track        = animator:LoadAnimation(animFolder:WaitForChild("SlideJump2"))
	hj1track        = animator:LoadAnimation(animFolder:WaitForChild("HJ1"))
	hj2track        = animator:LoadAnimation(animFolder:WaitForChild("HJ2"))
	crouchtrack     = animator:LoadAnimation(animFolder:WaitForChild("Crouch"))
	crouchlooptrack = animator:LoadAnimation(animFolder:WaitForChild("CrouchLoop"))
	crouchwalktrack = animator:LoadAnimation(animFolder:WaitForChild("CrouchWalk"))
	slidetrack      = animator:LoadAnimation(animFolder:WaitForChild("Slide"))
	runtrack        = animator:LoadAnimation(animFolder:WaitForChild("Run"))
end

local function _loadSprintAnimation()
	local sprintAnimId = char and char:GetAttribute("EquippedSprintAnim")
	local animFolder   = ReplicatedStorage:WaitForChild("Anims"):WaitForChild("Movement")
	if sprintAnimId and sprintAnimId ~= "" then
		local animObj = Instance.new("Animation")
		animObj.AnimationId = sprintAnimId
		return animator:LoadAnimation(animObj)
	else
		return
			animator:LoadAnimation(animFolder:WaitForChild("Run"))
	end
end

local function _getDashAnimIndex()
	if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then return 1 end
	local z, x = 0, 0
	if UIS:IsKeyDown(W) then z -= 1 end
	if UIS:IsKeyDown(S) then z += 1 end
	if UIS:IsKeyDown(A) then x -= 1 end
	if UIS:IsKeyDown(D) then x += 1 end
	if z <= -1 then return 1 end
	if z >= 1  then return 2 end
	if x <= -1 then return 3 end
	if x >= 1  then return 4 end
	return 1
end

---------------------------------------------------------------------------
-- INTERNAL HELPERS: BLOCK BAR GUI
---------------------------------------------------------------------------

local function _showBlockBar(currentHP, maxHP)
	if activeBlockBar then return end
	local clone = blockBarTemplate:Clone()
	clone.Adornee = player.Character:WaitForChild("Head")
	clone.Parent  = player.PlayerGui
	clone:WaitForChild("Frame"):WaitForChild("background").BackgroundTransparency = 0
	clone:WaitForChild("Frame"):WaitForChild("background"):WaitForChild("bar").BackgroundTransparency = 0
	clone:WaitForChild("ImageLabel").ImageTransparency = 0
	local bar = clone.Frame.background:FindFirstChild("bar")
	if bar then
		bar.Size = UDim2.fromScale(math.clamp(currentHP / maxHP, 0, 1), 1)
	end
	activeBlockBar = clone
end

local function _updateBlockBar(currentHP, maxHP)
	if not activeBlockBar then return end
	local bar = activeBlockBar.Frame.background:FindFirstChild("bar")
	if not bar then return end
	TweenService:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(currentHP / maxHP, 0, 1), 1)
	}):Play()
end

local function _hideBlockBar()
	if activeBlockBar then
		activeBlockBar:Destroy()
		activeBlockBar = nil
	end
end

---------------------------------------------------------------------------
-- INTERNAL: SLIDE CLEANUP
---------------------------------------------------------------------------

local function _cleanupSlide()
	if sliding and typeof(sliding) == "RBXScriptConnection" then
		sliding:Disconnect()
	end
	sliding = nil
	if slidetrack then slidetrack:Stop() end
	hum.AutoRotate = true
	hum.JumpPower  = DEFAULT_JUMP_POWER
	if root:FindFirstChild("SlideVelocity")        then root.SlideVelocity:Destroy()        end
	if root:FindFirstChild("SlideAngularVelocity") then root.SlideAngularVelocity:Destroy() end
	_requestStateChange("MobilityState", "Idle")
end

---------------------------------------------------------------------------
-- INTERNAL: SPRINT ATTRIBUTE LISTENER
---------------------------------------------------------------------------

local function _disconnectSprintAttrListener()
	if sprintAttributeConn then
		sprintAttributeConn:Disconnect()
		sprintAttributeConn = nil
	end
end

local function _connectSprintAttrListener()
	_disconnectSprintAttrListener()
	sprintAttributeConn = char:GetAttributeChangedSignal("EquippedSprintAnim"):Connect(function()
		if not run then return end
		if runtrack and runtrack.IsPlaying then runtrack:Stop() end
		runtrack = _loadSprintAnimation()
		runtrack:Play()
	end)
end

---------------------------------------------------------------------------
-- INTERNAL: REFRESH COMBAT INFO
-- Reads style/weapon from the new EquippedItems data layout.
---------------------------------------------------------------------------

local function _refreshCombatInfo()
	local playerequipdata = dataInvoke("EquippedItems")
	if not playerequipdata then return end

	local equippedItems = playerequipdata
	if not equippedItems then return end

	styleName  = (equippedItems.PrimaryStyle ~= "" and equippedItems.PrimaryStyle) or "DefaultFist"
	weaponName = equippedItems.BindedWeapon or ""

	styleInfo  = combatInvoke("get", "StyleInfo", styleName)
	if weaponName ~= " " and weaponName ~= "" then
		weaponInfo = combatInvoke("get", "WeaponInfo", weaponName)
	else
		weaponInfo = nil
	end

	if not styleInfo then
		warn("CombatClient: No style info for", styleName)
		return
	end

	-- Load attack animations
	attackAnims = {}
	for i = 1, (styleInfo.AttackAmount or 4) do
		attackAnims[i] = _loadAnimFromId(styleInfo.AnimationIDs["Anim" .. i])
	end

	-- Block animation (weapon override or style default)
	local blockAnimId = styleInfo.AnimationIDs.Block
	if weaponInfo and weaponInfo.AnimationOverrides and weaponInfo.AnimationOverrides.Block then
		local ov = weaponInfo.AnimationOverrides.Block
		if ov and ov ~= "idk" and ov ~= "" then blockAnimId = ov end
	end
	blockTrack       = _loadAnimFromId(blockAnimId)
	blockBrokenTrack = _loadAnimFromId(styleInfo.AnimationIDs.BlockBroken)
	equipTrack       = _loadAnimFromId(styleInfo.AnimationIDs.Equip)
	idleTrack        = _loadAnimFromId(styleInfo.AnimationIDs.Idle)

	combo          = 0
	lastAttackTime = 0
end

---------------------------------------------------------------------------
-- INTERNAL: HIGH JUMP PERFORM
---------------------------------------------------------------------------

local function _performHighJump(chargeTime)
	hj1track:Stop()
	hj2track:Play()
	task.wait(0.3)

	local at = Instance.new("Attachment")
	at.Parent = root

	local v = Instance.new("LinearVelocity")
	v.Attachment0    = at
	v.MaxForce       = math.huge
	v.VectorVelocity = root.CFrame.UpVector * (80 + chargeTime * 14)
	v.Parent         = root

	hum.WalkSpeed = 14
	hum.JumpPower = 40

	game.Debris:AddItem(v,  0.2)
	game.Debris:AddItem(at, 0.2)
end

---------------------------------------------------------------------------
-- CHANNEL: SERVER EVENT HANDLER
-- The CombatSetUp channel delivers: player (target), eventType, ...args
-- On the client side the first arg is eventType since player is implicit.
---------------------------------------------------------------------------

local function _onCombatChannelEvent(eventType, ...)
	if eventType == "BlockHPUpdate" then
		local currentHP, maxHP = ...
		_updateBlockBar(currentHP, maxHP)

	elseif eventType == "BlockBroken" then
		blocking    = false
		blocklocked = false
		if blocklockThread then task.cancel(blocklockThread) blocklockThread = nil end
		if blockTrack and blockTrack.IsPlaying then blockTrack:Stop() end
		if blockBrokenTrack then blockBrokenTrack:Play() end
		_updateBlockBar(0, 1)
		task.delay(1, _hideBlockBar)

	elseif eventType == "BlockBrokenRecovery" then
		if blockBrokenTrack and blockBrokenTrack.IsPlaying then blockBrokenTrack:Stop() end

	elseif eventType == "Blocklock" then
		local duration = ...
		blocklocked = true
		if blocklockThread then task.cancel(blocklockThread) end
		blocklockThread = task.delay(duration, function()
			blocklocked     = false
			blocklockThread = nil
			if not UIS:IsKeyDown(Enum.KeyCode.F) and blocking then
				module:EndBlock()
			end
		end)

	elseif eventType == "Stunned" then
		local sType, duration, animId = ...
		_stopCombatAnims()
		blocking    = false
		attacking   = false
		blocklocked = false
		_hideBlockBar()
		_updateJumpState()
		if animId and animId ~= "" and animId ~= "idk" then
			stunTrack = _loadAnimFromId(animId)
			if stunTrack then stunTrack:Play() end
		end

	elseif eventType == "StunRecovery" then
		if stunTrack and stunTrack.IsPlaying then stunTrack:Stop() end
		stunTrack = nil

	elseif eventType == "Hit" then
		-- Add hit effects here if needed

	elseif eventType == "HitLanded" then
		-- Add hit confirmation here if needed
	end
end

local function _connectServerEvents()
	framework:ConnectToChannel(COMBAT_CHANNEL, "CombatClient", _onCombatChannelEvent)
end

---------------------------------------------------------------------------
-- FRAMEWORK: RENDER TICK (crouch animation loop)
---------------------------------------------------------------------------

function module:RenderTick(_delta)
	if not crouching then return end
	if not cachedStates or cachedStates.MobilityState ~= "Crouching" then
		crouching = false
		if crouchlooptrack then crouchlooptrack:Stop() end
		if crouchwalktrack then crouchwalktrack:Stop() end
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
end

---------------------------------------------------------------------------
-- PUBLIC: START (called by framework)
---------------------------------------------------------------------------

function module:Start()
	Services, Modules, Shared = framework:Include({
		Services = {},
		Modules  = { "ClientFunctions" },
		Shared   = {}
	})

	_connectServerEvents()
	-- Defer initial refresh so PlayerData is populated and remotes exist
	task.defer(_refreshCombatInfo)
	
	ReplicatedStorage.FrameworkModules.Inputs.GameplayInputs.Attack.Pressed:Connect(function()
		
	end)
	
	coroutine.wrap(function()
		module:Init(Modules.ClientFunctions.Character)
	end)()
end

---------------------------------------------------------------------------
-- PUBLIC: INIT (called on character spawn / respawn by LocalScript)
---------------------------------------------------------------------------

function module:Init(newChar)
	char     = newChar
	hum      = char:WaitForChild("Humanoid")
	animator = hum:WaitForChild("Animator")
	root     = char:WaitForChild("HumanoidRootPart")

	rayParams.FilterDescendantsInstances = {char}

	-- Reset all state
	combo           = 0
	lastAttackTime  = 0
	attacking       = false
	blocking        = false
	equipped        = false
	blocklocked     = false
	if blocklockThread then task.cancel(blocklockThread) blocklockThread = nil end
	activeBlockBar   = nil
	styleInfo        = nil
	weaponInfo       = nil
	attackAnims      = {}
	blockTrack       = nil
	blockBrokenTrack = nil
	equipTrack       = nil
	idleTrack        = nil
	stunTrack        = nil

	cachedStates  = nil
	crouching     = false
	sliding       = nil
	run           = false
	lastw         = nil
	time1         = nil
	stop          = nil
	slideSpeed    = 0
	_disconnectSprintAttrListener()

	_loadMovementAnims()
	_updateJumpState()
	_refreshCombatInfo()
end

---------------------------------------------------------------------------
-- PUBLIC: COMBAT ACTIONS
---------------------------------------------------------------------------

function module:DoAttack()
	if attacking or blocking then return end
	if not equipped then return end

	for _, anim in ipairs(attackAnims) do
		if anim and anim.IsPlaying then return end
	end

	local canAttack = statesInvoke("canperform", "Attack")
	if not canAttack then return end

	if not styleInfo then
		_refreshCombatInfo()
		if not styleInfo then return end
	end

	local now              = os.clock()
	local comboRefreshTime = styleInfo.ComboRefreshTime or 2
	if weaponInfo and weaponInfo.ComboRefreshTimeModifier then
		comboRefreshTime = comboRefreshTime * weaponInfo.ComboRefreshTimeModifier
	end

	if now - lastAttackTime > comboRefreshTime then combo = 0 end
	combo = combo + 1
	if combo > (styleInfo.AttackAmount or 4) then combo = 1 end

	attacking      = true
	lastAttackTime = now
	_updateJumpState()

	local track     = attackAnims[combo]
	local animSpeed = 1

	if track then
		local speedKey  = SPEED_KEYS[combo] or "First"
		animSpeed       = styleInfo.AnimSpeeds[speedKey] or 1
		if weaponInfo and weaponInfo.AnimSpeedsModifier and weaponInfo.AnimSpeedsModifier[speedKey] then
			animSpeed = animSpeed * weaponInfo.AnimSpeedsModifier[speedKey]
		end
		local swingSpeed = styleInfo.SwingSpeed or 1
		if weaponInfo and weaponInfo.SwingSpeedModifier then
			swingSpeed = swingSpeed * weaponInfo.SwingSpeedModifier
		end
		animSpeed = animSpeed * swingSpeed
		track:Play(0.1, 1, animSpeed)
	end

	local animDuration          = track and (track.Length / animSpeed) or 0.5
	local success, serverCombo  = combatInvoke("attack", combo, animDuration)

	if not success then
		if track and track.IsPlaying then track:Stop() end
		combo     = 0
		attacking = false
		_updateJumpState()
		return
	end

	if serverCombo and serverCombo ~= combo then combo = serverCombo end

	local debounceTime = styleInfo.DebounceTime or 0.25
	if weaponInfo and weaponInfo.DebounceTimeModifier then
		debounceTime = debounceTime * weaponInfo.DebounceTimeModifier
	end
	local cooldown = math.max(animDuration, debounceTime)

	task.delay(cooldown, function()
		attacking = false
		_updateJumpState()
	end)
end

function module:StartBlock()
	if blocking or attacking then return end
	if not equipped then return end

	local canBlock = statesInvoke("canperform", "Block")
	if not canBlock then return end

	if not styleInfo then
		_refreshCombatInfo()
		if not styleInfo then return end
	end

	local success, hp, maxHP, blockAnimId = combatInvoke("startblock")
	if not success then return end

	blocking = true
	_updateJumpState()

	if blockAnimId and blockAnimId ~= "" then
		local serverBlockTrack = _loadAnimFromId(blockAnimId)
		if serverBlockTrack then blockTrack = serverBlockTrack end
	end

	if blockTrack then blockTrack:Play() end
	_showBlockBar(hp, maxHP)
end

function module:EndBlock()
	if not blocking then return end
	if blocklocked then return end

	blocking = false
	_updateJumpState()

	local success, reason = combatInvoke("endblock")
	if not success and reason == "Blocklocked" then
		blocking = true
		_updateJumpState()
		return
	end

	if blockTrack and blockTrack.IsPlaying then blockTrack:Stop() end
	_hideBlockBar()
end

function module:ToggleEquip()
	if attacking or blocking then return end

	local success, result = combatInvoke("equip")
	if not success then return end

	if result == "equipped" then
		equipped = true
		_updateJumpState()

		-- Refresh so tracks reflect the current loadout
		_refreshCombatInfo()

		local sprintAnimId = styleInfo and styleInfo.AnimationIDs and styleInfo.AnimationIDs.Sprint or nil
		if sprintAnimId and sprintAnimId ~= "" then
			char:SetAttribute("EquippedSprintAnim", sprintAnimId)
		end

		if equipTrack then
			equipTrack:Play()
		end

		if idleTrack then
			if equipTrack then
				task.delay(equipTrack.Length, function()
					if equipped and idleTrack then idleTrack:Play() end
				end)
			else
				idleTrack:Play()
			end
		end

	elseif result == "unequipped" then
		equipped = false
		_updateJumpState()
		_stopCombatAnims()
		char:SetAttribute("EquippedSprintAnim", nil)
	end
end

---------------------------------------------------------------------------
-- PUBLIC: MOVEMENT ACTIONS
---------------------------------------------------------------------------

function module:TryDash()
	local states = _getStates()
	if not states then return end
	if _isBusy() then return end
	if _mobilityIs("Crouching") or _mobilityIs("Swimming") or _mobilityIs("Dashing") then return end
	if not _canPerform("Dash") then return end
	if hum.MoveDirection == Vector3.zero then return end

	local at = Instance.new("Attachment")
	at.Parent = root

	local v = Instance.new("LinearVelocity")
	v.Attachment0    = at
	v.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	v.VectorVelocity = hum.MoveDirection * 70
	v.MaxAxesForce   = Vector3.new(100000, 0, 100000)
	v.Parent         = root

	game.Debris:AddItem(v,  0.2)
	game.Debris:AddItem(at, 0.2)

	_requestStateChange("MobilityState", "Dashing")
	dashAnims[_getDashAnimIndex()]:Play(0.1, 1, 1.5)

	task.delay(0.3, function()
		if cachedStates and cachedStates.MobilityState == "Dashing" then
			_requestStateChange("MobilityState", "Idle")
		end
	end)
end

function module:StartHighJump()
	local states = _getStates()
	if not states then return end
	if _isBusy() then return end
	if _mobilityIs("Crouching") then return end

	local humState = hum:GetState()
	local inAir = humState == Enum.HumanoidStateType.Freefall or humState == Enum.HumanoidStateType.Jumping
	if inAir and not _mobilityIs("Swimming") then return end

	time1         = os.clock()
	hum.WalkSpeed = 7
	hum.JumpPower = 0
	hj1track:Play()

	stop = task.delay(5, function()
		_performHighJump(5)
		time1 = nil
		stop  = nil
	end)
end

function module:ReleaseHighJump()
	local states = _getStates()
	if not states then return end

	if _isBusy() then
		if stop then task.cancel(stop) stop = nil end
		time1 = nil
		return
	end

	if time1 then
		local chargeTime = os.clock() - time1
		time1 = nil
		if stop then task.cancel(stop) stop = nil end
		_performHighJump(chargeTime)
	end
end

function module:TrySlideJump()
	if not _mobilityIs("Sliding") or not sliding then return end

	local v = root:FindFirstChild("SlideVelocity")
	if not v then return end

	sliding:Disconnect()
	if slidetrack then slidetrack:Stop() end
	sj1track:Play()
	hum.AutoRotate = true

	if root:FindFirstChild("SlideAngularVelocity") then
		root.SlideAngularVelocity:Destroy()
	end

	local t      = os.clock()
	local runConn
	local u      = 0
	local played = false
	v.MaxAxesForce = Vector3.new(100000, 100000, 100000)

	runConn = RunService.Heartbeat:Connect(function()
		local look = root.CFrame.LookVector
		root.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))

		if os.clock() - t <= 0.5 then
			local n = slideSpeed + 20
			v.VectorVelocity = (root.CFrame.LookVector + root.CFrame.UpVector).Unit * n - Vector3.new(0, u * n / 30, 0)
			if v.VectorVelocity.Y <= 0 and not played then
				played = true
				sj1track:Stop()
				sj2track:Play()
			end
			u += 1
		else
			sj2track:Stop()
			hum.JumpPower = DEFAULT_JUMP_POWER
			v:Destroy()
			runConn:Disconnect()
			_requestStateChange("MobilityState", "Idle")
		end
	end)
end

function module:TryCrouchOrSlide()
	local states = _getStates()
	if not states then return end
	if _mobilityIs("Swimming") then return end

	-- Toggle crouch off
	if crouching then
		crouching = false
		crouchtrack:Stop()
		crouchlooptrack:Stop()
		crouchwalktrack:Stop()
		hum.WalkSpeed = DEFAULT_WALK_SPEED
		hum.JumpPower = 40
		_requestStateChange("MobilityState", "Idle")
		return
	end

	local humState = hum:GetState()
	local inAir = humState == Enum.HumanoidStateType.Jumping or humState == Enum.HumanoidStateType.Freefall
	if inAir then return end

	if _mobilityIs("Running") then
		-- SLIDE
		hum.WalkSpeed  = DEFAULT_WALK_SPEED
		hum.JumpPower  = 0
		hum.AutoRotate = false
		if runtrack then runtrack:Stop() end
		slidetrack:Play()
		run = false
		_disconnectSprintAttrListener()

		_requestStateChange("MobilityState", "Sliding")

		local angVel = Instance.new("AngularVelocity")
		angVel.Name            = "SlideAngularVelocity"
		angVel.Attachment0     = root.RootAttachment
		angVel.AngularVelocity = Vector3.zero
		angVel.MaxTorque       = 0
		angVel.RelativeTo      = Enum.ActuatorRelativeTo.Attachment0
		angVel.Parent          = root

		local linVel = Instance.new("LinearVelocity")
		linVel.Name          = "SlideVelocity"
		linVel.Attachment0   = root.RootAttachment
		linVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		linVel.Parent        = root

		slideSpeed = 30

		sliding = RunService.Heartbeat:Connect(function(dt)
			local c1 = hum:GetState() == Enum.HumanoidStateType.Jumping
			local c2 = hum:GetState() == Enum.HumanoidStateType.Freefall
			if not sliding or c1 or c2 then return end

			local r1 = workspace:Raycast(root.Position, -Vector3.yAxis * 7, rayParams)
			if not r1 then return end

			local scale = math.deg(r1.Normal:Angle(Vector3.yAxis))
			linVel.MaxAxesForce = Vector3.new(100000, 0, 100000)
			angVel.MaxTorque    = math.huge

			if scale == 0 then
				local look = root.CFrame.LookVector
				linVel.VectorVelocity = Vector3.new(look.X, 0, look.Z) * slideSpeed
				if slideSpeed - SLIDE_DECEL * dt <= 0 then
					_cleanupSlide()
				else
					slideSpeed -= SLIDE_DECEL * dt
				end
			else
				local ns
				if math.deg(r1.Normal:Angle(root.CFrame.LookVector)) > 100 then
					ns = 30 - 20 * math.sin(math.rad(scale)) - SLIDE_DECEL * dt
					if ns <= 0 then _cleanupSlide() return end
				else
					ns = 30 + 20 * math.sin(math.rad(scale))
				end
				linVel.VectorVelocity = root.CFrame.LookVector * ns
				slideSpeed = ns
			end
		end)
	else
		-- CROUCH
		if _isBusy() then return end
		crouching     = true
		hum.WalkSpeed = CROUCH_WALK_SPEED
		hum.JumpPower = 0
		crouchtrack:Play()
		_requestStateChange("MobilityState", "Crouching")
		task.delay(crouchtrack.Length, function()
			if not crouching then return end
			crouchlooptrack:Play()
		end)
	end
end

function module:TryRun()
	local states = _getStates()
	if not states then return end
	if _isBusy() or _mobilityIs("Crouching") then return end

	if not lastw then
		lastw = os.clock()
	else
		if os.clock() - lastw <= 0.2 then
			if not _canPerform("Run") then
				lastw = nil
				return
			end
			run      = true
			runtrack = _loadSprintAnimation()
			runtrack:Play()
			_connectSprintAttrListener()
			_requestStateChange("MobilityState", "Running")
			hum.WalkSpeed = SPRINT_WALK_SPEED
		else
			lastw = os.clock()
		end
	end
end

function module:TryStopRun()
	if lastw and run then
		if _isBusy() then
			lastw = nil
			run   = false
			_disconnectSprintAttrListener()
			return
		end
		if runtrack then runtrack:Stop() end
		_requestStateChange("MobilityState", "Idle")
		hum.WalkSpeed = DEFAULT_WALK_SPEED
		run           = false
		lastw         = nil
		_disconnectSprintAttrListener()
	end
end

return module