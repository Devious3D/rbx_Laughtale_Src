local UIMethods = {}


function UIMethods:LocationUI(plr: Player, LocationName, LocationDescription)
	local playerGui = plr:WaitForChild("PlayerGui")
	local locationUI = playerGui:WaitForChild("RegionLocationGUI")
	local PlaceName = locationUI:WaitForChild("LocationName")
	local PlaceDescription = locationUI:WaitForChild("LocationDescription")
	PlaceName.Text = LocationName
	PlaceName.TextTransparency = 1
	PlaceDescription.Text = LocationDescription
	PlaceDescription.TextTransparency = 1
	locationUI.Enabled = true
	
	local TS = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1.5)
	local TurnOnTween = {TextTransparency = 0}
	local TurnOffTween = {TextTransparency = 1}
	local tween1 = TS:Create(PlaceName, tweenInfo, TurnOnTween)
	local tween2 = TS:Create(PlaceDescription, tweenInfo, TurnOnTween)
	tween1:Play()
	tween2:Play()
	
	task.wait(2.5)
	
	local tween3 = TS:Create(PlaceName, tweenInfo, TurnOffTween)
	local tween4 = TS:Create(PlaceDescription, tweenInfo, TurnOffTween)
	tween3:Play()
	tween4:Play()
	
	task.wait(.5)
	
	locationUI.Enabled = false
	
end

return UIMethods
