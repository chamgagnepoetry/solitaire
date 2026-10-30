local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = nil
local LocalHumanoid = nil
local LocalHumanoidRootPart = nil

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = LocalCharacter

local Library, Toggles, Options
local Logic = {}

local function Setup(newCharacter)
	LocalCharacter = newCharacter
	LocalHumanoid = newCharacter:WaitForChild("Humanoid")
	LocalHumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

	Mouse.TargetFilter = newCharacter
end

LocalPlayer.CharacterAdded:Connect(Setup)
Setup(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

local function runLoop(controlObj, loopFn, stopFn)
	if type(controlObj) == "string" then
		local keybind

		if controlObj:sub(1, 1) == "!" then
			keybind = Options[controlObj:sub(2)]

			task.spawn(function()
				pcall(function()
					while true do
						local state = keybind:GetState()

						if state then
							loopFn()
						else
							if stopFn then
								stopFn()
							end
						end

						RunService.Heartbeat:Wait()
					end
				end)
			end)
		else
			keybind = Options[controlObj]

			task.spawn(function()
				pcall(function()
					while true do
						local state = keybind:GetState()

						if state then
							loopFn()
						else
							if stopFn then
								stopFn()
							end
						end

						task.wait()
					end
				end)
			end)
		end

		return
	end

	if controlObj.Value ~= nil then
		task.spawn(function()
			local wasActive = false

			while true do
				local ok, err = pcall(function()
					if controlObj.Value then
						wasActive = true
						loopFn()
					elseif wasActive then
						wasActive = false
						if stopFn then
							stopFn()
						end
					end
				end)

				if not ok then
					warn("runLoop error:", err)
				end

				task.wait()
			end
		end)
	end
end

function Logic:Initialize(UIReference)
    _G.Toggles = UIReference.Toggles
	_G.Options = UIReference.Options
	Toggles = UIReference.Toggles
	Options = UIReference.Options
	Library = UIReference.Library

	--[[pcall(function()
		LPH_NO_VIRTUALIZE = function(...) return (...) end
		local newindex; newindex = hookmetamethod(game, "__newindex", LPH_NO_VIRTUALIZE(function(self, key, value)
			if key == 'WalkSpeed' then 
				if Toggles.WalkSpeedToggle.Value then
					value = Options.WalkSpeed.Value
				end
			end
			if key == "JumpPower" then 
				if Toggles.JumpPowerToggle.Value then
					value = Options.JumpPower.Value
				end
			end
			return newindex(self, key, value)
		end))
	end)--]]
	-- MAIN TAB
	local CameraTarget = nil
	runLoop("!CameraLockKey", function()
		local radiusSize = Toggles.CameraRadius.Value and CameraRadius.Radius or nil
		if not CameraTarget then
			CameraTarget = FindPlayerToMouse(radiusSize, {
				FriendCheck = Toggles.CameraFriendCheck.Value,
				TeamCheck = Toggles.CameraTeamCheck.Value,
				WallCheck = Toggles.CameraWallCheck.Value,
				DeadCheck = Toggles.CameraDeadCheck.Value
			})
		end

		if CameraTarget and CameraTarget.Character then
			local TargetHumanoid = CameraTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.CameraDeadCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				CameraTarget = FindPlayerToMouse(radiusSize, {
					FriendCheck = Toggles.CameraFriendCheck.Value,
					TeamCheck = Toggles.CameraTeamCheck.Value,
					WallCheck = Toggles.CameraWallCheck.Value,
					DeadCheck = Toggles.CameraDeadCheck.Value
				})
			end

			if CameraTarget and CameraTarget.Character then
				local TargetHeadPart = CameraTarget.Character:FindFirstChild("Head")
				if TargetHeadPart then
					Camera.CFrame = CFrame.new(
						Camera.CFrame.Position,
						TargetHeadPart.Position
					)
				end
			end
		end
	end, function()
		CameraTarget = nil
	end)

	runLoop("GunTriggerBotKey", function()
		local Tool = getEquippedTool()
		if not Tool then
			return
		end
	
		local TargetPart = Mouse.Target
		if not TargetPart then
			return
		end
	
		local TargetModel = TargetPart.Parent
		if not TargetModel then
			return
		end
	
		local TargetHumanoid = TargetModel:FindFirstChildOfClass("Humanoid")
	
		if not TargetHumanoid and TargetModel.Parent then
			TargetHumanoid = TargetModel.Parent:FindFirstChildOfClass("Humanoid")
			if TargetHumanoid then
				TargetModel = TargetModel.Parent
			end
		end

		if not TargetHumanoid then
			return
		elseif Toggles.GunTriggerBotDeadCheck.Value and TargetHumanoid.Health <= 0 then
			return
		end
	
		local TargetPlayer = Players:FindFirstChild(TargetModel.Name)
		local FriendCheck = false
		local TeamCheck = false
		
		if Toggles.GunTriggerBotTeamCheck.Value then
			TeamCheck = checkTeam(TargetPlayer)
		end

		if Toggles.GunTriggerBotFriendCheck.Value then
			FriendCheck = checkFriend(TargetPlayer)
		end

		if not FriendCheck and not TeamCheck and isrbxactive() then
			mouse1click()
		end
	end)

	runLoop(Toggles.CameraRadius, function()
		local MouseLocation = UserInputService:GetMouseLocation()
		local Color = Toggles.CameraRadiusMatchAccent.Value and Library.AccentColor or Options.CameraRadiusColor.Value
		local FillColor = Toggles.CameraRadiusMatchAccent.Value and Library.AccentColor or Options.CameraRadiusFillColor.Value
		local FillVisib = Toggles.CameraRadiusFill.Value and true or false

		CameraRadius.Position = MouseLocation
		CameraRadius.Radius = Options.CameraRadiusSize.Value
		CameraRadius.Color = Color
		CameraRadius.Thickness = Options.CameraRadiusThickness.Value

		CameraRadiusFill.Position = MouseLocation
		CameraRadiusFill.Radius = Options.CameraRadiusSize.Value
		CameraRadiusFill.Color = FillColor
		CameraRadiusFill.Transparency = Options.CameraRadiusTransparency.Value

		CameraRadiusFill.Visible = FillVisib
		CameraRadius.Visible = true
	end, function()
		CameraRadiusFill.Visible = false
		CameraRadius.Visible = false
	end)
	Toggles.CameraRadius:OnChanged(function()
		if Toggles.CameraRadius.Value == false then
			CameraRadiusFill.Visible = false
			CameraRadius.Visible = false
		end
	end)

	-- CHARACTER TAB
    runLoop("VelocityKey", function()
		if LocalHumanoid and LocalHumanoidRootPart then
			local direction = LocalHumanoid.MoveDirection
			local velocity = LocalHumanoidRootPart.AssemblyLinearVelocity
			local vertical = velocity.Y
			local horizontal = direction * Options.VelocitySpeed.Value
			LocalHumanoidRootPart.AssemblyLinearVelocity = Vector3.new(horizontal.X,vertical, horizontal.Z)
		end
	end)

	Toggles.WalkSpeedToggle:OnChanged(function()
		if Toggles.WalkSpeedToggle.Value then
			--Library:Notify("USE AT YOUR OWN RISK!", NotificationTime)
			Library:Notify("DISABLED UNTIL FURTHER NOTICE (Security Reasons)", NotificationTime)
		end
	end)

	Toggles.JumpPowerToggle:OnChanged(function()
		if Toggles.JumpPowerToggle.Value then
			--Library:Notify("USE AT YOUR OWN RISK!", NotificationTime)
			Library:Notify("DISABLED UNTIL FURTHER NOTICE (Security Reasons)", NotificationTime)
		end
	end)
end

return Logic
