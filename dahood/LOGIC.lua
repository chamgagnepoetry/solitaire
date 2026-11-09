print("yo ur gay and ur gay")
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

local function purgeOwnedFromQueue()
	for i = #PurchaseQueue, 1, -1 do
		local Entry = PurchaseQueue[i]
		local Bracketed = Entry.Item.Name:match("%[.-%]")
		local IsAmmoOrArmor = Entry.Item.Name:find("Ammo") or Entry.Item.Name:find("Armor")
		local Owned = not IsAmmoOrArmor and Bracketed and findToolByName(Bracketed)
		if Owned then
			table.remove(PurchaseQueue, i)
			if Entry.Callback then
				task.spawn(Entry.Callback, false, Owned)
			end
		end
	end
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
		if not LocalHumanoid or LocalHumanoid.Health <= 0 then
			return false
		end

		if not Item or not Item.Parent or not Item:FindFirstChild("Head") or not Item:FindFirstChild("ClickDetector") or LocalCurrency.Value < Item.Price.Value then
			return false
		end

		local ValueBefore = LocalCurrency.Value

		LocalHumanoidRootPart.CFrame = Item.Head.CFrame
		fireclickdetector(Item.ClickDetector,0)
		task.wait()
		if LocalCurrency.Value < ValueBefore then
			return true
		end
	end
end

local function waitForBoughtTool(Item)
	local Bracketed = Item.Name:match("%[.-%]")
	if not Bracketed or Item.Name:find("Ammo") or Item.Name:find("Armor") then
		return nil
	end

	local tool = findToolByName(Bracketed)
	while not tool and LocalHumanoid.Health > 0 do
		task.wait()
		tool = findToolByName(Bracketed)
	end
	return tool
end

local function ProcessQueue()
	if IsProcessing then return end
	IsProcessing = true

	local HRP = LocalHumanoidRootPart
	local OriginalCFrame = HRP.CFrame

	while #PurchaseQueue > 0 do
		purgeOwnedFromQueue()
		if #PurchaseQueue == 0 then break end

		local Entry = table.remove(PurchaseQueue, 1)

		local ok, result = pcall(TryPurchase, Entry.Item)
		if not ok then
			warn("purchase error:", result)
		end
		local success = ok and result == true

		if Entry.Callback then
			task.spawn(function()
				local tool = nil
				if success then
					tool = waitForBoughtTool(Entry.Item)
				end
				Entry.Callback(success, tool)
			end)
		end
	end

	if HRP.Parent then
		HRP.CFrame = OriginalCFrame
	end
	IsProcessing = false
end

local function PurchaseItem(Name, Callback)
	for _, Item in ipairs(IgnoredShop) do
		if Item.Name == Name then
			table.insert(PurchaseQueue, { Item = Item, Callback = Callback })
			task.spawn(ProcessQueue)
			return
		end
	end
	if Callback then
		task.spawn(Callback, false, nil)
	end
end
getgenv().PurchaseItem = PurchaseItem

local function checkLocalPlayerKnocked()
	local bodyEffects = LocalCharacter and LocalCharacter:FindFirstChild("BodyEffects")
	local KO = bodyEffects and bodyEffects:FindFirstChild("K.O")

	return KO ~= nil and KO.Value == true
end
getgenv().checkLocalPlayerKnocked = checkLocalPlayerKnocked

local function checkCrew(target, crewid)
	local function getCrew(player)
		local data = player:FindFirstChild("DataFolder")
		local info = data and data:FindFirstChild("Information")
		local crew = info and info:FindFirstChild("Crew")
		return crew and crew.Value or ""
	end

	local theirCrew = getCrew(target)

	if theirCrew == "" then
		return false
	end
	if crewid ~= nil then
		return tostring(theirCrew) == tostring(crewid)
	end

	local ourCrew = getCrew(LocalPlayer)
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

local function FindPlayerTo(radius, configurations)
	if not LocalHumanoidRootPart then
		return false
	end

	local useCharacter = configurations.Character and not configurations.Mouse

	local whitelistSet = {}
	if configurations.Whitelist then
		for key, value in pairs(configurations.Whitelist) do
			if type(value) == "string" then
				whitelistSet[value:lower()] = true
			elseif value == true and type(key) == "string" then
				whitelistSet[key:lower()] = true
			end
		end
	end

	local ClosestPlayer = nil
	local ShortestDistance = math.huge
	local MyPosition = LocalHumanoidRootPart.Position
	local MousePos = Vector2.new(Mouse.X, Mouse.Y)

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= LocalPlayer and target.Character then
			if whitelistSet[target.Name:lower()] then
				continue
			end
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

				local worldDistance = (targetRootPart.Position - MyPosition).Magnitude
				if configurations.LimitDistance and worldDistance > tonumber(Options.TargetingLimitDistance.Value) then
					continue
				end

				local distance
				if useCharacter then
					distance = worldDistance
				else
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetRootPart.Position)
					if not onScreen then
						continue
					end
					distance = (Vector2.new(screenPos.X, screenPos.Y) - MousePos).Magnitude
				end
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
	return ClosestPlayer
end
getgenv().FindPlayerTo = FindPlayerTo

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

local function getLocalArmor()
	local bodyEffects = LocalCharacter and LocalCharacter:FindFirstChild("BodyEffects")
	local armor = bodyEffects and bodyEffects:FindFirstChild("Armor")
	if armor then 
		return armor.Value
	else
		return false
	end
	return false
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

