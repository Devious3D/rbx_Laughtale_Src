--task.wait(5)
-- CombatController LocalScript: Place in StarterPlayerScripts
-- Handles attack, block, and equip input

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")
local root = char:WaitForChild("HumanoidRootPart")

local CRF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatRemoteFunction")
local SRF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StatesRemoteFunction")
local DRF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DataRemoteFunction")
local CRE = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatRemoteEvent")

local blockBarTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("BlockBar")

----------------------------------------------------------------
-- LOCAL STATE
----------------------------------------------------------------
local combo = 0
local lastAttackTime = 0
local attacking = false
local blocking = false
local equipped = false
local blocklocked = false
local blocklockThread = nil

local styleInfo = nil
local weaponInfo = nil
local styleName = ""
local weaponName = ""

-- Animation tracks
local attackAnims = {}
local blockTrack = nil
local blockBrokenTrack = nil
local equipTrack = nil
local idleTrack = nil
local stunTrack = nil

-- Block bar GUI
local activeBlockBar = nil

local SPEED_KEYS = { "First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth" }

----------------------------------------------------------------
-- ANIMATION HELPERS
----------------------------------------------------------------
local function loadAnimFromId(animId)
	if not animId or animId == "" then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	return animator:LoadAnimation(anim)
end

local function stopAllAttackAnims()
	for _, track in ipairs(attackAnims) do
		if track and track.IsPlaying then
			track:Stop()
		end
	end
end

local function stopCombatAnims()
	stopAllAttackAnims()
	if blockTrack and blockTrack.IsPlaying then blockTrack:Stop() end
	if blockBrokenTrack and blockBrokenTrack.IsPlaying then blockBrokenTrack:Stop() end
	if equipTrack and equipTrack.IsPlaying then equipTrack:Stop() end
	if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
	if stunTrack and stunTrack.IsPlaying then stunTrack:Stop() end
end

----------------------------------------------------------------
-- REFRESH COMBAT INFO (call when loadout changes)
----------------------------------------------------------------
local function refreshCombatInfo()
	local ld = DRF:InvokeServer("ld")
	if not ld then return end

	styleName = ld.Primary or "DefaultFist"
	weaponName = ld.BindedWeapon or ""

	styleInfo = CRF:InvokeServer("get", "StyleInfo", styleName)
	if weaponName ~= " " and weaponName ~= "" then
		weaponInfo = CRF:InvokeServer("get", "WeaponInfo", weaponName)
	else
		weaponInfo = nil
	end

	if not styleInfo then
		warn("CombatController: No style info for", styleName)
		return
	end

	-- Load attack animations
	attackAnims = {}
	for i = 1, (styleInfo.AttackAmount or 4) do
		local animId = styleInfo.AnimationIDs["Anim" .. i]
		attackAnims[i] = loadAnimFromId(animId)
	end

	-- Load block animation (weapon override or style default)
	local blockAnimId = styleInfo.AnimationIDs.Block
	if weaponInfo and weaponInfo.AnimationOverrides and weaponInfo.AnimationOverrides.Block then
		local override = weaponInfo.AnimationOverrides.Block
		if override and override ~= "idk" and override ~= "" then
			blockAnimId = override
		end
	end
	blockTrack = loadAnimFromId(blockAnimId)

	-- Load block broken animation
	blockBrokenTrack = loadAnimFromId(styleInfo.AnimationIDs.BlockBroken)

	-- Load equip and idle animations
	equipTrack = loadAnimFromId(styleInfo.AnimationIDs.Equip)
	idleTrack = loadAnimFromId(styleInfo.AnimationIDs.Idle)

	-- Reset combo
	combo = 0
	lastAttackTime = 0
end

----------------------------------------------------------------
-- JUMP MONITORING
-- Disables jumping when current local state doesn't allow it
----------------------------------------------------------------
local DEFAULT_JUMP_POWER = 50

local function updateJumpState()
	if blocking or attacking or equipped then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		hum.JumpPower = 0
	else
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hum.JumpPower = DEFAULT_JUMP_POWER
	end
end
----------------------------------------------------------------
-- BLOCK BAR GUI
----------------------------------------------------------------
local function showBlockBar(currentHP, maxHP)
	if activeBlockBar then return end
	local clone = blockBarTemplate:Clone()
	clone.Adornee = player.Character:WaitForChild("Head")
	clone.Parent = player.PlayerGui
	print(clone)
	-- Set initial bar size
	clone:WaitForChild("Frame"):WaitForChild("background").BackgroundTransparency = 0
	clone:WaitForChild("Frame"):WaitForChild("background"):WaitForChild("bar").BackgroundTransparency = 0
	clone:WaitForChild("ImageLabel").ImageTransparency = 0
	local bar = clone:FindFirstChild("Frame") and clone.Frame:FindFirstChild("background"):FindFirstChild("bar")
	if bar then
		local ratio = math.clamp(currentHP / maxHP, 0, 1)
		bar.Size = UDim2.fromScale(ratio, 1)
	end
	activeBlockBar = clone
end

