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

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end
getgenv().ValidateArguments = ValidateArguments

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