local function getTargetCharacter(part)
	local current = part
	while current and current ~= workspace and current ~= game do
		if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
			return current
		end
		current = current.Parent
	end
	return nil
end

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

	local SilentAimTarget = nil
	local oldGetAim; oldGetAim = clonefunction(hookfunction(rawget(GunHandler, "getAim"), newcclosure(function(origin)
		if Toggles.SilentAimToggle.Value and typeof(origin) == "Vector3" then
			if LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") then
			
				local radiusSize = Toggles.SilentAimRadius.Value and SilentAimRadius.Radius
				
				SilentAimTarget = FindPlayerTo(radiusSize, {
					Mouse = true,
					FriendCheck = Toggles.TargetingFriendCheck.Value,
					CrewCheck = Toggles.TargetingCrewCheck.Value,
					WallCheck = Toggles.TargetingWallCheck.Value,
					KnockedCheck = Toggles.TargetingKnockedCheck.Value,
					LimitDistance = Toggles.TargetingLimitDistanceToggle.Value,
					Whitelist = Options.TargetingWhitelist.Value
				})
				
				if SilentAimTarget and SilentAimTarget.Character then
					local targetPart
					if not Toggles.SilentAimClosestPart.Value then
						targetPart = SilentAimTarget.Character:FindFirstChild(Options.TargetingTargetPart.Value)
					else
						targetPart = getClosestPartToMouse(SilentAimTarget)
					end
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
		if not CameraTarget then
			CameraTarget = FindPlayerTo(radiusSize, {
				Mouse = true,
				FriendCheck = Toggles.TargetingFriendCheck.Value,
				CrewCheck = Toggles.TargetingCrewCheck.Value,
				WallCheck = Toggles.TargetingWallCheck.Value,
				KnockedCheck = Toggles.TargetingKnockedCheck.Value,
				LimitDistance = Toggles.TargetingLimitDistanceToggle.Value,
				Whitelist = Options.TargetingWhitelist.Value
			})
		end

		if CameraTarget and CameraTarget.Character then
			local TargetHumanoid = CameraTarget.Character:FindFirstChildOfClass("Humanoid")
			if Toggles.TargetingKnockedCheck.Value and (not TargetHumanoid or TargetHumanoid.Health <= 0) then
				CameraTarget = FindPlayerTo(radiusSize, {
					Mouse = true,
					FriendCheck = Toggles.TargetingFriendCheck.Value,
					CrewCheck = Toggles.TargetingCrewCheck.Value,
					WallCheck = Toggles.TargetingWallCheck.Value,
					KnockedCheck = Toggles.TargetingKnockedCheck.Value,
					LimitDistance = Toggles.TargetingLimitDistanceToggle.Value,
					Whitelist = Options.TargetingWhitelist.Value
				})
			end

			if CameraTarget and CameraTarget.Character then
				local targetPart
					if not Toggles.CameraLockClosestPart.Value then
						targetPart = CameraTarget.Character:FindFirstChild(Options.TargetingTargetPart.Value)
					else
						targetPart = getClosestPartToMouse(CameraTarget)
					end
				if targetPart then
					Camera.CFrame = CFrame.new(
						Camera.CFrame.Position,
						targetPart.Position
					)
				end
			end
		end
	end, function()
		CameraTarget = nil
	end)

	local function isWhitelisted(player)
		local whitelist = Options.TargetingWhitelist.Value
		if not player or type(whitelist) ~= "table" then
			return false
		end

		local name = player.Name:lower()
		for key, value in pairs(whitelist) do
			if type(value) == "string" then
				if value:lower() == name then
					return true
				end
			elseif value == true and type(key) == "string" then
				if key:lower() == name then
					return true
				end
			end
		end

		return false
	end

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
	
		if isWhitelisted(TargetPlayer) then
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

	local KillAuraTarget = nil
	runLoop("!KillAuraKey", function()
		local closestToMouse = Toggles.KillAuraClosestToMouse.Value
		KillAuraTarget = FindPlayerTo(math.huge, {
			Mouse = closestToMouse,
			Character = not closestToMouse,
			FriendCheck = Toggles.TargetingFriendCheck.Value,
			CrewCheck = Toggles.TargetingCrewCheck.Value,
			WallCheck = Toggles.TargetingWallCheck.Value,
			KnockedCheck = Toggles.TargetingKnockedCheck.Value,
			LimitDistance = Toggles.TargetingLimitDistanceToggle.Value,
			Whitelist = Options.TargetingWhitelist.Value
		})
		if KillAuraTarget and KillAuraTarget.Character then
			local targetPart
			if not Toggles.KillAuraRandomHitPart.Value then
				targetPart = KillAuraTarget.Character:FindFirstChild(Options.TargetingTargetPart.Value)
			else
				targetPart = getRandomHitPart(KillAuraTarget.Character)
			end
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
	local maskPending = false
	runLoop(Toggles.AutoMaskToggle, function()
		if maskPending then return end
		if LocalHumanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.Viewer then return end

		local itemName = Options.AutoMaskItem.Value
		if not itemName or itemName == "" then return end

		local maskTool = findToolByName(itemName)
		if not maskTool then
			print('no mask tool gang')
			maskPending = true
			PurchaseItem(itemName, function(success, tool)
				maskPending = false
			end)
			return
		end
		print("yo")

		LocalHumanoid:EquipTool(maskTool)
		while LocalHumanoid.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.Viewer and LocalHumanoid.Health > 0 do
			task.wait()
			print("activating")
			maskTool:Activate()
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
end

return Logic
