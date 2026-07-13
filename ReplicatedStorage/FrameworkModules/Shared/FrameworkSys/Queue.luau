local Framework = require("../../Framework")
local Services, Modules, Shared

local Queues: {Framework.tQueue} = {}

local module = {}

local function doesIdExsist(id: string)
	assert(Queues[id] ~= nil, `{id} does not exsist`)
	--return (Queues[id] ~= nil)
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
		line = elements,
		
		metadata = {
			freezeQueue = false
		}
	} 
	
	Queues[newQueue.id] = newQueue
	
	return newQueue.id
end

function module:setMetadata(id: string, meta: Framework.tQueueMetadata)
	doesIdExsist(id)
	Queues[id].metadata = meta
end

function module:find(id: string)
	return Queues[id] ~= nil
end

function module:get(id: string): Framework.tQueue
	doesIdExsist(id)
	
	return Queues[id]
end

function module:getCurrent(id: string): any
	doesIdExsist(id)
	return Queues[id].current
end

function module:insert(id: string, elements: any | {any})
	doesIdExsist(id)

	if (typeof(elements) == "table")  then
		
		for i, v in pairs(elements)  do
			table.insert(Queues[id].line, v)
		end		
		
		return
	end
	
	table.insert(Queues[id].line, elements)
end

function module:size(id: string)	
	doesIdExsist(id)
	return #Queues[id].line
end

function module:next(id: string, destroyIfLastElement: boolean): any
	doesIdExsist(id)

	local queue: Framework.tQueue = Queues[id]
	if (queue.metadata.freezeQueue == true) then return end
	
	local nextValue = queue.line[1]
	
	queue.current = queue.line[1]
	table.remove(queue.line, 1)

	if (#queue.line == 0 and destroyIfLastElement) then module:delete(id) end

	return nextValue
end

function module:clear(id: string)
	doesIdExsist(id)
	
	Queues[id].current = 0
	Queues[id].line = {}
end

function module:delete(id: string)
	doesIdExsist(id)

	Queues[id] = nil
end

return module