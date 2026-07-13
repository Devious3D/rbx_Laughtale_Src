-- ModuleScript: ReplicatedStorage/FrameworkModules/Server/CombatServer
-- Full combat server logic. Replaces CombatServerBridge ServerScript.
-- Integrated with Framework: remotes created/connected here, player cleanup via framework signals.
-- Uses "CombatSetUp" remote channel for all server → client combat events.

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage       = game:GetService("ServerStorage")
local Players             = game:GetService("Players")

local framework = require(ReplicatedStorage.FrameworkModules.Framework)

-- These modules live in ServerScriptService and are required directly —
-- they are NOT framework modules so we don't go through framework:Include.
local StateHandler      = require(ServerScriptService.dir_ServerScriptService.Modules.StatesHandler)
local PlayerDataHandler = require(ServerScriptService.dir_ServerScriptService.Modules.PlayerDataHandler)
local WeaponInfoTable   = require(ServerScriptService.dir_ServerScriptService.Modules.WeaponInfoTable)
local StyleInfoTable    = require(ServerScriptService.dir_ServerScriptService.Modules.StyleInfoTable)
local HitboxModule      = require(ServerScriptService.dir_ServerScriptService.Modules.HitboxModule)

----------------------------------------------------------------
-- REMOTE NAMES
----------------------------------------------------------------
local COMBAT_RF      = "CombatRemoteFunction"
local COMBAT_CHANNEL = "CombatSetUp"   -- Remote channel for server → client events

-- Default block HP when BlockAmount isn't stored in player data
local DEFAULT_BLOCK_AMOUNT = 100

----------------------------------------------------------------
-- TRACKING TABLES
----------------------------------------------------------------
local CombatData = {}  -- [player] = { combo, lastAttackTime, hitboxConnection, stateRestoreThread }
local BlockData  = {}  -- [player] = { HP, MaxHP, RegenTimer, lastHitTime, blocklockThread }
local StunData   = {}  -- [player] = { recoveryThread }

local SPEED_KEYS = { "First","Second","Third","Fourth","Fifth","Sixth","Seventh","Eighth","Ninth","Tenth" }

----------------------------------------------------------------
-- DATA ACCESSORS
-- New data layout:
--   EquippedItems.PrimaryStyle  → active fighting style name
--   Experiences.Muscle          → muscle stat
--   Experiences.<ExpKey>        → style-specific exp
--   PlayerStatus.Health         → player health (not used for combat HP directly)
----------------------------------------------------------------

local function getStyleName(player)
	local equipped = PlayerDataHandler:Get(player, "EquippedItems")
	if not equipped then return "DefaultFist" end
	return (equipped.PrimaryStyle ~= "" and equipped.PrimaryStyle) or "DefaultFist"
end

local function getWeaponName(player)
	local equipped = PlayerDataHandler:Get(player, "EquippedItems")
	if not equipped then return "" end
	return equipped.BindedWeapon or ""
end

local function getMuscle(player)
	local exp = PlayerDataHandler:Get(player, "Experiences")
	if not exp then return 0 end
	return exp.Muscle or 0
end

local function getStyleExp(player, expKey)
	local exp = PlayerDataHandler:Get(player, "Experiences")
	if not exp then return 0 end
	return exp[expKey] or 0
end

local function getBlockAmount(player)
	-- BlockAmount is not stored directly in the new schema;
	-- derive it from Experiences.Muscle or fall back to the default.
	local exp = PlayerDataHandler:Get(player, "Experiences")
	if exp and exp.Muscle then
		return DEFAULT_BLOCK_AMOUNT + math.floor(exp.Muscle * 0.1)
	end
	return DEFAULT_BLOCK_AMOUNT
end

----------------------------------------------------------------
-- CHANNEL HELPER: fire an event to one client via the CombatSetUp channel
-- The channel carries: player (target), eventType, ...args
----------------------------------------------------------------
local function fireClient(player, eventType, ...)
	framework:FireRemoteChannel(COMBAT_CHANNEL, player, eventType, ...)
end

----------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------
local function getWeaponInfo(weaponName)
	if not weaponName or weaponName == " " or weaponName == "" then return nil end
	return WeaponInfoTable[weaponName]
end

