print("yo ur gay and ur like men")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LocalCharacter = nil
local LocalHumanoid = nil
local LocalHumanoidRootPart = nil

do
	if not LocalPlayer:FindFirstChild("DataFolder") then
		local loadingText = Drawing.new("Text")
		loadingText.Text = "waiting for localplayer." .. "DataFolder"
		loadingText.Size = 24
		loadingText.Center = true
		loadingText.Outline = true
		loadingText.Color = Color3.fromRGB(255, 255, 255)
		loadingText.Visible = true

		local renderConnection = RunService.RenderStepped:Connect(function()
			local currentCamera = workspace.CurrentCamera
			if currentCamera then
				loadingText.Position = currentCamera.ViewportSize / 2
			end
		end)

		LocalPlayer:WaitForChild("DataFolder")

		renderConnection:Disconnect()
		loadingText:Remove()
	end
end

local LocalDataFolder = LocalPlayer:WaitForChild("DataFolder")
local LocalInventoryFolder = LocalDataFolder:WaitForChild("Inventory")
local ClientAnimations = ReplicatedStorage:WaitForChild("ClientAnimations")

local LocalCurrency = LocalDataFolder:WaitForChild("Currency")
local LocalHumanoidHealthChangedConnection = nil

local pendingHits = {}
local unclaimedDamage = {}

local Framework
local GunHandler = require(ReplicatedStorage.Modules.GunHandler)
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

local function formatCustomNotification(templateString, shooterName, damage, partName, weaponName)
    local replacements = {
        ["{NAME}"] = shooterName,
        ["{DMG}"] = tostring(math.floor(damage)),
        ["{PART}"] = partName,
        ["{WEAPON}"] = weaponName
    }
    
    local formattedMessage = templateString:gsub("{%a+}", replacements)
    return formattedMessage
end

local function notifyDamage(hit, damage)
	local text = Options.NotifyDamageText.Value
	if text == nil or text == "" then
		text = "{NAME} HIT US FOR {DMG} IN THE {PART} USING {WEAPON}"
	end
	local notificationText = formatCustomNotification(text, hit.shooterName, damage, hit.partName, hit.weaponName)
	Library:Notify(notificationText, tonumber(Options.NotifyDamageDuration.Value))
end

local function notifyHit(hit, damage)
	if not Toggles.NotifyHitToggle.Value then return end

	local text = Options.NotifyHitText.Value
	if text == nil or text == "" then
		text = "HIT {NAME} FOR {DMG} IN THE {PART} USING {WEAPON}"
	end
	local notificationText = formatCustomNotification(text, hit.playerName, damage, hit.bodyPartName, hit.gunName)
	Library:Notify(notificationText, tonumber(Options.NotifyHitDuration.Value))
end

local function popFresh(list)
	local now = os.clock()
	while #list > 0 do
		local entry = table.remove(list, 1)
		if now - entry.time <= 1 then
			return entry
		end
	end
	return nil
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

	table.clear(pendingHits)
	table.clear(unclaimedDamage)

	local lastHealth = LocalHumanoid.Health > 0 and LocalHumanoid.Health or LocalHumanoid.MaxHealth

	LocalHumanoidHealthChangedConnection = LocalHumanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			local amount = lastHealth - newHealth

			local hit = popFresh(pendingHits)
			if hit then
				if Toggles.NotifyDamageToggle.Value then
					notifyDamage(hit, amount)
				end
			else
				table.insert(unclaimedDamage, { amount = amount, time = os.clock() })
			end
		end
		lastHealth = newHealth
	end)
end

LocalPlayer.CharacterAdded:Connect(Setup)
Setup(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())


local PurchaseMoved = false

local function getToolName(Item)
	if Item.Name:find("Ammo") or Item.Name:find("Armor") then
		return nil
	end
	if Item.Name:find("Mask") then
		return "[Mask]"
	end
	return Item.Name:match("%[.-%]")
end

local function attemptPurchase(Item)
	while true do
		if not LocalHumanoid or LocalHumanoid.Health <= 0 then
			return false
		end

		if not Item.Parent or not Item:FindFirstChild("Head") or not Item:FindFirstChild("ClickDetector") or LocalCurrency.Value < Item.Price.Value then
			return false
		end

		local ValueBefore = LocalCurrency.Value

		PurchaseMoved = true
		LocalHumanoidRootPart.CFrame = Item.Head.CFrame
		fireclickdetector(Item.ClickDetector, 0)
		task.wait()

		if LocalCurrency.Value < ValueBefore then
			return true
		end
	end