local function updateBlockBar(currentHP, maxHP)
	if not activeBlockBar then return end
	local bar = activeBlockBar:FindFirstChild("Frame") and activeBlockBar.Frame:FindFirstChild("background"):FindFirstChild("bar")
	if not bar then return end
	local ratio = math.clamp(currentHP / maxHP, 0, 1)
	local tween = TweenService:Create(bar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(ratio, 1)
	})
	tween:Play()
end

local function hideBlockBar()
	if activeBlockBar then
		activeBlockBar:Destroy()
		activeBlockBar = nil
	end
	print("endblock")
end

----------------------------------------------------------------
-- ATTACK
----------------------------------------------------------------
local function doAttack()
	if attacking or blocking then return end
	if not equipped then return end

	-- Don't allow next attack if current attack animation is still playing
	for _, anim in ipairs(attackAnims) do
		if anim and anim.IsPlaying then return end
	end

	-- Check state permission
	local canAttack = SRF:InvokeServer("canperform", "Attack")
	if not canAttack then return end

	if not styleInfo then
		refreshCombatInfo()
		if not styleInfo then return end
	end

	-- Combo timing
	local now = os.clock()
	local comboRefreshTime = styleInfo.ComboRefreshTime or 2
	if weaponInfo and weaponInfo.ComboRefreshTimeModifier then
		comboRefreshTime = comboRefreshTime * weaponInfo.ComboRefreshTimeModifier
	end

	if now - lastAttackTime > comboRefreshTime then
		combo = 0
	end

	combo = combo + 1
	if combo > (styleInfo.AttackAmount or 4) then
		combo = 1
	end

	attacking = true
	lastAttackTime = now
	updateJumpState()

	-- Play animation locally for responsiveness
	local track = attackAnims[combo]
	local animSpeed = 1
	if track then
		local speedKey = SPEED_KEYS[combo] or "First"
		animSpeed = styleInfo.AnimSpeeds[speedKey] or 1
		if weaponInfo and weaponInfo.AnimSpeedsModifier and weaponInfo.AnimSpeedsModifier[speedKey] then
			animSpeed = animSpeed * weaponInfo.AnimSpeedsModifier[speedKey]
		end
		-- SwingSpeed is a global speed modifier for the style, weapon modifier adjusts further
		local swingSpeed = styleInfo.SwingSpeed or 1
		if weaponInfo and weaponInfo.SwingSpeedModifier then
			swingSpeed = swingSpeed * weaponInfo.SwingSpeedModifier
		end
		animSpeed = animSpeed * swingSpeed
		track:Play(0.1, 1, animSpeed)
	end

	-- Send attack request to server (include animation duration for hitbox timing)
	local animDuration = track and (track.Length / animSpeed) or 0.5
	local success, serverCombo = CRF:InvokeServer("attack", combo, animDuration)

	if not success then
		-- Server rejected, stop animation
		if track and track.IsPlaying then
			track:Stop()
		end
		combo = 0
		attacking = false
		updateJumpState()
		return
	end

	-- Sync combo with server if different
	if serverCombo and serverCombo ~= combo then
		combo = serverCombo
	end

	-- Wait for animation to finish before allowing next attack
	-- Actual playback time = animation length / play speed
	local animDuration = track and (track.Length / animSpeed) or 0.5
	local debounceTime = styleInfo.DebounceTime or 0.25
	if weaponInfo and weaponInfo.DebounceTimeModifier then
		debounceTime = debounceTime * weaponInfo.DebounceTimeModifier
	end
	local cooldown = math.max(animDuration, debounceTime)

	task.delay(cooldown, function()
		attacking = false
		updateJumpState()
	end)
end

----------------------------------------------------------------
-- BLOCK
----------------------------------------------------------------
local function startBlock()
	if blocking or attacking then return end
	if not equipped then return end

	local canBlock = SRF:InvokeServer("canperform", "Block")
	if not canBlock then return end

	if not styleInfo then
		refreshCombatInfo()
		if not styleInfo then return end
	end

	-- Request block from server
	local success, hp, maxHP, blockAnimId = CRF:InvokeServer("startblock")
	if not success then return end

	blocking = true
	updateJumpState()
	if blockAnimId and blockAnimId ~= "" then
		-- Server might send a different anim than cached (weapon override resolved server-side)
		local serverBlockTrack = loadAnimFromId(blockAnimId)
		if serverBlockTrack then
			blockTrack = serverBlockTrack
		end
	end

	if blockTrack then
		blockTrack:Play()
	end

	-- Show block bar
	showBlockBar(hp, maxHP)
end

local function endBlock()
	if not blocking then return end

	-- Check if blocklocked (server enforces this too, but client prevents wasted calls)
	if blocklocked then return end

	blocking = false
	updateJumpState()

	-- Tell server
	local success, reason = CRF:InvokeServer("endblock")
	if not success and reason == "Blocklocked" then
		-- Server says we're still blocklocked, keep blocking
		blocking = true
		updateJumpState()
		return
	end

	-- Stop animation
	if blockTrack and blockTrack.IsPlaying then
		blockTrack:Stop()
	end

	-- Hide block bar
	hideBlockBar()
end

