local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalCharacter, LocalHumanoid, LocalHumanoidRootPart

local LocalDataFolder = LocalPlayer:WaitForChild("DataFolder")
local LocalInventoryFolder = LocalDataFolder:WaitForChild("Inventory")

local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = LocalCharacter

local CameraRadius = Drawing.new("Circle")
local MouseRadius = Drawing.new("Circle")
local NotificationTime = 3

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
getgenv().getEquippedTool = getEquippedTool

local function getEquippedGun()
	local Tool
	for _, object in pairs(LocalCharacter:GetChildren()) do
		if object:FindFirstChild("Ammo") and object:FindFirstChild("MaxAmmo") then 
			Tool = object
			return Tool
		end
	end
	return false
end
getgenv().getEquippedGun = getEquippedGun

local function checkLocalPlayerKnocked()
	local bodyEffects = LocalCharacter and LocalCharacter:FindFirstChild("BodyEffects")
	local KO = bodyEffects and bodyEffects:FindFirstChild("K.O")

	return KO ~= nil and KO.Value == true
end
getgenv().checkLocalPlayerKnocked = checkLocalPlayerKnocked

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
getgenv().checkWall = checkWall

local function checkCrew(target)
	local function getCrew(player)
		local data = player:FindFirstChild("DataFolder")
		local info = data and data:FindFirstChild("Information")
		local crew = info and info:FindFirstChild("Crew")
		return crew and crew.Value or ""
	end

	local ourCrew = getCrew(LocalPlayer)
	local theirCrew = getCrew(target)

	return ourCrew ~= "" and ourCrew == theirCrew
end
getgenv().checkCrew = checkCrew

local function checkKnocked(target)
	local character = target and target.Character
	local bodyEffects = character and character:FindFirstChild("BodyEffects")
	local KO = bodyEffects and bodyEffects:FindFirstChild("K.O")

	return KO ~= nil and KO.Value == true
end
getgenv().checkKnocked = checkKnocked

local function checkFriend(target)
	return LocalPlayer:IsFriendsWith(target.UserId)
end
getgenv().checkFriend = checkFriend

local function checkTeam(target)
	return target.Team == LocalPlayer.Team
end
getgenv().checkTeam = checkTeam

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
				if configurations.FriendCheck and checkFriend(target) then
					continue
				end

				if configurations.CrewCheck and checkCrew(target) then
					continue
				end

				if configurations.WallCheck and checkWall(target) then
					continue
				end

				if configurations.KnockedCheck and (targetHumanoid.Health <= 0 or checkKnocked(target)) then
					continue
				end

				local screenPos, onScreen = Camera:WorldToViewportPoint(targetRootPart.Position)

				if onScreen then
					local screenVector = Vector2.new(screenPos.X, screenPos.Y)
					local distance = (screenVector - MousePos).Magnitude

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
getgenv().FindPlayerToMouse = FindPlayerToMouse