end

local function waitForTool(ToolName)
	local Tool = findToolByName(ToolName)
	if Tool or LocalHumanoid.Health <= 0 then
		return Tool
	end

	local Thread = coroutine.running()
	local Finished = false
	local Connections = {}

	local function Finish()
		if Finished then return end
		Finished = true
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
		task.spawn(Thread)
	end

	local function Watch(Container)
		if Container then
			table.insert(Connections, Container.ChildAdded:Connect(function()
				if findToolByName(ToolName) then
					Finish()
				end
			end))
		end
	end

	Watch(LocalPlayer:FindFirstChildOfClass("Backpack"))
	Watch(LocalCharacter)
	table.insert(Connections, LocalHumanoid.Died:Connect(Finish))

	coroutine.yield()

	return findToolByName(ToolName)
end

local function processEntry(Item, ReturnHome)
	local ToolName = getToolName(Item)

	if ToolName then
		local Owned = findToolByName(ToolName)
		if Owned then
			return false, Owned
		end
	end

	if Item:FindFirstChild("Amount") then
		local Bracketed = Item.Name:match("%[.-%]")
		if not Bracketed or not searchForTool((Bracketed:gsub(" Ammo", ""))) then
			return false, nil
		end
	end

	if not attemptPurchase(Item) then
		return false, nil
	end

	if #PurchaseQueue == 0 then
		ReturnHome()
	end

	if not ToolName then
		return true, nil
	end

	local Tool = waitForTool(ToolName)
	if not Tool then
		warn("bought " .. ToolName .. " but could not find it in the backpack or character")
	end
	return true, Tool
end

local function ProcessQueue()
	if IsProcessing then return end
	IsProcessing = true

	local HRP = LocalHumanoidRootPart
	local OriginalCFrame = HRP.CFrame

	local function ReturnHome()
		if PurchaseMoved and HRP.Parent then
			HRP.CFrame = OriginalCFrame
		end
		PurchaseMoved = false
	end

	while #PurchaseQueue > 0 do
		local Entry = table.remove(PurchaseQueue, 1)

		local ok, success, tool = pcall(processEntry, Entry.Item, ReturnHome)
		if not ok then
			warn("purchase error:", success)
			success, tool = false, nil
		end

		Entry.Success = success == true
		Entry.Tool = tool
		Entry.Done = true

		if Entry.Thread then
			task.spawn(Entry.Thread)
		end
	end

	ReturnHome()
	IsProcessing = false
end

local function PurchaseItem(Name, Callback)
	local Item = nil
	for _, ShopItem in ipairs(IgnoredShop) do
		if ShopItem.Name == Name then
			Item = ShopItem
			break
		end
	end

	if not Item then
		if Callback then
			Callback(false, nil)
		end
		return
	end

	local Entry = { Item = Item, Done = false }
	table.insert(PurchaseQueue, Entry)
	task.spawn(ProcessQueue)

	if not Callback then return end

	if not Entry.Done then
		Entry.Thread = coroutine.running()
		coroutine.yield()
	end

	Callback(Entry.Success, Entry.Tool)
end
getgenv().PurchaseItem = PurchaseItem

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
	return hum ~= nil and checkKnocked(hum.Parent)
end
getgenv().canStompBelow = canStompBelow

local function getLocalArmor()
	local armor = getBodyEffect(LocalCharacter, "Armor")
	return armor and armor.Value or false
end
getgenv().getLocalArmor = getLocalArmor

local function getMaxArmor(itemName)
	local name = itemName:lower()
	if name:find("high-medium armor", 1, true) then
		return 130
	elseif name:find("medium armor", 1, true) then
		return 100
	end
	return false
end
getgenv().getMaxArmor = getMaxArmor

local humanoidHealth = setmetatable({}, { __mode = "k" })
local lastHit = setmetatable({}, { __mode = "k" })