local function getHitboxLocation(wInfo)
	if not wInfo then return "Arms" end
	return wInfo.HitboxLocation or "Arms"
end

local function getExpKey(styleName)
	local si = StyleInfoTable[styleName]
	if si and si.ExpKey then return si.ExpKey end
	-- Fallback map
	local fallback = {
		DefaultFist = "FistExp",
		DefaultSword = "SwordExp",
		DefaultKick  = "KickExp",
	}
	return fallback[styleName] or "FistExp"
end

local function calculateDamage(player, styleName, weaponName)
	local si = StyleInfoTable[styleName]
	if not si then return 0 end

	local wi             = getWeaponInfo(weaponName)
	local baseDamage     = si.Damage or 10
	local damageModifier = wi and wi.DamageModifier or 1

	local muscle   = getMuscle(player)
	local expKey   = getExpKey(styleName)
	local styleExp = getStyleExp(player, expKey)

	return (baseDamage * damageModifier) + (muscle * 0.0005) + (styleExp * 0.00001)
end

local function getDebounceTime(si, wi)
	local base     = si.DebounceTime or 0.25
	local modifier = wi and wi.DebounceTimeModifier or 1
	return base * modifier
end

local function initCombatData(player)
	if not CombatData[player] then
		CombatData[player] = {
			combo              = 0,
			lastAttackTime     = 0,
			hitboxConnection   = nil,
			stateRestoreThread = nil,
		}
	end
end

local function initBlockData(player)
	local maxHP = getBlockAmount(player)
	if not BlockData[player] then
		BlockData[player] = {
			HP         = maxHP,
			MaxHP      = maxHP,
			RegenTimer = nil,
		}
	else
		BlockData[player].MaxHP = maxHP
	end
end

