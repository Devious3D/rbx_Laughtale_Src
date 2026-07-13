local Framework = require("../FrameworkModules/Framework")
local Services, Modules, Shared

local module = {}

function module:Start()
	
	Services, Modules, Shared = Framework:Include({
		Services = {},
		Modules = {},
		Shared = {}
	})
	
	warn(script.Name)
end

return module