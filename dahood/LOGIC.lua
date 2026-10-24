local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LocalCharacter, LocalHumanoid, LocalHumanoidRootPart

local LocalDataFolder = LocalPlayer:WaitForChild("DataFolder")
local LocalInventoryFolder = LocalDataFolder:WaitForChild("Inventory")
local ClientAnimations = ReplicatedStorage:WaitForChild("ClientAnimations")
local Framework

local ExpectedArguments = {
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = LocalCharacter

local SilentAimRadiusFill = Drawing.new("Circle")
local SilentAimRadius = Drawing.new("Circle")
SilentAimRadiusFill.Thickness = 0
SilentAimRadiusFill.Filled = true

local CameraRadiusFill = Drawing.new("Circle")
local CameraRadius = Drawing.new("Circle")
CameraRadiusFill.Thickness = 0
CameraRadiusFill.Filled = true

local MouseRadiusFill = Drawing.new("Circle")
local MouseRadius = Drawing.new("Circle")
MouseRadiusFill.Thickness = 0
MouseRadiusFill.Filled = true

local NotificationTime = 3

local Library, Toggles, Options
local Logic = {}

local function Setup(newCharacter)
	LocalCharacter = newCharacter
	LocalHumanoid = newCharacter:WaitForChild("Humanoid")
	LocalHumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

	Mouse.TargetFilter = newCharacter

	Framework = LocalPlayerGui:WaitForChild("Framework")
end

LocalPlayer.CharacterAdded:Connect(Setup)
Setup(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

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

local function getHumanoid(part)
	local inst = part
	for i = 1, 6 do
		inst = inst.Parent
		if not inst then return nil end
		local hum = inst:FindFirstChildOfClass("Humanoid")
		if hum then return hum end
	end
	return nil
end
getgenv().getHumanoid = getHumanoid

local function canStompBelow()
	local lower = LocalCharacter:FindFirstChild("LowerTorso")
	local upper = LocalCharacter:FindFirstChild("UpperTorso")
	if not (lower and upper) then return false end

	local part = workspace:FindPartOnRayWithIgnoreList(
		Ray.new(lower.Position, Vector3.new(0, -upper.Size.Y * 4.5, 0)),
		{ LocalCharacter, unpack(require(ReplicatedStorage.MainModule).Ignored) }
	)
	if not part then return false end

	local hum = getHumanoid(part)
	if not hum then return false end

	local char = hum.Parent
	local be = char:FindFirstChild("BodyEffects")
	if not be then return false end

	return be["K.O"].Value == true
end
getgenv().canStompBelow = canStompBelow

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

function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)

    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    -- // Return
    return chance <= Percentage / 100
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
			local callingscript = getcallingscript()
			if key == "CFrame" and Framework and callingscript == Framework and self:IsA("Camera") and Toggles.GunNoRecoil.Value then
				return
			elseif key == 'WalkSpeed' then 
				if Toggles.WalkSpeedToggle.Value then
					value = Options.WalkSpeed.Value
				end
			elseif key == "JumpPower" then 
				if Toggles.JumpPowerToggle.Value then
					value = Options.JumpPower.Value
				end
			end
			return newindex(self, key, value)
		end))
	end)

	local SilentAimTarget = nil
	--pcall(function()
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
			local Method = getnamecallmethod()
			local Arguments = {...}
			local self = Arguments[1]
			local chance = CalculateChance(SilentAimSettings.HitChance)
			if Toggles.SilentAimToggle.Value then
				if Method == "Raycast" and self == workspace and not checkcaller() and chance == true then
					print("chance")
					if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
						print("valid")
						local radiusSize = Toggles.SilentAimRadius.Value and SilentAimRadius.Radius or nil
						if not SilentAimTarget then
							SilentAimTarget = FindPlayerToMouse(radiusSize, {
								FriendCheck = Toggles.SilentAimFriendCheck.Value,
								CrewCheck = Toggles.SilentAimCrewCheck.Value,
								WallCheck = Toggles.SilentAimWallCheck.Value,
								KnockedCheck = Toggles.SilentAimKnockedCheck.Value
							})
						end

						if SilentAimTarget and SilentAimTarget.Character then
							local TargetHumanoid = SilentAimTarget.Character:FindFirstChildOfClass("Humanoid")
							if Toggles.SilentAimKnockedCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
								SilentAimTarget = FindPlayerToMouse(radiusSize, {
									FriendCheck = Toggles.SilentAimFriendCheck.Value,
									CrewCheck = Toggles.SilentAimCrewCheck.Value,
									WallCheck = Toggles.SilentAimWallCheck.Value,
									KnockedCheck = Toggles.SilentAimKnockedCheck.Value
								})
							end
				
							if SilentAimTarget and SilentAimTarget.Character then
								local TargetHeadPart = SilentAimTarget.Character:FindFirstChild("Head")
								if TargetHeadPart then
									local A_Origin = Arguments[2]
									Arguments[3] = getDirection(A_Origin, TargetHeadPart.Position)
									print('raycast')
									return oldNamecall(unpack(Arguments))
								end
							end
						end
					end
				end
			end
			return oldNamecall(...)
		end))
	--end)

	-- MAIN TAB
	local stompAnimationCooldown
	runLoop(Toggles.AutoStompToggle, function()
		MainEvent:FireServer("Stomp")
		if Toggles.AutoStompAnimation.Value and not stompAnimationCooldown and LocalHumanoid then
			if not canStompBelow() then return end

			stompAnimationCooldown = true
			task.delay(1.3, function()
				stompAnimationCooldown = false
			end)
	
			local stompAnimation = LocalHumanoid.Animator:LoadAnimation(ClientAnimations.Stomp)
			stompAnimation:Play(0.100000001, 1, 1.5)
		end
	end)

	runLoop(Toggles.SilentAimToggle, function()

	end,function()
		SilentAimTarget = nil
	end)

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
		local Gun = getEquippedGun()
		if not Gun then
			return
		end
	
		local TargetPart = Mouse.Target
		if not TargetPart then
			Gun:Deactivate()
			return
		end
	
		local TargetModel = TargetPart.Parent
		if not TargetModel then
			Gun:Deactivate()
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
			Gun:Deactivate()
			return
		elseif Toggles.GunTriggerBotKnockedCheck.Value and (TargetHumanoid.Health <= 0 or checkKnocked(TargetPlayer)) then
			Gun:Deactivate()
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
	
		if not FriendCheck and not CrewCheck then
			Gun:Activate()
		else
			Gun:Deactivate()
		end
	end)

	runLoop(Toggles.GunAutoReload, function()
		local gun = getEquippedGun()
		if not gun then
			return
		end
		if not checkLocalPlayerKnocked() and gun.Ammo.Value < 1 then
			MainEvent:FireServer("Reload",gun)
		end
	end)

	runLoop(Toggles.SilentAimRadius, function()
		local MouseLocation = UserInputService:GetMouseLocation()
		local Color = Toggles.SilentAimRadiusMatchAccent.Value and Library.AccentColor or Options.SilentAimRadiusColor.Value
		local FillColor = Toggles.SilentAimRadiusMatchAccent.Value and Library.AccentColor or Options.SilentAimRadiusFillColor.Value
		local FillVisib = Toggles.SilentAimRadiusFill.Value and true or false

		SilentAimRadius.Position = MouseLocation
		SilentAimRadius.Radius = Options.SilentAimRadiusSize.Value
		SilentAimRadius.Color = Color
		SilentAimRadius.Thickness = Options.SilentAimRadiusThickness.Value

		SilentAimRadiusFill.Position = MouseLocation
		SilentAimRadiusFill.Radius = Options.SilentAimRadiusSize.Value
		SilentAimRadiusFill.Color = FillColor
		SilentAimRadiusFill.Transparency = Options.SilentAimRadiusTransparency.Value

		SilentAimRadiusFill.Visible = FillVisib
		SilentAimRadius.Visible = true
	end, function()
		SilentAimRadiusFill.Visible = false
		SilentAimRadius.Visible = false
	end)
	Toggles.SilentAimRadius:OnChanged(function()
		if not Toggles.SilentAimRadius.Value then
			SilentAimRadiusFill.Visible = false
			SilentAimRadius.Visible = false
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
		if not Toggles.CameraRadius.Value then
			CameraRadiusFill.Visible = false
			CameraRadius.Visible = false
		end
	end)

	runLoop(Toggles.MouseRadius, function()
		local MouseLocation = UserInputService:GetMouseLocation()
		local Color = Toggles.MouseRadiusMatchAccent.Value and Library.AccentColor or Options.MouseRadiusColor.Value
		local FillColor = Toggles.MouseRadiusMatchAccent.Value and Library.AccentColor or Options.MouseRadiusFillColor.Value
		local FillVisib = Toggles.MouseRadiusFill.Value and true or false

		MouseRadius.Position = MouseLocation
		MouseRadius.Radius = Options.MouseRadiusSize.Value
		MouseRadius.Color = Color
		MouseRadius.Thickness = Options.MouseRadiusThickness.Value

		MouseRadiusFill.Position = MouseLocation
		MouseRadiusFill.Radius = Options.MouseRadiusSize.Value
		MouseRadiusFill.Color = FillColor
		MouseRadiusFill.Transparency = Options.MouseRadiusTransparency.Value

		MouseRadiusFill.Visible = FillVisib
		MouseRadius.Visible = true
	end, function()
		MouseRadiusFill.Visible = false
		MouseRadius.Visible = false
	end)
	Toggles.MouseRadius:OnChanged(function()
		if not Toggles.MouseRadius.Value then
			MouseRadiusFill.Visible = false
			MouseRadius.Visible = false
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

	local RVelocity
	local Velocity = Vector3.new(200,0,200)
	runLoop("VelocityBreakerKey", function()
		if LocalHumanoid and LocalHumanoidRootPart then
			RVelocity = LocalHumanoidRootPart.Velocity
			LocalHumanoidRootPart.Velocity = type(Velocity) == "vector" and Velocity or Velocity(RVelocity)
			RunService.RenderStepped:Wait()
			LocalHumanoidRootPart.Velocity = RVelocity
		end
	end)

	runLoop(Toggles.AntiStompToggle, function()
		if checkLocalPlayerKnocked() then
			if LocalCharacter then
				local LocalHead = LocalCharacter:FindFirstChild("Head")
				if LocalHead then
					LocalHead:Destroy()
				end
			end
		end
	end)
end

return Logic