local shotQueue = {}
local function recordShot(handle, hitPart, shotTime)
	if typeof(hitPart) ~= "Instance" then return end

	local targetCharacter = getTargetCharacter(hitPart)
	local targetPlayer = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
	local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")

	if not (targetPlayer and targetPlayer ~= LocalPlayer and humanoid and humanoid.Health > 0) then
		return
	end

	local gunName = "Unknown"
	if typeof(handle) == "Instance" and handle.Parent then
		gunName = handle.Parent.Name
	end

	lastHit[humanoid] = {
		time = shotTime,
		playerName = targetPlayer.Name,
		gunName = gunName,
		bodyPartName = hitPart.Name,
	}
end
RunService.Heartbeat:Connect(function()
	if #shotQueue == 0 then return end

	local batch = shotQueue
	shotQueue = {}

	for _, shot in ipairs(batch) do
		recordShot(shot.handle, shot.hitPart, shot.time)
	end
end)

local function watchHumanoid(humanoid)
	if humanoidHealth[humanoid] ~= nil then
		return
	end

	humanoidHealth[humanoid] = humanoid.Health

	humanoid.HealthChanged:Connect(function(newHealth)
		local oldHealth = humanoidHealth[humanoid] or newHealth
		humanoidHealth[humanoid] = newHealth

		local damageDealt = oldHealth - newHealth
		local hit = lastHit[humanoid]

		if damageDealt > 0 and hit and (os.clock() - hit.time) <= 1.5 then
			lastHit[humanoid] = nil
			notifyHit(hit, damageDealt)
		end
	end)

	humanoid.Destroying:Once(function()
		humanoidHealth[humanoid] = nil
		lastHit[humanoid] = nil
	end)
end

local function watchCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	if humanoid then
		watchHumanoid(humanoid)
	end
end

local function watchPlayer(player)
	if player == LocalPlayer then return end

	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

local function runLoop(controlObj, loopFn, stopFn)
	local isKeybind = type(controlObj) == "string"
	local useHeartbeat = isKeybind and controlObj:sub(1, 1) == "!"
	local keybind = isKeybind and Options[useHeartbeat and controlObj:sub(2) or controlObj]

	if not isKeybind and controlObj.Value == nil then
		return
	end

	task.spawn(function()
		local wasActive = false

		while true do
			if isKeybind then
				if keybind:GetState() then
					loopFn()
				elseif stopFn then
					stopFn()
				end
			else
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
			end

			if useHeartbeat then
				RunService.Heartbeat:Wait()
			else
				task.wait()
			end
		end
	end)
end

-- builds the FindPlayerTo config from the shared targeting toggles, plus per-feature extras
local function targetingConfig(extra)
	local config = {
		FriendCheck = Toggles.TargetingFriendCheck.Value,
		CrewCheck = Toggles.TargetingCrewCheck.Value,
		WallCheck = Toggles.TargetingWallCheck.Value,
		KnockedCheck = Toggles.TargetingKnockedCheck.Value,
		LimitDistance = Toggles.TargetingLimitDistanceToggle.Value,
		MaxDistance = tonumber(Options.TargetingLimitDistance.Value),
		Whitelist = Options.TargetingWhitelist.Value,
	}
	if extra then
		for key, value in pairs(extra) do
			config[key] = value
		end
	end
	return config
end

