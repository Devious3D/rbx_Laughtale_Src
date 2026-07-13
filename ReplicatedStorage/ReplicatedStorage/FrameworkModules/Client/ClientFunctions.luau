--!strict

local repStore = game:GetService("ReplicatedStorage")
local Framework = require("../Framework")


local module = {}

module.Character = {}
module.Player = {}
module.PlayerData = {}


function module:Start()
	warn(script.Name)
end

--Core Load Process
function module:SecondaryStart(): boolean
	
end


function module:GetPlayer(): Player
	return module.Player
end

function module:GetCharacter(): Model
	return module.Character
end

function module:GetPlayerData() :{any}
	return module.PlayerData
end


return module
