local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = nil
local LocalHumanoid = nil
local LocalHumanoidRootPart = nil

local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

getgenv().NotificationTime = 3

local function createRadius(name)
	local outline = Drawing.new("Circle")
	local fill = Drawing.new("Circle")
	fill.Thickness = 0
	fill.Filled = true
	getgenv()[name] = outline
	getgenv()[name .. "Fill"] = fill
end
createRadius("SilentAimRadius")
createRadius("CameraRadius")

local function Setup(newCharacter)
	LocalCharacter = newCharacter
	LocalHumanoid = newCharacter:WaitForChild("Humanoid")
	LocalHumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(Setup)
Setup(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end
getgenv().getDirection = getDirection

local function checkFriend(target)
	return LocalPlayer:IsFriendsWith(target.UserId)
end
getgenv().checkFriend = checkFriend

local function checkTeam(target)
	return target.Team == LocalPlayer.Team
end
getgenv().checkTeam = checkTeam

local function FindBestMatch(Query, Names)
	Query = Query:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if Query == "" then return nil end

	local BestName, BestScore = nil, 0

	for _, Name in ipairs(Names) do
		local Lower = Name:lower()
		local Score = 0

		if Lower == Query then
			Score = 1000 -- exact match
		elseif Lower:sub(1, #Query) == Query then
			Score = 800 - (#Lower - #Query)
		elseif Lower:find(Query, 1, true) then
			Score = 600 - (#Lower - #Query)
		else
			local QueryIndex = 1
			for i = 1, #Lower do
				if Lower:sub(i, i) == Query:sub(QueryIndex, QueryIndex) then
					QueryIndex += 1
					if QueryIndex > #Query then break end
				end
			end
			if QueryIndex > #Query then
				Score = 300 - (#Lower - #Query)
			end
		end

		if Score > BestScore then
			BestScore = Score
			BestName = Name
		end
	end

	return BestName
end
getgenv().FindBestMatch = FindBestMatch

local function getEquippedTool(filter)
	if not LocalCharacter then
		return false
	end
	for _, object in ipairs(LocalCharacter:GetChildren()) do
		if object:IsA("Tool") and (not filter or filter(object)) then
			return object
		end
	end
	return false
end
getgenv().getEquippedTool = getEquippedTool

local function getEquippedGun()
	return getEquippedTool(function(tool)
		return tool:FindFirstChild("Ammo") ~= nil and tool:FindFirstChild("MaxAmmo") ~= nil
	end)
end
getgenv().getEquippedGun = getEquippedGun

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

local function getBodyEffect(character, name)
	local effects = character and character:FindFirstChild("BodyEffects")
	return effects and effects:FindFirstChild(name) or nil
end
getgenv().getBodyEffect = getBodyEffect

local function checkKnocked(target)
	if typeof(target) ~= "Instance" then
		return false
	end
	local character = target:IsA("Player") and target.Character or target
	local KO = getBodyEffect(character, "K.O")
	return KO ~= nil and KO.Value == true
end
getgenv().checkKnocked = checkKnocked

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

-- whitelist can be { "name", ... } and/or { name = true, ... }
local function buildWhitelistSet(whitelist)
	local set = {}
	if type(whitelist) == "table" then
		for key, value in pairs(whitelist) do
			if type(value) == "string" then
				set[value:lower()] = true
			elseif value == true and type(key) == "string" then
				set[key:lower()] = true
			end
		end
	end
	return set
end
getgenv().buildWhitelistSet = buildWhitelistSet

local function isWhitelisted(player, whitelist)
	return player ~= nil and buildWhitelistSet(whitelist)[player.Name:lower()] == true
end
getgenv().isWhitelisted = isWhitelisted

local function FindPlayerTo(radius, configurations)
	if not LocalHumanoidRootPart then
		return false
	end

	local useCharacter = configurations.Character and not configurations.Mouse
	local whitelistSet = buildWhitelistSet(configurations.Whitelist)

	local ClosestPlayer = nil
	local ShortestDistance = math.huge
	local MyPosition = LocalHumanoidRootPart.Position
	local MousePos = Vector2.new(Mouse.X, Mouse.Y)

	local MaxDistance
	if configurations.LimitDistance then
		MaxDistance = configurations.MaxDistance
		if not MaxDistance then
			local options = getgenv().Options or _G.Options
			MaxDistance = tonumber(options.TargetingLimitDistance.Value)
		end
	end

	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= LocalPlayer and target.Character and not whitelistSet[target.Name:lower()] then
			local targetRootPart = target.Character:FindFirstChild("HumanoidRootPart")
			local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")

			if targetRootPart and targetHumanoid then
				if configurations.FriendCheck and checkFriend(target) then
					continue
				end

				if configurations.TeamCheck and checkTeam(target) then
					continue
				end

				if configurations.CrewCheck and checkCrew(target) then
					continue
				end

				if configurations.WallCheck and checkWall(target) then
					continue
				end

				if (configurations.KnockedCheck or configurations.DeadCheck) and targetHumanoid.Health <= 0 then
					continue
				end

				if configurations.KnockedCheck and checkKnocked(target) then
					continue
				end

				local worldDistance = (targetRootPart.Position - MyPosition).Magnitude
				if MaxDistance and worldDistance > MaxDistance then
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

local function FindPlayerToMouse(radius, configurations)
	configurations = table.clone(configurations or {})
	configurations.Mouse = true
	return FindPlayerTo(radius, configurations)
end
getgenv().FindPlayerToMouse = FindPlayerToMouse

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
getgenv().getTargetCharacter = getTargetCharacter

local function getRandomHitPart(targetCharacter)
	local Parts = {}

	for _, part in ipairs(targetCharacter:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(Parts, part)
		end
	end

	if #Parts == 0 then
		return nil
	end

	return Parts[math.random(1, #Parts)]
end
getgenv().getRandomHitPart = getRandomHitPart

local function getClosestPartToMouse(player)
    local character = player and player.Character
    if not character then
        return nil
    end
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local closestPart = nil
    local shortestDistance = math.huge

    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPart = part
                end
            end
        end
    end
    return closestPart
end
getgenv().getClosestPartToMouse = getClosestPartToMouse

local function getTargetPart(player, mode, partName)
	local character = player and player.Character
	if not character then
		return nil
	end

	if mode == "Closest" then
		return getClosestPartToMouse(player)
	elseif mode == "Random" then
		return getRandomHitPart(character)
	end

	return character:FindFirstChild(partName)
end
getgenv().getTargetPart = getTargetPart

local function findToolByName(name)
	local needle = (name:match("%[.-%]") or name):lower()
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	for _, container in ipairs({ LocalCharacter, backpack }) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool.Name:lower():find(needle, 1, true) then
					return tool
				end
			end
		end
	end
	return nil
end
getgenv().findToolByName = findToolByName

local function searchForTool(name)
	return findToolByName(name) ~= nil
end
getgenv().searchForTool = searchForTool
