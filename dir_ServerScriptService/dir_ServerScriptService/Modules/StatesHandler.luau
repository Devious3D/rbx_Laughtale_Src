local StatesHandler = {}
local AllPlayerStatesTable = {}

local StatePermissions = {
	["Idle"] = {
		Attack = true,
		Block = true,
		Dash = true,
		Jump = true,
		Run = true,
		Equip = true,
		Unequip = true,
		WalkSpeed = 16,
	},
	["Blocking"] = {
		Attack = false,
		Block = false,
		Dash = true,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = 4,
	},
	["WeaponEquipped"] = {
		Attack = true,
		Block = true,
		Dash = true,
		Jump = false,
		Run = true,
		Equip = false,
		Unequip = true,
		WalkSpeed = 16,
	},
	["Attacking"] = {
		Attack = true,
		Block = false,
		Dash = false,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = 4,
	},
	["UsingSkill"] = {
		Attack = false,
		Block = false,
		Dash = false,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = nil,
	},
	["Interacting"] = {
		Attack = false,
		Block = false,
		Dash = false,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = 0,
	},
	["BlockBroken"] = {
		Attack = false,
		Block = false,
		Dash = false,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = 0,
	},
	["TrueStunned"] = {
		Attack = false,
		Block = false,
		Dash = false,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = 0,
	},
	["SoftStunned"] = {
		Attack = false,
		Block = true,
		Dash = true,
		Jump = false,
		Run = false,
		Equip = false,
		Unequip = false,
		WalkSpeed = 4,
	}
}

-- States that only the server can set, never the client
local ServerOnlyStates = {
	TrueStunned = true,
	SoftStunned = true,
	BlockBroken = true,
}

-- Valid mobility states and which permission they require from PrimaryState
local ValidMobilityStates = {
	Idle = false,
	Running = "Run",
	Dashing = "Dash",
	Swimming = false,
	Sliding = "Dash",
	Crouching = false,
	Skydash = "Dash",
	Jumping = "Jump",
	Falling = false,
}

-- Valid secondary states with server-only flag and optional permission requirement
local ValidSecondaryStates = {
	-- Neutral / client-allowed
	Idle = { serverOnly = false, permission = nil },
	Eating = { serverOnly = false, permission = nil },
	Drinking = { serverOnly = false, permission = nil },
	Carrying = { serverOnly = false, permission = nil },
	Crafting = { serverOnly = false, permission = nil },
	Fishing = { serverOnly = false, permission = nil },
	Sitting = { serverOnly = false, permission = nil },
	Sleeping = { serverOnly = false, permission = nil },

	-- Status effects / server-only
	Poisoned = { serverOnly = true, permission = nil },
	Burning = { serverOnly = true, permission = nil },
	Bleeding = { serverOnly = true, permission = nil },
	Frozen = { serverOnly = true, permission = nil },
	Electrocuted = { serverOnly = true, permission = nil },
	Drowning = { serverOnly = true, permission = nil },
	Healing = { serverOnly = true, permission = nil },
}

