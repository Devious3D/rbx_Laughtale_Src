local Framework = require(script.Parent)
local LinkedListTypes = require("../Types/LinkedListTypes")


local module = {}

local Head: LinkedListTypes.LinkedListKey = nil
local Tail: LinkedListTypes.LinkedListKey = nil
local length = 0

function module.new()
	module = setmetatable(module, {
		__index = function(tbl, Index)
			return module.Get(Index)
		end,

		__newindex = function(tbl, key, index)
			
			module.Insert(key, index)
		end,
		
		__len = function()
			return length
		end,
	})
	

	return module
end

function module.clear()
	
	local HeadKey: LinkedListTypes.LinkedListKey  = Head
	local CurrentKey: LinkedListTypes.LinkedListKey = Head.NextKey
	
	for i = 1, length,  1  do
		if CurrentKey.NextKey == nil then break end
		
		CurrentKey.Value = nil
		
		CurrentKey = CurrentKey.NextKey
		Head.NextKey = CurrentKey
		
		CurrentKey.NextKey = nil
	end
	
	--print(Head)
	
	Head.NextKey.Value = nil
	Head.NextKey = nil
	
	Head.Value = nil
	Head = nil
	
end


function module:ForEach(callback: (number, any | {any}) -> ())

	local CurrentKey: LinkedListTypes.LinkedListKey = Head

	for i = 1, length, 1 do
		callback(i, CurrentKey.Value)
		if CurrentKey.NextKey == nil then break end
		CurrentKey = CurrentKey.NextKey
	end

end

function module.length()
	return length
end



function UpdateCount()
	
	local CurrentKey: LinkedListTypes.LinkedListKey = Head
	local NewLength = 0
	
	for i = 1, length, 1 do
		NewLength += 1
		
		CurrentKey.Position = NewLength
		if CurrentKey.NextKey == nil then break end
		CurrentKey = CurrentKey.NextKey
	end
	
	length = NewLength
	
	print(Head)
end


function module.Insert(Value: any | {any}, Index: string): LinkedListTypes.LinkedListKey
	assert(Index ~= nil, "Index needs to be filled")
	
	local NewKey: LinkedListTypes.LinkedListKey = Framework:MakeWeakTable({})
	NewKey.Position = length + 1
	NewKey.Value = Value
	NewKey.DictionaryIndex = Index


	if (Head == nil) then
		
		Head = NewKey
		Tail = NewKey
		
		length += 1
						
		return NewKey
	end
	
	
	Tail.NextKey = NewKey
	Tail = NewKey

	
	--print(Head)

	length += 1
	UpdateCount()

	return NewKey
end

function module.Remove(Index: string)
	assert(Index ~= nil, "Index needs to be filled")
	
	local CurrentKey: LinkedListTypes.LinkedListKey = Head
	local LastKeyChecked: LinkedListTypes.LinkedListKey = nil
	
	for i = 1, length, 1 do
		
		if CurrentKey.DictionaryIndex ~= Index  then
			LastKeyChecked = CurrentKey
			
			if CurrentKey.NextKey == nil then break end
			CurrentKey = CurrentKey.NextKey
			continue
		end
		
		print(CurrentKey.DictionaryIndex)
		CurrentKey.Value = nil
		
		break;
	end
	
	pcall(function()
		LastKeyChecked.NextKey = CurrentKey.NextKey

		CurrentKey = nil
		CurrentKey = LastKeyChecked.NextKey

		--Starting from the Key was just omitted
		for i = 1, (length - CurrentKey.Position + 1), 1 do

			CurrentKey.Position -= 1
			Framework:Print(`({script.Name}): {CurrentKey.DictionaryIndex} new position {CurrentKey.Position}`)

			if CurrentKey.NextKey == nil then print(CurrentKey.DictionaryIndex) break end
			CurrentKey = CurrentKey.NextKey
		end
	end)
	
	
	
	length -= 1
	
	UpdateCount()
	--print(Head)
end

function module.Get(Index: string)
	local CurrentKey: LinkedListTypes.LinkedListKey = Head
	
	--Advancing to the Key
	for i = 1, length, 1  do
		
		if CurrentKey.DictionaryIndex == Index then break end
		
		if CurrentKey.NextKey == nil then 
			CurrentKey = nil
			break 
		end
		CurrentKey = CurrentKey.NextKey
	end
	
	if CurrentKey == nil then return nil end
	return CurrentKey.Value
end

function module.Set(Value: any | {any}, Index: string)
	
	local CurrentKey: LinkedListTypes.LinkedListKey = Head

	--Advancing to the Key
	for i = 1, length, 1  do

		if CurrentKey.DictionaryIndex == Index then 
			CurrentKey.Value = Value
			break 
		end

		if CurrentKey.NextKey == nil then break end
		CurrentKey = CurrentKey.NextKey
	end
	
end



return module.new()