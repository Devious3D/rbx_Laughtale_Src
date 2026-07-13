local Framework = require("../../Framework")

local Timers: {Framework.tTimer} = {
	
}


local module = {}

module.Variable = ""

function module:Start()
	
end

function module:new(pDefaultTime, pTimerType, pMetadata: Framework.tTimerMetadata): string
	
	local newTimer: Framework.tTimer = {
		id = Framework:GenerateID(),
		currentTime = if (pTimerType == Framework.eTimerType.tickUp) then 0 else pDefaultTime,
		defaultTime = pDefaultTime,
		targetTime = if (pTimerType == Framework.eTimerType.tickUp) then pDefaultTime else 0,
		noramlized = 0,
		type = pTimerType,
		
		metadata = if (pMetadata ~= nil) then pMetadata else {
			paused = true,
			stopOnTick = false,
			Listeners = {}
		}
	}
	
	newTimer.noramlized = if (newTimer.type == Framework.eTimerType.tickUp) then (newTimer.currentTime / newTimer.defaultTime) else (newTimer.defaultTime / newTimer.currentTime)
	
	Timers[newTimer.id] = newTimer	
			
	return newTimer.id	
end

function module:get(id: string): Framework.tTimer
	return Timers[id]
end

function module:start(id: string)
	Timers[id].metadata.paused = false
end

function module:stop(id: string)
	Timers[id].metadata.paused = true
end

function module:reset(id: string)
	Timers[id].currentTime = Timers[id].defaultTime
end

function module:destroy(id: string)
	Timers[id] = nil
end 

function module:connect(id: string, func: () -> ()): string
	
	local connectionId = Framework:GenerateID()
	Timers[id].metadata.Listeners[connectionId] = func
	return connectionId
end

function module:disconnect(connectionId: string, timerId: string)
	Timers[timerId].metadata.Listeners[connectionId] = nil
end

function module.Tick(delta)	
	if (Timers == {}) then return end
	
	for i, v in pairs(Timers) do
		
		if (v.metadata.paused == true) then continue end
		
		local ticked = false;
		
		if (v.type == Framework.eTimerType.tickUp)  then
			v.currentTime += delta
			if (v.currentTime >= v.targetTime) then ticked = true end 
		end
		
		if (v.type == Framework.eTimerType.tickDown) then
			v.currentTime -= delta
			if (v.currentTime <= v.targetTime) then ticked = true end 
		end
		
		--print(v.currentTime)
		
		local sum1 = (v.currentTime - v.defaultTime)
		local sum2 = (v.targetTime - v.defaultTime)
		v.noramlized = sum1 / sum2
		
		if (ticked == true) then
			
			if (v.metadata.Listeners ~= {})  then
				--loop and run the functions
				for id, func in (v.metadata.Listeners) do
					func()
				end
			
			end
			
			if (v.metadata.stopOnTick) then
				module:destroy()
			end
			
			v.currentTime = v.defaultTime
		end
		
	end
end




return module