local function isChangeValid(player, key, newValue)
	local currentState = AllPlayerStatesTable[player.UserId]
	if not currentState then return false end

	local currentPrimary = currentState.PrimaryState

	-- Can't change PrimaryState or MobilityState if in a server-only stun state
	-- SecondaryState is exempt so status effects can still be applied
	if ServerOnlyStates[currentPrimary] and key ~= "SecondaryState" then
		return false
	end

	if key == "PrimaryState" then
		if not StatePermissions[newValue] then
			warn(player.Name .. " tried to set an invalid state: " .. tostring(newValue))
			return false
		end

		if ServerOnlyStates[newValue] then
			return false
		end

	elseif key == "MobilityState" then
		-- Check if it's a valid mobility state
		local exists = false
		for k, _ in pairs(ValidMobilityStates) do
			if k == newValue then
				exists = true
				break
			end
		end
		if not exists then
			warn(player.Name .. " tried to set an invalid mobility state: " .. tostring(newValue))
			return false
		end

		-- Check if current PrimaryState allows this movement
		local requiredPermission = ValidMobilityStates[newValue]
		if requiredPermission then
			local perms = StatePermissions[currentPrimary]
			if not perms or not perms[requiredPermission] then
				warn(player.Name .. " tried to " .. newValue .. " but PrimaryState " .. currentPrimary .. " doesn't allow it")
				return false
			end
		end

	elseif key == "SecondaryState" then
		-- Check if it's a valid secondary state
		local stateInfo = ValidSecondaryStates[newValue]
		if not stateInfo then
			warn(player.Name .. " tried to set an invalid secondary state: " .. tostring(newValue))
			return false
		end

		-- Client can't set server-only states
		if stateInfo.serverOnly then
			warn(player.Name .. " tried to set server-only secondary state: " .. tostring(newValue))
			return false
		end

		-- Check if current PrimaryState allows this action
		if stateInfo.permission then
			local perms = StatePermissions[currentPrimary]
			if not perms or not perms[stateInfo.permission] then
				warn(player.Name .. " can't " .. newValue .. " during " .. currentPrimary)
				return false
			end
		end
	end

	return true
end

function StatesHandler.AddPlayerToStatesTable(plr)
	AllPlayerStatesTable[plr.UserId] = {
		PrimaryState = "Idle",
		MobilityState = "Idle",
		SecondaryState = "Idle",
		CombatState = false,
		HeldState = nil,
		IFrames = false,
	}
end

function StatesHandler.RemovePlayerFromStatesTable(plr)
	local playerState = AllPlayerStatesTable[plr.UserId]
	if not playerState then return end

	if playerState.CombatState == true then
		-- put punishment here
	end
	AllPlayerStatesTable[plr.UserId] = nil
end

function StatesHandler.RequestStateChange(player, key, newValue, requester)
	if requester == "Client" then
		if not isChangeValid(player, key, newValue) then
			warn(player.Name .. " sent an invalid or exploiting state request!")
			return false
		end
	end

	-- Validate PrimaryState even for server calls
	if key == "PrimaryState" and not StatePermissions[newValue] then
		warn("Invalid PrimaryState: " .. tostring(newValue))
		return false
	end

	-- Validate MobilityState even for server calls
	if key == "MobilityState" then
		local exists = false
		for k, _ in pairs(ValidMobilityStates) do
			if k == newValue then
				exists = true
				break
			end
		end
		if not exists then
			warn("Invalid MobilityState: " .. tostring(newValue))
			return false
		end
	end

	-- Validate SecondaryState even for server calls
	if key == "SecondaryState" and not ValidSecondaryStates[newValue] then
		warn("Invalid SecondaryState: " .. tostring(newValue))
		return false
	end

	AllPlayerStatesTable[player.UserId][key] = newValue

	-- Auto-manage IFrames based on MobilityState
	if key == "MobilityState" then
		AllPlayerStatesTable[player.UserId].IFrames = (newValue == "Dashing")
	end

	print(player.Name .. " changed " .. key .. " to " .. tostring(newValue))
	return true
end

function StatesHandler.GetPlayerState(player, key)
	if key == nil then
		return AllPlayerStatesTable[player.UserId]
	else
		return AllPlayerStatesTable[player.UserId][key]
	end
end

function StatesHandler.GetPermissions(state)
	return StatePermissions[state]
end

function StatesHandler.CanPerformAction(player, action)
	local currentState = AllPlayerStatesTable[player.UserId]
	if not currentState then return false end

	local perms = StatePermissions[currentState.PrimaryState]
	if not perms then return false end

	return perms[action] == true
end

function StatesHandler.HoldState(player, state)
	local playerState = AllPlayerStatesTable[player.UserId]
	if not playerState then return end

	if playerState.HeldState == nil then
		playerState.HeldState = state
		return print("Holding " .. state)
	end
end

return StatesHandler