----------------------------------------------------------------
-- ATTACK HANDLER
----------------------------------------------------------------
local function handleAttack(player, comboNumber, clientAnimDuration)
	initCombatData(player)
	local cd = CombatData[player]

	if not StateHandler.CanPerformAction(player, "Attack") then
		return false, "State doesn't allow attacking"
	end

	local styleName  = getStyleName(player)
	local weaponName = getWeaponName(player)

	local si = StyleInfoTable[styleName]
	if not si then return false, "Invalid style" end

	local wi = getWeaponInfo(weaponName)

	local now              = os.clock()
	local comboRefreshTime = si.ComboRefreshTime * (wi and wi.ComboRefreshTimeModifier or 1)
	local debounceTime     = getDebounceTime(si, wi)

	if now - cd.lastAttackTime < debounceTime then
		return false, "Debounce"
	end

	if now - cd.lastAttackTime > comboRefreshTime then
		cd.combo = 0
	end

	cd.combo = cd.combo + 1
	if cd.combo > si.AttackAmount then
		cd.combo = 1
	end

	local serverCombo = cd.combo
	cd.lastAttackTime = now

	-- Clean up previous attack
	if cd.hitboxConnection then
		cd.hitboxConnection:Disconnect()
		cd.hitboxConnection = nil
	end
	if cd.stateRestoreThread then
		task.cancel(cd.stateRestoreThread)
		cd.stateRestoreThread = nil
	end

	-- Remember what state to restore to after the attack
	local previousState = StateHandler.GetPlayerState(player, "PrimaryState")
	if previousState == "Attacking" then
		previousState = "WeaponEquipped"
	end

	StateHandler.RequestStateChange(player, "PrimaryState", "Attacking", "Server")

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local perms = StateHandler.GetPermissions("Attacking")
			if perms and perms.WalkSpeed then
				humanoid.WalkSpeed = perms.WalkSpeed
			end
		end
	end

	local damage         = calculateDamage(player, styleName, weaponName)
	local MAX_DURATION   = 5
	local attackDuration = math.clamp(clientAnimDuration or 1, 0.1, MAX_DURATION)

	local blockInteraction = si.BlockInteraction
	if wi and wi.BlockInteractionModifier then
		blockInteraction = wi.BlockInteractionModifier
	end

	-- Build hitbox info: weapon > style > fallback
	local hitboxInfo
	if wi and wi.HitboxInfo then
		hitboxInfo = wi.HitboxInfo
	elseif si.HitboxInfo then
		hitboxInfo = si.HitboxInfo
	else
		local loc = getHitboxLocation(wi)
		local defaultSize = Vector3.new(
			si.HitboxSize and si.HitboxSize.X or 4,
			si.HitboxSize and si.HitboxSize.Y or 4,
			si.HitboxSize and si.HitboxSize.Z or 4
		)
		hitboxInfo = {}
		if loc == "Legs" then
			hitboxInfo["Right Leg"] = { HitboxSize = defaultSize, HitboxPosition = Vector3.zero, HitboxOrientation = Vector3.zero }
			hitboxInfo["Left Leg"]  = { HitboxSize = defaultSize, HitboxPosition = Vector3.zero, HitboxOrientation = Vector3.zero }
		else
			hitboxInfo["Right Arm"] = { HitboxSize = defaultSize, HitboxPosition = Vector3.zero, HitboxOrientation = Vector3.zero }
			hitboxInfo["Left Arm"]  = { HitboxSize = defaultSize, HitboxPosition = Vector3.zero, HitboxOrientation = Vector3.zero }
		end
	end

	local comboKey          = SPEED_KEYS[serverCombo] or "First"
	local attackInfo        = wi and wi.AttackInfo and wi.AttackInfo[comboKey] or nil

	local isBlockable       = attackInfo and attackInfo.Blockable ~= nil and attackInfo.Blockable or (blockInteraction == "blockable")
	local perAttackBlockDmg = attackInfo and attackInfo.BlockDamage or (si.BlockDamage or 10)
	local blocklock         = attackInfo and attackInfo.Blocklock or nil
	local stunType          = attackInfo and attackInfo.StunType or "SoftStunned"
	local stunTime          = (si.StunTime or 1) * (attackInfo and attackInfo.StunTimeModifier or 1)
	local stunAnimId        = si.StunAnimations and si.StunAnimations["Anim" .. serverCombo] or nil

	cd.hitboxConnection = HitboxModule:RunHitDetection(player, hitboxInfo, attackDuration, function(hitPlayer, hitChar, hitHumanoid)
		if not hitHumanoid or hitHumanoid.Health <= 0 then return end

		-- IFrames check
		if hitPlayer then
			local targetFullState = StateHandler.GetPlayerState(hitPlayer)
			if targetFullState and targetFullState.IFrames then return end
		end

		-- Block check
		local targetBlocking = hitPlayer and StateHandler.GetPlayerState(hitPlayer, "PrimaryState") == "Blocking"

		if targetBlocking and hitPlayer then
			if not isBlockable then
				-- Unblockable: force block break
				initBlockData(hitPlayer)
				local bd = BlockData[hitPlayer]
				bd.HP    = 0

				StateHandler.RequestStateChange(hitPlayer, "PrimaryState", "BlockBroken", "Server")
				fireClient(hitPlayer, "BlockBroken")
				fireClient(hitPlayer, "BlockHPUpdate", 0, bd.MaxHP)

				local targetChar = hitPlayer.Character
				if targetChar then
					local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
					if targetHum then
						local brokenPerms = StateHandler.GetPermissions("BlockBroken")
						if brokenPerms then targetHum.WalkSpeed = brokenPerms.WalkSpeed or 0 end
					end
				end

				local ragdollTime = si.RagdollTime * (wi and wi.RagdollTimeModifier or 1)
				task.delay(ragdollTime, function()
					if StateHandler.GetPlayerState(hitPlayer, "PrimaryState") == "BlockBroken" then
						StateHandler.RequestStateChange(hitPlayer, "PrimaryState", "Idle", "Server")
						local tc = hitPlayer.Character
						if tc then
							local th = tc:FindFirstChildOfClass("Humanoid")
							if th then
								th.WalkSpeed = (StateHandler.GetPermissions("Idle") or {}).WalkSpeed or 16
							end
						end
						fireClient(hitPlayer, "BlockBrokenRecovery")
					end
				end)
			else
				-- Blockable: reduce block HP
				initBlockData(hitPlayer)
				local bd = BlockData[hitPlayer]
				bd.HP    = bd.HP - perAttackBlockDmg
				bd.lastHitTime = os.clock()

				fireClient(hitPlayer, "BlockHPUpdate", bd.HP, bd.MaxHP)

				if blocklock then
					if bd.blocklockThread then task.cancel(bd.blocklockThread) end
					fireClient(hitPlayer, "Blocklock", blocklock)
					bd.blocklockThread = task.delay(blocklock, function()
						bd.blocklockThread = nil
					end)
				end

				if bd.HP <= 0 then
					bd.HP = 0
					StateHandler.RequestStateChange(hitPlayer, "PrimaryState", "BlockBroken", "Server")
					fireClient(hitPlayer, "BlockBroken")

					local targetChar = hitPlayer.Character
					if targetChar then
						local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
						if targetHum then
							local brokenPerms = StateHandler.GetPermissions("BlockBroken")
							if brokenPerms then targetHum.WalkSpeed = brokenPerms.WalkSpeed or 0 end
						end
					end

					local ragdollTime = si.RagdollTime * (wi and wi.RagdollTimeModifier or 1)
					task.delay(ragdollTime, function()
						if StateHandler.GetPlayerState(hitPlayer, "PrimaryState") == "BlockBroken" then
							StateHandler.RequestStateChange(hitPlayer, "PrimaryState", "Idle", "Server")
							local tc = hitPlayer.Character
							if tc then
								local th = tc:FindFirstChildOfClass("Humanoid")
								if th then
									th.WalkSpeed = (StateHandler.GetPermissions("Idle") or {}).WalkSpeed or 16
								end
							end
							fireClient(hitPlayer, "BlockBrokenRecovery")
						end
					end)
				end
			end
		else
			-- Not blocking: apply damage, stun, knockback
			hitHumanoid:TakeDamage(damage)

			-- Knockback on final combo hit
			task.spawn(function()
				if serverCombo >= si.AttackAmount then
					local knockbackForce = si.KnockbackForce or 50
					if wi and wi.KnockbackForceModifier then
						knockbackForce = knockbackForce * wi.KnockbackForceModifier
					end

					local targetRoot   = hitChar:FindFirstChild("HumanoidRootPart")
					local attackerRoot = character and character:FindFirstChild("HumanoidRootPart")
					if targetRoot and attackerRoot then
						local dir = (targetRoot.Position - attackerRoot.Position)
						dir = Vector3.new(dir.X, 0, dir.Z)
						dir = dir.Magnitude > 0 and dir.Unit or attackerRoot.CFrame.LookVector

						local att = Instance.new("Attachment")
						att.Parent = targetRoot
						local lv = Instance.new("LinearVelocity")
						lv.Attachment0    = att
						lv.MaxForce       = math.huge
						lv.VectorVelocity = dir * knockbackForce
						lv.Parent         = targetRoot
						game.Debris:AddItem(lv,  0.2)
						game.Debris:AddItem(att, 0.2)
					end
				end
			end)

			-- Stun
			task.spawn(function()
				if hitPlayer then
					if StunData[hitPlayer] and StunData[hitPlayer].recoveryThread then
						task.cancel(StunData[hitPlayer].recoveryThread)
					end
					StunData[hitPlayer] = StunData[hitPlayer] or {}

					StateHandler.RequestStateChange(hitPlayer, "PrimaryState", stunType, "Server")
					local targetHum2 = hitChar:FindFirstChildOfClass("Humanoid")
					if targetHum2 then
						local stunPerms = StateHandler.GetPermissions(stunType)
						if stunPerms then targetHum2.WalkSpeed = stunPerms.WalkSpeed or 0 end
					end

					fireClient(hitPlayer, "Stunned", stunType, stunTime, stunAnimId)
					fireClient(hitPlayer, "Hit", damage)

					StunData[hitPlayer].recoveryThread = task.delay(stunTime, function()
						if StateHandler.GetPlayerState(hitPlayer, "PrimaryState") == stunType then
							StateHandler.RequestStateChange(hitPlayer, "PrimaryState", "Idle", "Server")
							local tc = hitPlayer.Character
							if tc then
								local th = tc:FindFirstChildOfClass("Humanoid")
								if th then
									th.WalkSpeed = (StateHandler.GetPermissions("Idle") or {}).WalkSpeed or 16
								end
							end
							fireClient(hitPlayer, "StunRecovery")
						end
						if StunData[hitPlayer] then
							StunData[hitPlayer].recoveryThread = nil
						end
					end)
				else
					-- NPC / dummy
					local npcHum = hitChar:FindFirstChildOfClass("Humanoid")
					if stunAnimId and stunAnimId ~= "" and stunAnimId ~= "idk" then
						local npcAnimator = npcHum and npcHum:FindFirstChildOfClass("Animator")
						if npcAnimator then
							local animObj = Instance.new("Animation")
							animObj.AnimationId = stunAnimId
							local npcStunTrack = npcAnimator:LoadAnimation(animObj)
							npcStunTrack:Play()
							task.delay(stunTime, function()
								if npcStunTrack and npcStunTrack.IsPlaying then npcStunTrack:Stop() end
							end)
						end
					end
					if npcHum then
						local originalWS = npcHum.WalkSpeed
						npcHum.WalkSpeed = 0
						task.delay(stunTime, function()
							if npcHum and npcHum.Parent then npcHum.WalkSpeed = originalWS end
						end)
					end
				end
			end)
		end

		fireClient(player, "HitLanded", hitPlayer and hitPlayer.Name or "NPC", damage)
	end)

	-- Restore state after attack window closes
	cd.stateRestoreThread = task.delay(attackDuration, function()
		if cd.hitboxConnection then
			cd.hitboxConnection:Disconnect()
			cd.hitboxConnection = nil
		end
		cd.stateRestoreThread = nil

		if StateHandler.GetPlayerState(player, "PrimaryState") == "Attacking" then
			local restoreState = previousState or "Idle"
			if restoreState ~= "WeaponEquipped" and restoreState ~= "Idle" then
				restoreState = "Idle"
			end
			StateHandler.RequestStateChange(player, "PrimaryState", restoreState, "Server")
			local ch = player.Character
			if ch then
				local hum = ch:FindFirstChildOfClass("Humanoid")
				if hum then
					local perms = StateHandler.GetPermissions(restoreState)
					if perms then hum.WalkSpeed = perms.WalkSpeed or 16 end
				end
			end
		end
	end)

	return true, serverCombo
