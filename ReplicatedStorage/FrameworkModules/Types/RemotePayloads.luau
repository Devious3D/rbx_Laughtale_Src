local InventoryTypes = require("../Types/InventoryTypes")

--Actions
--[[
	Set
	Get
	Respawn 
]]--
export type DataRemotePayload = {
	Action: number,
	Data: {any}
}


export type tInventoryRemotePayload = {
	player: string,
	item: InventoryTypes.InventoryItem
}


--[[
	local example = {
		module = "TestModule"
		functions = {
			[1] = "TestFunction"
		},
		params = {
			[1] = {
				param1 = "Hello World!"
			}
		}
	}
]]
export type tUseModule = {
	module: string,
	functions: {string},
	params: {string}
}


local module = {}

module.DataRemoteActions = {
	Set = 1,
	Get = 2, 
	Respawn = 3
}

return module