----------------------------------------------------------------
-- EQUIP
----------------------------------------------------------------
local function toggleEquip()
	if attacking or blocking then return end

	local success, result, animId1, animId2 = CRF:InvokeServer("equip")
	if not success then return end

	if result == "equipped" then
		equipped = true
		updateJumpState()

		-- Refresh combat info in case loadout changed
		refreshCombatInfo()

		-- Set sprint animation attribute for movement script coordination
		local sprintAnimId = styleInfo and styleInfo.AnimationIDs and styleInfo.AnimationIDs.Sprint or nil
		if sprintAnimId and sprintAnimId ~= "" then
			char:SetAttribute("EquippedSprintAnim", sprintAnimId)
		end

		-- Play equip animation then idle
		if equipTrack then
			equipTrack:Play()
		end

		if idleTrack then
			if equipTrack then
				task.delay(equipTrack.Length, function()
					if equipped and idleTrack then
						idleTrack:Play()
					end
				end)
			else
				idleTrack:Play()
			end
		end

	elseif result == "unequipped" then
		equipped = false
		updateJumpState()
		stopCombatAnims()

		-- Clear sprint animation attribute
		char:SetAttribute("EquippedSprintAnim", nil)
	end
end


----------------------------------------------------------------
-- RECONNECT ON RESPAWN
----------------------------------------------------------------
player.CharacterAdded:Connect(function(newChar)
	char = newChar
	hum = char:WaitForChild("Humanoid")
	animator = hum:WaitForChild("Animator")
	root = char:WaitForChild("HumanoidRootPart")

	-- Reset state
	combo = 0
	lastAttackTime = 0
	attacking = false
	blocking = false
	equipped = false
	blocklocked = false
	if blocklockThread then
		task.cancel(blocklockThread)
		blocklockThread = nil
	end
	activeBlockBar = nil
	styleInfo = nil
	weaponInfo = nil
	attackAnims = {}
	blockTrack = nil
	blockBrokenTrack = nil
	equipTrack = nil
	idleTrack = nil
	stunTrack = nil

	-- Restore jump state for fresh character
	updateJumpState()
end)

----------------------------------------------------------------
-- SERVER EVENT LISTENER (block HP updates, block broken, etc.)
----------------------------------------------------------------
CRE.OnClientEvent:Connect(function(eventType, ...)
	if eventType == "BlockHPUpdate" then
		local currentHP, maxHP = ...
		updateBlockBar(currentHP, maxHP)

	elseif eventType == "BlockBroken" then
		-- Block was broken
		blocking = false
		blocklocked = false
		if blocklockThread then
			task.cancel(blocklockThread)
			blocklockThread = nil
		end

		if blockTrack and blockTrack.IsPlaying then
			blockTrack:Stop()
		end

		if blockBrokenTrack then
			blockBrokenTrack:Play()
		end

		-- Keep block bar visible at 0 briefly then hide
		updateBlockBar(0, 1)
		task.delay(1, function()
			hideBlockBar()
		end)

	elseif eventType == "BlockBrokenRecovery" then
		-- Recovered from block broken
		if blockBrokenTrack and blockBrokenTrack.IsPlaying then
			blockBrokenTrack:Stop()
		end

	elseif eventType == "Blocklock" then
		-- Server says keep blocking for this duration
		local duration = ...
		blocklocked = true

		if blocklockThread then
			task.cancel(blocklockThread)
		end
		blocklockThread = task.delay(duration, function()
			blocklocked = false
			blocklockThread = nil

			-- If player already released F, end block now
			if not UIS:IsKeyDown(Enum.KeyCode.F) and blocking then
				endBlock()
			end
		end)

	elseif eventType == "Stunned" then
		-- Player got stunned
		local sType, duration, animId = ...

		-- Stop any combat anims
		stopCombatAnims()
		blocking = false
		attacking = false
		blocklocked = false
		hideBlockBar()
		updateJumpState()

		-- Play stun animation
		if animId and animId ~= "" and animId ~= "idk" then
			stunTrack = loadAnimFromId(animId)
			if stunTrack then
				stunTrack:Play()
			end
		end

	elseif eventType == "StunRecovery" then
		-- Recovered from stun
		if stunTrack and stunTrack.IsPlaying then
			stunTrack:Stop()
		end
		stunTrack = nil

	elseif eventType == "Hit" then
		local damage = ...
		-- You can add hit effects, screen shake, etc. here

	elseif eventType == "HitLanded" then
		local targetName, damage = ...
		-- You can add hit confirmation effects here
	end
end)

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	-- ATTACK (Left Click)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		doAttack()
	end

	-- BLOCK (F)
	if input.KeyCode == Enum.KeyCode.F then
		startBlock()
	end

	-- EQUIP (E)
	if input.KeyCode == Enum.KeyCode.E then
		toggleEquip()
	end
end)

UIS.InputEnded:Connect(function(input, gpe)
	if gpe then return end

	-- RELEASE BLOCK (F)
	if input.KeyCode == Enum.KeyCode.F then
		endBlock()
	end
end)

----------------------------------------------------------------
-- INITIAL LOAD
----------------------------------------------------------------
task.defer(refreshCombatInfo)