end

----------------------------------------------------------------
-- BLOCK HANDLERS
----------------------------------------------------------------
local function handleStartBlock(player)
	if not StateHandler.CanPerformAction(player, "Block") then
		return false, "State doesn't allow blocking"
	end

	initBlockData(player)
	local bd = BlockData[player]

	if bd.RegenTimer then
		task.cancel(bd.RegenTimer)
		bd.RegenTimer = nil
	end

	StateHandler.RequestStateChange(player, "PrimaryState", "Blocking", "Server")

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local perms = StateHandler.GetPermissions("Blocking")
			if perms and perms.WalkSpeed then
				humanoid.WalkSpeed = perms.WalkSpeed
			end
		end
	end

	local styleName  = getStyleName(player)
	local weaponName = getWeaponName(player)
	local si         = StyleInfoTable[styleName]
	local wi         = getWeaponInfo(weaponName)
	local blockAnimId = si and si.AnimationIDs and si.AnimationIDs.Block or nil

	if wi and wi.AnimationOverrides and wi.AnimationOverrides.Block then
		local ov = wi.AnimationOverrides.Block
		if ov ~= "idk" and ov ~= "" then blockAnimId = ov end
	end

	return true, bd.HP, bd.MaxHP, blockAnimId
end

local function handleEndBlock(player)
	if StateHandler.GetPlayerState(player, "PrimaryState") ~= "Blocking" then
		return false
	end

	local bd = BlockData[player]
	if bd and bd.blocklockThread then
		if bd.lastHitTime and os.clock() - bd.lastHitTime < 1 then
			return false, "Blocklocked"
		else
			task.cancel(bd.blocklockThread)
			bd.blocklockThread = nil
		end
	end

	StateHandler.RequestStateChange(player, "PrimaryState", "Idle", "Server")

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local perms = StateHandler.GetPermissions("Idle")
			if perms and perms.WalkSpeed then
				humanoid.WalkSpeed = perms.WalkSpeed
			end
		end
	end

	if bd then
		if bd.RegenTimer then task.cancel(bd.RegenTimer) end
		bd.RegenTimer = task.delay(5, function()
			if BlockData[player] then
				BlockData[player].HP        = BlockData[player].MaxHP
				BlockData[player].RegenTimer = nil
				fireClient(player, "BlockHPUpdate", BlockData[player].HP, BlockData[player].MaxHP)
			end
		end)
	end

	return true
