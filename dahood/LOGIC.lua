print('aids')
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LocalCharacter = nil
local LocalHumanoid = nil
local LocalHumanoidRootPart = nil

local LocalDataFolder = LocalPlayer:WaitForChild("DataFolder")
local LocalInventoryFolder = LocalDataFolder:WaitForChild("Inventory")
local ClientAnimations = ReplicatedStorage:WaitForChild("ClientAnimations")

local LocalCurrency = LocalDataFolder:WaitForChild("Currency")
local LocalHumanoidHealthChangedConnection = nil
local damageTaken = 0

local Framework
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
getgenv().IgnoredShop = {}

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
Mouse.TargetFilter = LocalCharacter

local IsProcessing = false
local PurchaseQueue = {}

local Library, Toggles, Options
local Logic = {}

for i,v in ipairs(workspace.Ignored.Shop:GetChildren()) do
	if v:IsA("Model") and v:GetAttribute("itemlol") and not table.find(IgnoredShop,v) then
		table.insert(IgnoredShop,v)
	end
end

local function Setup(newCharacter)
	LocalCharacter = newCharacter
	LocalHumanoid = newCharacter:WaitForChild("Humanoid")
	LocalHumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

	Mouse.TargetFilter = newCharacter

	Framework = LocalPlayerGui:WaitForChild("Framework")

	if LocalHumanoidHealthChangedConnection then
		LocalHumanoidHealthChangedConnection:Disconnect()
		LocalHumanoidHealthChangedConnection = nil
	end

	local lastHealth = LocalHumanoid.Health > 0 and LocalHumanoid.Health or LocalHumanoid.MaxHealth
    
	LocalHumanoidHealthChangedConnection = LocalHumanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			local damage = lastHealth - newHealth
			damageTaken = damage

			task.defer(function()
				if damageTaken == damage then
					damageTaken = 0
				end
			end)
		end
		lastHealth = newHealth
	end)
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

local function formatCustomNotification(templateString, shooterName, damage, partName, weaponName)
    local replacements = {
        ["{NAME}"] = shooterName,
        ["{DMG}"] = tostring(math.round(damage)),
        ["{PART}"] = partName,
        ["{WEAPON}"] = weaponName
    }
    
    local formattedMessage = templateString:gsub("{%a+}", replacements)
    
    return formattedMessage
end

local function TryPurchase(Item)
	local Bracketed = Item.Name:match("%[.-%]")
	local IsAmmoOrArmor = Item.Name:find("Ammo") or Item.Name:find("Armor")

	if Item:FindFirstChild("Amount") then
		if not Bracketed then return false end

		local GunName = (Bracketed:gsub(" Ammo", ""))
		if not searchForTool(GunName) then return false end
	end

	if not IsAmmoOrArmor and Bracketed then
		if searchForTool(Bracketed) then return false end
	end

	while true do
		if not Item or not Item.Parent or not Item:FindFirstChild("Head") or not Item:FindFirstChild("ClickDetector") or LocalCurrency.Value < Item.Price.Value then
			return false
		end

		local ValueBefore = LocalCurrency.Value

		LocalHumanoidRootPart.CFrame = Item.Head.CFrame
		task.wait(0.15)
		fireclickdetector(Item.ClickDetector)
		task.wait(0.15)

		if LocalCurrency.Value < ValueBefore then
			return true
		end
	end
end

local function ProcessQueue()
	if IsProcessing then return end
	IsProcessing = true

	local OriginalCFrame = LocalHumanoidRootPart.CFrame

	while #PurchaseQueue > 0 do
		local Item = table.remove(PurchaseQueue, 1)
		TryPurchase(Item)
	end

	LocalHumanoidRootPart.CFrame = OriginalCFrame
	IsProcessing = false
end

local function PurchaseItem(Name)
	for _, Item in ipairs(IgnoredShop) do
		if Item.Name == Name then
			table.insert(PurchaseQueue, Item)
			task.spawn(ProcessQueue)
			break
		end
	end
end
getgenv().PurchaseItem = PurchaseItem

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

	-- MAIN EVENT CONNECTIONS
	MainEvent.OnClientEvent:Connect(function(...)
		local args = {...}

		local eventType = args[1]
		local shooter = args[2]
		local weaponHandle = args[3]
		local hitPart = args[6]

		if eventType ~= "ClientBullet" then return end

		if hitPart and hitPart:IsDescendantOf(LocalCharacter) then
			local defaultText = "Hit by {NAME} for {DMG} in the {PART} with {WEAPON}"

			local shooterName = shooter and shooter.Name or "Unknown Shooter"
			local weaponName = weaponHandle and weaponHandle.Parent.Name or "Unknown Weapon"
			local partName = hitPart.Name

			local notificationText = formatCustomNotification(defaultText, shooterName, damageTaken, partName, weaponName)

			Library:Notify(notificationText,tonumber(Options.NotifyHitDuration.Value))
		end
	end)

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
		Library:Notify("DISABLED UNTIL FURTHER NOTICE (Security Reasons)", NotificationTime)
	end,function()
		
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

	-- MISC TAB
end

return Logic
