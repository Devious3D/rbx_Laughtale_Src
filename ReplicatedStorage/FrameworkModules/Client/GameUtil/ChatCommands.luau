local Framework = require("../../Framework")

local RemotePayloads = require("../../Types/RemotePayloads")

local Services, Modules, Shared

local GameCommandObjects: Folder
local GiveItem: TextChatCommand

local module = {}

function module:Start()
	
	Services, Modules, Shared = Framework:Include({
		Services = {
			"TextChatService"	
		},
		Modules = {},
		Shared = {}
	})
	
	GameCommandObjects = Services.TextChatService.GameCommands
	GiveItem = GameCommandObjects.GiveItem

	module:setUpCmds()
end

function module:setUpCmds()
	
	Framework:NewSignal("GiveItemCmd", nil, GiveItem.Triggered:Connect(function(origin:TextSource, unfiltered:string)
		
		warn("Gate cmd with player ids")
		
		const start, End = string.find(unfiltered, "/giveItem ")
		if (start and End) then
			unfiltered = string.sub(unfiltered, End+1, string.len(unfiltered))
		end	
		
		local Payload: RemotePayloads.tUseModule = {
			module = "InventoryServer",
			functions = {
				[1] = "Add"
			},
			params = {
				[1] = {}
			}
		}
		
		local InventoryAddData: RemotePayloads.tInventoryRemotePayload = {
			player = "",
			item = {
				name = "",
				amount = 0
			}
		}
		
		local currentString = ""
		local readState = 0
		
		for i=0, string.len(unfiltered) do
			const currentChar = string.sub(unfiltered, 1+i, 1+i)
			
			print(currentString)
			
			if (currentChar == " " or i==string.len(unfiltered)) then
				if (readState == 0) then InventoryAddData.player = currentString end
				if (readState == 1) then InventoryAddData.item.name = currentString end
				if (readState == 2) then InventoryAddData.item.amount = currentString end
				
				
				readState += 1
				print(readState)
				currentString = ""
				continue
			end
			
			currentString = `{currentString}{currentChar}`
		end
		
		print(InventoryAddData)
		
		Payload.params[1] = InventoryAddData
		Framework:Fire("InventoryRemote", {Payload})	
 	end))
	
end

return module
