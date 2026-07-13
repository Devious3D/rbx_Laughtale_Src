local Framework = require("../../Framework")
local Services, Modules, Shared

local DataTemplateTypes = require("../../Types/DataTemplateTypes")
local InventoryTypes = require("../../Types/InventoryTypes")

const restrictedItemNames = {
	Hotbar = 1,
	metadata = 2
}

const ItemDragOffset = UDim2.fromOffset(0, 50)
--const ItemDragOffset = UDim2.fromOffset(0, 0)

local Player: Player
local Mouse: PlayerMouse

local PlayerGui: PlayerGui
local InventoryGui: ScreenGui
local MainFrame: Frame
local ItemGuiTemplate: Frame
local InventoryFrame: Frame
local ItemSpace: ScrollingFrame
local ItemDragSpace: ScrollingFrame

local ItemSortingFrame: Frame
local SearchBar: TextBox

local CurrentlySelectedItem: ImageButton = nil

 
local module = {}

function module:Start()
	
	Services, Modules, Shared = Framework:Include({
		Services = {
			"UserInputService"
		},
		Modules = {
			"GuiCollision",
			"ClientFunctions"	
		},
		Shared = {
			"ItemMetadata"
		}
	})
	
	Framework:Connect("InventoryRemote", function(InventoryData)
		Modules.ClientFunctions.PlayerData.Inventory = InventoryData
		
		module:Update()
		--print(Modules.ClientFunctions.PlayerData)
	end)
	
	Player = Modules.ClientFunctions:GetPlayer()
	Mouse = Player:GetMouse()
	PlayerGui = Player.PlayerGui
	InventoryGui = PlayerGui.InventoryGUI
	MainFrame = InventoryGui.Main
	
	ItemGuiTemplate = InventoryGui.Templates.InventorySpace  
	InventoryFrame = MainFrame.InventoryFrame
	ItemSpace  = InventoryFrame.ItemSpace
	ItemDragSpace = InventoryGui.ItemDragSpace
	
	ItemSortingFrame = InventoryFrame.ItemSortingFrame
	SearchBar = ItemSortingFrame.SearchBar
	
	module:Update()
end


function module.Open()

end

function module.Close()

end


function module:Update()

	module:ClearItemSpace()
	Framework:DestroyGroup("InventoryItemButtons")


	local Inv: DataTemplateTypes.tInventory = Modules.ClientFunctions:GetPlayerData().Inventory

	for itemName, itemAmount in pairs(Inv) do
		if (restrictedItemNames[itemName] ~= nil) then continue end

		local newItemGui: Frame = ItemGuiTemplate:Clone()
		newItemGui.Name = itemName
		newItemGui.Amount.Text = `x{itemAmount}`
		newItemGui.Icon.Image = Shared.ItemMetadata[itemName].icon
		newItemGui.Parent = ItemSpace

	end

	InventoryFrame.Weight.WeightTotal.Text = `{Inv.metadata.InvWeight}/{Inv.metadata.MaxInvWeight}`

	module:ConnectUiItemButtons()
end

function module:ClearItemSpace()

	for i, v in pairs(ItemSpace:GetChildren())  do
		if (v.ClassName ~= "ImageButton") then continue end
		v:Destroy()
	end
	
	Framework:DestroyGroup("InventoryItemButtons")

end

--==========Button Manipulation==========--
local function selectItemButton(button: Frame?)	
	CurrentlySelectedItem = button
	CurrentlySelectedItem.Visible = false
	CurrentlySelectedItem.Parent = InventoryGui
end

local function deSelectItemButton(button: Frame?)
	if (button ~= CurrentlySelectedItem) then return end
	
	CurrentlySelectedItem.Parent = ItemSpace
	CurrentlySelectedItem = nil
end
--===============================================

function module:ConnectUiItemButtons()
	
	local InventoryItemGroup = Framework:NewConnectionGroup("InventoryItemButtons")
	
	for itemName, button: ImageButton in pairs(ItemSpace:GetChildren()) do
		if (button.ClassName ~= "ImageButton") then continue end
				
		Framework:NewSignal(`{button.Name}Hovered`, InventoryItemGroup, button.MouseEnter:Connect(function()
					
		end))
		
		Framework:NewSignal(`{button.Name}Hovered`, InventoryItemGroup , button.MouseLeave:Connect(function()
		end))
		
		
		Framework:NewSignal(`{itemName}Pressed`, InventoryItemGroup, button.MouseButton1Down:Connect(function()
			selectItemButton(button)
		end))

		Framework:NewSignal(`{itemName}Released`, InventoryItemGroup, button.MouseButton1Up:Connect(function()
			deSelectItemButton(button)
		end))
	end
	
	--Search Bar
	Framework:NewSignal("SearchBar", "InventoryItemButtons", SearchBar.Changed:Connect(function(msg)
		if (msg ~= "Text") then return end
		const SearchBarText = SearchBar.Text

		for i, v: ImageButton in pairs(ItemSpace:GetChildren())  do
			if (v.ClassName ~= "ImageButton") then continue end 
			
			const Start, End = string.find(v.Name, SearchBarText, 1) 
			if (Start == nil or End == nil) then 
				
				v.Visible = false
				continue 
			end
			
			v.Visible = true			
			--print(string.sub(v.Name, Start, End))	
		end
	end))
	
	Framework:NewSignal("SearchBarLostFocus", "InventoryItemButtons", SearchBar.FocusLost:Connect(function(pressed)
		SearchBar.Text = ""
	end))
end

function module.Tick(deltaTime)
	
	if (CurrentlySelectedItem ~= nil) then
		CurrentlySelectedItem.Visible = true
		
		
		local NewPosition: UDim2 = UDim2.fromOffset(Mouse.X, Mouse.Y) + ItemDragOffset
		CurrentlySelectedItem.Position = NewPosition	
		
		
		const ItemCollision: Framework.tGuiCollisionParams = {
			targetGUI = CurrentlySelectedItem,
			DistanceRequired = 30,
			collisionType = {Include = true},
			filteredInstances = ItemSpace:GetChildren()
		}
		
		local result:Framework.tGuiCollisionResult = Modules.GuiCollision:DistanceCollision(ItemCollision)
		print(result.Hit)
	end
end

return module