end

----------------------------------------------------------------
-- WEAPON MODEL HELPERS
----------------------------------------------------------------
local WeaponModelsFolder = ServerStorage:WaitForChild("WeaponModels")

local function getEquippedWeapon(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:GetAttribute("EquippedWeapon") then return child end
	end
	return nil
end

local function clearWeaponMotors(character)
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") and desc:GetAttribute("WeaponMotor") then
			desc:Destroy()
		end
	end
end

local function weldWeaponToLimbs(character, weaponName, wi, handle)
	if not wi.WeldLocation then return end
	local weldInfo = wi.WeldInfo
	for _, limbName in ipairs(wi.WeldLocation) do
		local limb = character:FindFirstChild(limbName)
		if not limb then
			warn("Limb not found: " .. limbName .. " on " .. character.Name)
			continue
		end
		local motor = Instance.new("Motor6D")
		motor.Name  = "WeaponMotor_" .. weaponName
		motor:SetAttribute("WeaponMotor", true)
		motor.Part0 = limb
		motor.Part1 = handle
		if weldInfo then
			motor.C0 = CFrame.new(weldInfo.Position) * CFrame.Angles(
				math.rad(weldInfo.Orientation.X),
				math.rad(weldInfo.Orientation.Y),
				math.rad(weldInfo.Orientation.Z)
			)
		end
		motor.Parent = limb
	end
end

local function weldWeaponToBack(character, weaponName, wi, handle)
	local torso = character:FindFirstChild("Torso")
	if not torso then return end
	local backInfo = wi and wi.BackWeldInfo
	local motor = Instance.new("Motor6D")
	motor.Name  = "WeaponMotor_" .. weaponName
	motor:SetAttribute("WeaponMotor", true)
	motor.Part0 = torso
	motor.Part1 = handle
	if backInfo then
		motor.C0 = CFrame.new(backInfo.Position) * CFrame.Angles(
			math.rad(backInfo.Orientation.X),
			math.rad(backInfo.Orientation.Y),
			math.rad(backInfo.Orientation.Z)
		)
	else
		motor.C0 = CFrame.new(0, 0, 1) * CFrame.Angles(0, 0, math.rad(45))
	end
	motor.Parent = torso
end

local function equipWeaponModel(player, weaponName, wi)
	local character = player.Character
	if not character then return end

	local existing = getEquippedWeapon(character)
	if existing then
		local handle = existing:FindFirstChild("Handle", true)
		if handle then
			clearWeaponMotors(character)
			weldWeaponToLimbs(character, weaponName, wi, handle)
		end
		return
	end

	local template = WeaponModelsFolder:FindFirstChild(weaponName)
	if not template then
		warn("No weapon model found for: " .. weaponName)
		return
	end
	if not wi.WeldLocation then
		warn("No WeldLocation defined for: " .. weaponName)
		return
	end

	local weaponModel = template:Clone()
	weaponModel.Name  = weaponName
	weaponModel:SetAttribute("EquippedWeapon", true)
	weaponModel.Parent = character

	local handle = weaponModel:FindFirstChild("Handle", true)
	if not handle then
		warn("No Handle found in weapon model: " .. weaponName)
		weaponModel:Destroy()
		return
	end

	weldWeaponToLimbs(character, weaponName, wi, handle)
end

local function unequipWeaponModel(player, weaponName, wi)
	local character = player.Character
	if not character then return end

	local unequipLocation = wi and wi.UnequipLocation or "None"

	if unequipLocation == "Back" then
		local existing = getEquippedWeapon(character)
		if existing then
			local handle = existing:FindFirstChild("Handle", true)
			if handle then
				clearWeaponMotors(character)
				weldWeaponToBack(character, weaponName or existing.Name, wi, handle)
			else
				warn("unequipWeaponModel: No Handle found in " .. existing.Name)
			end
		else
			warn("unequipWeaponModel: No equipped weapon found on character")
		end
	else
		local existing = getEquippedWeapon(character)
		if existing then existing:Destroy() end
		clearWeaponMotors(character)
	end
end

local function destroyWeaponModel(player)
	local character = player.Character
	if not character then return end
	local existing = getEquippedWeapon(character)
	if existing then existing:Destroy() end
	clearWeaponMotors(character)
end

----------------------------------------------------------------
-- EQUIP HANDLER
----------------------------------------------------------------
local function handleEquip(player)
	local currentState = StateHandler.GetPlayerState(player, "PrimaryState")

	if currentState == "Idle" then
		if not StateHandler.CanPerformAction(player, "Equip") then
			return false, "Can't equip"
		end

		local styleName  = getStyleName(player)
		local weaponName = getWeaponName(player)
		local si         = StyleInfoTable[styleName]
		local wi         = getWeaponInfo(weaponName)

		if wi then equipWeaponModel(player, weaponName, wi) end

		StateHandler.RequestStateChange(player, "PrimaryState", "WeaponEquipped", "Server")

		local equipAnimId = si and si.AnimationIDs and si.AnimationIDs.Equip or nil
		local idleAnimId  = si and si.AnimationIDs and si.AnimationIDs.Idle  or nil

		return true, "equipped", equipAnimId, idleAnimId

	elseif currentState == "WeaponEquipped" then
		if not StateHandler.CanPerformAction(player, "Unequip") then
			return false, "Can't unequip"
		end

		local weaponName = getWeaponName(player)
		local wi         = getWeaponInfo(weaponName)

		unequipWeaponModel(player, weaponName, wi)

		StateHandler.RequestStateChange(player, "PrimaryState", "Idle", "Server")
		return true, "unequipped"
	end

	return false, "Invalid state for equip"
end

----------------------------------------------------------------
-- REMOTE FUNCTION HANDLER
----------------------------------------------------------------
local function onCombatInvoke(player, action, key, ValueNeeded, ...)
	-- Info table lookups
	if action == "get" then
		if key == "WeaponInfo" then
			return ValueNeeded == "All" and WeaponInfoTable or WeaponInfoTable[ValueNeeded]
		elseif key == "StyleInfo" then
			return ValueNeeded == "All" and StyleInfoTable or StyleInfoTable[ValueNeeded]
		end
	end

	if action == "attack"     then return handleAttack(player, key, ValueNeeded) end
	if action == "startblock" then return handleStartBlock(player) end
	if action == "endblock"   then return handleEndBlock(player) end
	if action == "equip"      then return handleEquip(player) end

	if action == "getblockdata" then
		initBlockData(player)
		local bd = BlockData[player]
		return bd.HP, bd.MaxHP
	end

	return nil
end

----------------------------------------------------------------
-- PLAYER CLEANUP
----------------------------------------------------------------
local function cleanupPlayer(player)
	destroyWeaponModel(player)

	if CombatData[player] then
		if CombatData[player].hitboxConnection   then CombatData[player].hitboxConnection:Disconnect() end
		if CombatData[player].stateRestoreThread then task.cancel(CombatData[player].stateRestoreThread) end
		CombatData[player] = nil
	end
	if BlockData[player] then
		if BlockData[player].RegenTimer      then task.cancel(BlockData[player].RegenTimer) end
		if BlockData[player].blocklockThread then task.cancel(BlockData[player].blocklockThread) end
		BlockData[player] = nil
	end
	if StunData[player] then
		if StunData[player].recoveryThread then task.cancel(StunData[player].recoveryThread) end
		StunData[player] = nil
	end
end

----------------------------------------------------------------
-- MODULE
----------------------------------------------------------------
local CombatServer = {}

function CombatServer:Start()
	-- Create the CombatSetUp remote channel (3 channels for load balancing)
	framework:CreateRemoteChannel(COMBAT_CHANNEL, 3)

	-- Create the invoke remote and register its handler
	framework:CreateInvoke(COMBAT_RF)
	framework:Connect(COMBAT_RF, onCombatInvoke)

	-- Player cleanup
	framework:NewSignal("CombatServerPlayerRemoving", nil,
		Players.PlayerRemoving:Connect(cleanupPlayer)
	)

	warn(script.Name .. " started")
end

return CombatServer