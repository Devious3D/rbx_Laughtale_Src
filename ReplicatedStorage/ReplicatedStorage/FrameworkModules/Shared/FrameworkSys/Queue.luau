local Framework = require("../../Framework")
local Services, Modules, Shared

local Queues: {Framework.tQueue} = {}

local module = {}

local function doesIdExsist(id: string)
	return (Queues[id] ~= nil)
end

function module:Start()

	--Services, Modules, Shared = Framework:Include({
	--	Services = {},
	--	Modules = {},
	--	Shared = {}
	--})

	warn(script.Name)
end

function module:new(elements): string
	
	local newQueue: Framework.tQueue = {
		id = Framework:GenerateID(),
		current = 0,
		line = elements
	} 
	
	Queues[newQueue.id] = newQueue
	
	return newQueue.id
end

function module:find(id: string)
	return doesIdExsist(id)
end

function module:get(id: string): Framework.tQueue
	if (not doesIdExsist(id)) then return end
	return Queues[id]
end

function module: insert(id: string, elements: any | {any})
	if (not doesIdExsist(id)) then return end
	
	if (typeof(elements) == "table")  then
		
		for i, v in pairs(elements)  do
			table.insert(Queues[id].line, v)
		end		
		
		return
	end
	
	table.insert(Queues[id].line, elements)
end

function module:size(id: string)	
	if (not doesIdExsist(id)) then return end
	return #Queues[id].line
end

function module:next(id: string, destroyIfLastElement: boolean): any
	if (not doesIdExsist(id)) then return end
	
	local queue: Framework.tQueue = Queues[id]
	local nextValue = queue.line[1]
	
	queue.current = queue.line[1]
	table.remove(queue.line, 1)

	if (#queue.line == 0 and destroyIfLastElement) then module:delete(id) end

	return nextValue
end

function module:delete(id: string)
	if (not doesIdExsist(id)) then return end
	
	Queues[id] = nil
end

return module