local function runLoop(controlObj, loopFn, stopFn)
	if type(controlObj) == "string" then
		local keybind

		if controlObj:sub(1, 1) == "!" then
			keybind = Options[controlObj:sub(2)]

			task.spawn(function()
				--pcall(function()
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
				--end)
			end)
		else
			keybind = Options[controlObj]

			task.spawn(function()
				--pcall(function()
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
				--end)
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

	-- HOOK FUNCTIONS

	pcall(function()
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
	end)

	-- MAIN TAB
	local CameraTarget = nil
	runLoop("!CameraLockKey", function()
		local radiusSize = Toggles.CameraRadius.Value and CameraRadius.Radius or nil
		if not CameraTarget then
			CameraTarget = FindPlayerToMouse(radiusSize, {
				FriendCheck = Toggles.CameraFriendCheck.Value,
				CrewCheck = Toggles.CameraCrewCheck.Value,
				WallCheck = Toggles.CameraWallCheck.Value,
				KnockedCheck = Toggles.CameraKnockedCheck.Value
			})
		end

		if CameraTarget and CameraTarget.Character then
			local TargetHumanoid = CameraTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.CameraKnockedCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				CameraTarget = FindPlayerToMouse(radiusSize, {
					FriendCheck = Toggles.CameraFriendCheck.Value,
					CrewCheck = Toggles.CameraCrewCheck.Value,
					WallCheck = Toggles.CameraWallCheck.Value,
					KnockedCheck = Toggles.CameraKnockedCheck.Value
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
	runLoop("!MouseLockKey", function()
		local radiusSize = Toggles.MouseRadius.Value and MouseRadius.Radius or nil
		if not MouseTarget then
			MouseTarget = FindPlayerToMouse(radiusSize, {
				FriendCheck = Toggles.MouseFriendCheck.Value,
				CrewCheck = Toggles.MouseCrewCheck.Value,
				WallCheck = Toggles.MouseWallCheck.Value,
				KnockedCheck = Toggles.MouseKnockedCheck.Value
			})
		end

		if MouseTarget and MouseTarget.Character then
			local TargetHumanoid = MouseTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.MouseKnockedCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				MouseTarget = FindPlayerToMouse(radiusSize, {
					FriendCheck = Toggles.MouseFriendCheck.Value,
					CrewCheck = Toggles.MouseCrewCheck.Value,
					WallCheck = Toggles.MouseWallCheck.Value,
					KnockedCheck = Toggles.MouseKnockedCheck.Value
				})
			end

			if MouseTarget and MouseTarget.Character then
				local TargetHeadPart = MouseTarget.Character:FindFirstChild("Head")
				if TargetHeadPart then
					local screenPos, onScreen = Camera:WorldToViewportPoint(TargetHeadPart.Position)
					if not onScreen then
						MouseTarget = FindPlayerToMouse(radiusSize, {
							FriendCheck = Toggles.MouseFriendCheck.Value,
							CrewCheck = Toggles.MouseCrewCheck.Value,
							WallCheck = Toggles.MouseWallCheck.Value,
							KnockedCheck = Toggles.MouseKnockedCheck.Value
						})
					elseif onScreen and isrbxactive() then
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

		local TargetPlayer = Players:FindFirstChild(TargetModel.Name)
		local TargetHumanoid = TargetModel:FindFirstChildOfClass("Humanoid")

		if not TargetHumanoid and TargetModel.Parent then
			TargetHumanoid = TargetModel.Parent:FindFirstChildOfClass("Humanoid")
			if TargetHumanoid then
				TargetModel = TargetModel.Parent
			end
		end

		if not TargetHumanoid then
			return
		elseif Toggles.GunTriggerBotKnockedCheck.Value and (TargetHumanoid.Health <= 0 or checkKnocked(TargetPlayer)) then
			return
		end
	
		local FriendCheck = false
		local CrewCheck = false
		
		if Toggles.GunTriggerBotCrewCheck.Value then
			CrewCheck = checkCrew(TargetPlayer)
		end

		if Toggles.GunTriggerBotFriendCheck.Value then
			FriendCheck = checkFriend(TargetPlayer)
		end

		if not FriendCheck and not CrewCheck and isrbxactive() then
			mouse1click()
		end
	end)

	runLoop(Toggles.GunAutoReload, function()
		local gun = getEquippedGun()
		if not gun then
			return
		end
		print("gun yes")
		if not checkLocalPlayerKnocked() and gun.Ammo.Value < 1 then
			print("firing event")
			MainEvent:FireServer("Reload",gun)
		end
	end)

	runLoop(Toggles.CameraRadius, function()
		local MouseLocation = UserInputService:GetMouseLocation()
		local Color = Toggles.CameraRadiusMatchAccent.Value and Library.AccentColor or Options.CameraRadiusColor.Value
		local Visibility = Toggles.CameraRadius.Value and true or false

		CameraRadius.Position = MouseLocation
		CameraRadius.Radius = Options.CameraRadiusSize.Value
		CameraRadius.Color = Color
		CameraRadius.Thickness = Options.CameraRadiusThickness.Value
		CameraRadius.Transparency = Options.CameraRadiusTransparency.Value
		CameraRadius.Visible = Visibility
	end, function()
		CameraRadius.Visible = false
	end)

	runLoop(Toggles.MouseRadius, function()
		local MouseLocation = UserInputService:GetMouseLocation()
		local Color = Toggles.MouseRadiusMatchAccent.Value and Library.AccentColor or Options.MouseRadiusColor.Value
		local Visibility = Toggles.MouseRadis.Value and true or false

		MouseRadius.Position = MouseLocation
		MouseRadius.Radius = Options.MouseRadiusSize.Value
		MouseRadius.Color = Color
		MouseRadius.Thickness = Options.MouseRadiusThickness.Value
		MouseRadius.Transparency = Options.MouseRadiusTransparency.Value
		MouseRadius.Visible = Visibility
	end, function()
		MouseRadius.Visible = false
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
end

return Logic