-- shows/updates a Drawing circle pair created by createRadius(name) from the "<name>*" toggles/options
local function setupRadius(name)
	local outline = getgenv()[name]
	local fill = getgenv()[name .. "Fill"]

	local function hide()
		fill.Visible = false
		outline.Visible = false
	end

	runLoop(Toggles[name], function()
		local MouseLocation = UserInputService:GetMouseLocation()
		local MatchAccent = Toggles[name .. "MatchAccent"].Value
		local Radius = Options[name .. "Size"].Value

		outline.Position = MouseLocation
		outline.Radius = Radius
		outline.Color = MatchAccent and Library.AccentColor or Options[name .. "Color"].Value
		outline.Thickness = Options[name .. "Thickness"].Value

		fill.Position = MouseLocation
		fill.Radius = Radius
		fill.Color = MatchAccent and Library.AccentColor or Options[name .. "FillColor"].Value
		fill.Transparency = Options[name .. "Transparency"].Value

		fill.Visible = Toggles[name .. "Fill"].Value and true or false
		outline.Visible = true
	end, hide)

	Toggles[name]:OnChanged(function()
		if not Toggles[name].Value then
			hide()
		end
	end)
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
	local oldGetAim; oldGetAim = clonefunction(hookfunction(rawget(GunHandler, "getAim"), newcclosure(function(origin)
		if Toggles.SilentAimToggle.Value and typeof(origin) == "Vector3" then
			if LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") then
			
				local radiusSize = Toggles.SilentAimRadius.Value and SilentAimRadius.Radius
				
				SilentAimTarget = FindPlayerTo(radiusSize, targetingConfig({ Mouse = true }))
				
				if SilentAimTarget and SilentAimTarget.Character then
					local targetPart = getTargetPart(
						SilentAimTarget,
						Toggles.SilentAimClosestPart.Value and "Closest",
						Options.TargetingTargetPart.Value
					)
					if targetPart then
						local currentChance = tonumber(Options.SilentAimHitRate.Value)
						local roll = math.random(1, 100)
						
						if roll > currentChance then
							local maxMissOffset = 2.5 
							local randomOffset = Vector3.new(
								math.random(-100, 100) / 100 * maxMissOffset,
								math.random(-100, 100) / 100 * maxMissOffset,
								math.random(-100, 100) / 100 * maxMissOffset
							)
							
							local targetPosition = targetPart.Position + randomOffset
							local targetDirection = (targetPosition - origin).Unit
							return targetDirection, (targetPosition - origin).Magnitude
						end
						
						local targetDirection = (targetPart.Position - origin).Unit
						return targetDirection, (targetPart.Position - origin).Magnitude
					end
				end
			end
		end
		return oldGetAim(origin)
	end)))

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
	
		if self == MainEvent and method == "FireServer" then
			local eventType, handle, _, _, hitPart = ...
			if eventType == "ShootGun" then
				shotQueue[#shotQueue + 1] = { time = os.clock(), handle = handle, hitPart = hitPart }
			end
		end
	
		return oldNamecall(self, ...)
	end))

	-- MAIN EVENT CONNECTIONS
	MainEvent.OnClientEvent:Connect(function(...)
		if not Toggles.NotifyDamageToggle.Value then return end
	
		local args = {...}
		local eventType, shooter, weaponHandle, hitPart = args[1], args[2], args[3], args[6]
	
		if eventType ~= "ClientBullet" then return end
		if not (hitPart and LocalCharacter and hitPart:IsDescendantOf(LocalCharacter)) then return end
	
		local hit = {
			time = os.clock(),
			shooterName = shooter and shooter.Name or "Unknown Shooter",
			weaponName = weaponHandle and weaponHandle.Parent and weaponHandle.Parent.Name or "Unknown Weapon",
			partName = hitPart.Name,
		}
	
		local damage = popFresh(unclaimedDamage)
		if damage then
			notifyDamage(hit, damage.amount)
		else
			table.insert(pendingHits, hit)
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
		
	end,function()
		SilentAimTarget = nil
	end)

	local CameraTarget = nil
	runLoop("!CameraLockKey", function()
		local radiusSize = Toggles.CameraRadius.Value and CameraRadius.Radius
		local function findCameraTarget()
			return FindPlayerTo(radiusSize, targetingConfig({ Mouse = true }))
		end

		if not CameraTarget then
			CameraTarget = findCameraTarget()
		end

		if CameraTarget and CameraTarget.Character then
			local TargetHumanoid = CameraTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.TargetingKnockedCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				CameraTarget = findCameraTarget()
			end

			local targetPart = getTargetPart(
				CameraTarget,
				Toggles.CameraLockClosestPart.Value and "Closest",
				Options.TargetingTargetPart.Value
			)
			if targetPart then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
			end
		end
	end, function()
		CameraTarget = nil
	end)

	runLoop("GunTriggerBotKey", function()
		local Gun = getEquippedGun()
		if not Gun then
			return
		end

		local TargetHumanoid = Mouse.Target and getHumanoid(Mouse.Target)
		local TargetPlayer = TargetHumanoid and Players:GetPlayerFromCharacter(TargetHumanoid.Parent)

		local shouldFire = TargetHumanoid ~= nil
			and not (Toggles.GunTriggerBotKnockedCheck.Value and (TargetHumanoid.Health <= 0 or checkKnocked(TargetPlayer)))
			and not isWhitelisted(TargetPlayer, Options.TargetingWhitelist.Value)
			and not (TargetPlayer and Toggles.GunTriggerBotCrewCheck.Value and checkCrew(TargetPlayer))
			and not (TargetPlayer and Toggles.GunTriggerBotFriendCheck.Value and checkFriend(TargetPlayer))

		if shouldFire then
			Gun:Activate()
		else
			Gun:Deactivate()
		end
	end)

	local KillAuraTarget = nil
	runLoop("!KillAuraKey", function()
		local closestToMouse = Toggles.KillAuraClosestToMouse.Value
		KillAuraTarget = FindPlayerTo(math.huge, targetingConfig({
			Mouse = closestToMouse,
			Character = not closestToMouse,
		}))
		if KillAuraTarget and KillAuraTarget.Character then
			local targetPart = getTargetPart(
				KillAuraTarget,
				Toggles.KillAuraRandomHitPart.Value and "Random",
				Options.TargetingTargetPart.Value
			)
			if targetPart then
				local gun = getEquippedGun()
				if gun then
					local args = {
						[1] = "ShootGun",
						[2] = gun:WaitForChild("Handle"),
						[3] = LocalHumanoidRootPart.Position,
						[4] = targetPart.Position,
						[5] = targetPart,
						[6] = Vector3.zAxis
					}
					MainEvent:FireServer(unpack(args))
				end
			end
		end
	end, function()
		KillAuraTarget = nil
	end)

	runLoop(Toggles.GunAutoReload, function()
		local gun = getEquippedGun()
		if not gun then
			return
		end
		if not checkKnocked(LocalPlayer) and gun.Ammo.Value < 1 then
			MainEvent:FireServer("Reload",gun)
		end
	end)

	setupRadius("SilentAimRadius")
	setupRadius("CameraRadius")

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
		if checkKnocked(LocalPlayer) then
			if LocalCharacter then
				local LocalHead = LocalCharacter:FindFirstChild("Head")
				if LocalHead then
					LocalHead:Destroy()
				end
			end
		end
	end)

	-- MISC TAB
	runLoop(Toggles.AutoMaskToggle, function()
		if LocalHumanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.Viewer then return end

		local itemName = Options.AutoMaskItem.Value
		if not itemName or itemName == "" then return end

		local maskTool = findToolByName("[Mask]")
		if not maskTool then
			PurchaseItem(itemName, function(success, tool)
				maskTool = tool
			end)
		end
		if not maskTool then return end

		LocalHumanoid:EquipTool(maskTool)
		while LocalHumanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.Viewer and LocalHumanoid.Health > 0 and maskTool.Parent and Toggles.AutoMaskToggle.Value do
			task.wait()
			if maskTool.Parent == LocalCharacter then
				maskTool:Activate()
			else
				LocalHumanoid:EquipTool(maskTool)
			end
		end
		LocalHumanoid:UnequipTools()
	end)

	local armorPending = false
	runLoop(Toggles.AutoArmorToggle, function()
		if armorPending then return end

		local itemName = Options.AutoArmorItem.Value
		if not itemName or itemName == "" then return end

		local maxArmor = getMaxArmor(itemName)
		local armor = getLocalArmor()
		if not maxArmor or not armor then return end

		local needsArmor
		if Toggles.ArmorBuyOnDamageToggle.Value then
			needsArmor = armor < maxArmor
		else
			needsArmor = armor <= 0
		end
		if not needsArmor then return end

		armorPending = true
		PurchaseItem(itemName, function(success)
			if success then
				while LocalHumanoid.Health > 0 do
					local current = getLocalArmor()
					if not current or current > armor then break end
					task.wait()
				end
			end
			armorPending = false
		end)
	end)

	local reportConnection
	runLoop(Toggles.NotifyReportToggle, function()
		if not reportConnection then
			reportConnection = LocalDataFolder:WaitForChild("Reporters").ChildAdded:Connect(function(child)
				if child and child.Value ~= "" then
					Library:Notify(child.Value.." reported you", tonumber(Options.NotifyReportDuration.Value))
				end
			end)
		end
	end, function()
		if reportConnection then
			reportConnection:Disconnect()
		end
	end)
end

return Logic
