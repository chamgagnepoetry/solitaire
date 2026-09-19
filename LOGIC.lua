local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = LocalCharacter

local LocalCharacter, LocalHumanoid, LocalHumanoidRootPart
local NotificationTime = 3

local Logic = {}

local Library, Toggles, Options

local CircleRadius = Drawing.new("Circle")
CircleRadius.Thickness = 2
CircleRadius.Transparency = 0.5

local function Setup(newCharacter)
	LocalCharacter = newCharacter
	LocalHumanoid = newCharacter:WaitForChild("Humanoid")
	LocalHumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

	Mouse.TargetFilter = newCharacter
end

LocalPlayer.CharacterAdded:Connect(Setup)
Setup(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

local function getEquippedTool()
	local Tool
	for _, object in pairs(LocalCharacter:GetChildren()) do
		if object:IsA("Tool") then
			Tool = object
			return Tool
		end
	end
	return false
end

local function checkWall(target)
	if not LocalHumanoidRootPart then
		return false
	end

	local TargetCharacter = target.Character
	if not TargetCharacter then
		return false
	end

	local TargetRootPart = TargetCharacter:FindFirstChild("HumanoidRootPart")
	if not TargetRootPart then
		return false
	end

	local Origin = LocalHumanoidRootPart.Position
	local Direction = TargetRootPart.Position - Origin

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {
		LocalCharacter,
		TargetCharacter
	}

	local Result = workspace:Raycast(Origin, Direction, Params)

	return Result ~= nil
end

local function checkFriend(target)
	return LocalPlayer:IsFriendsWith(target.UserId)
end

local function checkTeam(target)
	return target.Team == LocalPlayer.Team
end

local function FindPlayerToMouse(radius, configurations)
	if not LocalHumanoidRootPart then
		return false
	end

	local ClosestPlayer = nil
	local ShortestDistance = math.huge
	local MousePos = Vector2.new(Mouse.X, Mouse.Y)

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= LocalPlayer and target.Character then
			local targetRootPart = target.Character:FindFirstChild("HumanoidRootPart")
			local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")

			if targetRootPart and targetHumanoid then
				if configurations.DeadCheck and targetHumanoid.Health <= 0 then
					continue
				end

				if configurations.FriendCheck and checkFriend(target) then
					continue
				end

				if configurations.TeamCheck and checkTeam(target) then
					continue
				end

				if configurations.WallCheck and checkWall(target) then
					continue
				end

				local screenPos, onScreen = Camera:WorldToViewportPoint(targetRootPart.Position)

				if onScreen then
					local screenVector = Vector2.new(screenPos.X, screenPos.Y)
					local distance = (screenVector - MousePos).Magnitude

					-- Only apply radius check if radius was provided
					if radius and distance > radius then
						continue
					end

					if distance < ShortestDistance then
						ShortestDistance = distance
						ClosestPlayer = target
					end
				end
			end
		end
	end

	return ClosestPlayer
end

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

	if controlObj.OnChanged then
		local loopTask

		controlObj:OnChanged(function()
			if controlObj.Value then
				if not loopTask then
					loopTask = task.spawn(function()
						pcall(function()
							while controlObj.Value do
								task.wait()
								loopFn()
							end

							loopTask = nil

							if stopFn then
								stopFn()
							end
						end)
					end)
				end
			else
				loopTask = nil

				if stopFn then
					stopFn()
				end
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
	runLoop("CameraLockKey", function()
		if not CameraTarget then
			CameraTarget = FindPlayerToMouse(nil, {
				FriendCheck = Toggles.CameraFriendCheck.Value,
				TeamCheck = Toggles.CameraTeamCheck.Value,
				WallCheck = Toggles.CameraWallCheck.Value,
				DeadCheck = Toggles.CameraDeadCheck.Value
			})
		end

		if CameraTarget and CameraTarget.Character then
			local TargetHumanoid = CameraTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.CameraDeadCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				CameraTarget = FindPlayerToMouse(nil, {
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

	local MouseTarget = nil
	runLoop("MouseLockKey", function()
		if not MouseTarget then
			MouseTarget = FindPlayerToMouse(nil, {
				FriendCheck = Toggles.MouseFriendCheck.Value,
				TeamCheck = Toggles.MouseTeamCheck.Value,
				WallCheck = Toggles.MouseWallCheck.Value,
				DeadCheck = Toggles.MouseDeadCheck.Value
			})
		end

		if MouseTarget and MouseTarget.Character then
			local TargetHumanoid = MouseTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.MouseDeadCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				MouseTarget = FindPlayerToMouse(nil, {
					FriendCheck = Toggles.MouseFriendCheck.Value,
					TeamCheck = Toggles.MouseTeamCheck.Value,
					WallCheck = Toggles.MouseWallCheck.Value,
					DeadCheck = Toggles.MouseDeadCheck.Value
				})
			end

			if MouseTarget and MouseTarget.Character then
				local TargetHeadPart = MouseTarget.Character:FindFirstChild("Head")
				if TargetHeadPart then
					local screenPos, onScreen = Camera:WorldToViewportPoint(TargetHeadPart.Position)
					if onScreen and isrbxactive() then
						mousemoveabs(screenPos.X,screenPos.Y)
					end
				end
			end
		end
	end, function()
		MouseTarget = nil
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
		local correctedPos = Vector2.new(MouseLocation.X,MouseLocation.Y)

		CircleRadius.Position = correctedPos
		CircleRadis.Radius = Options.CameraRadiusSize.Value
		CircleRadius.Visible = true
	end, function()
		CircleRadius.Visible = false
	end)
	Toggles.CameraRadius:OnChanged(function()
		if Toggles.CameraRadius.Value then
			CircleRadius.Visible = true
		else
			CircleRadius.Visible = false
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
