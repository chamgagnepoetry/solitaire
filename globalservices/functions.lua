local Players = game:GetService("Players")

getgenv().LocalPlayer = Players.LocalPlayer
getgenv().LocalCharacter = nil
getgenv().LocalHumanoid = nil
getgenv().LocalHumanoidRootPart = nil

getgenv().NotificationTime = 3

getgenv().SilentAimRadiusFill = Drawing.new("Circle")
getgenv().SilentAimRadius = Drawing.new("Circle")
getgenv().SilentAimRadiusFill.Thickness = 0
getgenv().SilentAimRadiusFill.Filled = true

getgenv().CameraRadiusFill = Drawing.new("Circle")
getgenv().CameraRadius = Drawing.new("Circle")
getgenv().CameraRadiusFill.Thickness = 0
getgenv().CameraRadiusFill.Filled = true

getgenv().MouseRadiusFill = Drawing.new("Circle")
getgenv().MouseRadius = Drawing.new("Circle")
getgenv().MouseRadiusFill.Thickness = 0
getgenv().MouseRadiusFill.Filled = true

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

				if configurations.TeamCheck and checkTeam(target) then
					continue
				end

				if configurations.WallCheck and checkWall(target) then
					continue
				end

				if configurations.DeadCheck and targetHumanoid.Health <= 0 then
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
