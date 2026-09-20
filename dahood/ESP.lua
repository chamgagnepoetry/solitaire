print('upodatedd')
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local HeadOff = Vector3.new(0, 0.5, 0)
local LegOff = Vector3.new(0, 3, 0)

local BoxWidthRatio = 0.5 -- box width as a fraction of box height; raise this to make the box wider
local MaxArmor = 130 -- max armor value (same as your old code)
local BarGap = 4 -- gap between the box, health bar and armor bar

local Style = {
	Box = {
		Thickness = 1,
		Transparency = 1,

		OutlineThickness = 3,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		OutlineTransparency = 1
	},

	Name = {
		Size = 13,
		Center = true,
		Font = 2,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Transparency = 1
	},

	Distance = {
		Size = 13,
		Center = true,
		Font = 2,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Transparency = 1
	},

	Weapon = {
		Size = 13,
		Center = true,
		Font = 2,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Transparency = 1
	},

	Health = {
		BackgroundColor = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.15,

		OutlineColor = Color3.fromRGB(0, 0, 0),
		OutlineThickness = 1.5,

		Width = 4,
		BackgroundWidth = 6,
		Padding = 1
	},

	Armor = {
		BackgroundColor = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.15,

		OutlineColor = Color3.fromRGB(0, 0, 0),
		OutlineThickness = 1.5,

		Width = 4,
		BackgroundWidth = 6,
		Padding = 1
	}
}

local ESP = {}
local Data = {}

local Toggles, Options, Library

local function checkTeam(target)
	return target.Team == LocalPlayer.Team
end

local function ApplyStyle(Object, StyleProperties)
	for Property, Value in pairs(StyleProperties) do
		pcall(function()
			Object[Property] = Value
		end)
	end
end

local function GetHealthColor(HealthPercent)
	HealthPercent = math.clamp(HealthPercent, 0, 1)

	local HealthColor = Options.ESPHealthUpperColor.Value
	local MidColor = Options.ESPHealthMidColor.Value
	local LowColor = Options.ESPHealthLowerColor.Value

	if HealthPercent >= 0.5 then
		local Alpha = (HealthPercent - 0.5) * 2
		return Color3.new(
			MidColor.R + (HealthColor.R - MidColor.R) * Alpha,
			MidColor.G + (HealthColor.G - MidColor.G) * Alpha,
			MidColor.B + (HealthColor.B - MidColor.B) * Alpha
		)
	end

	local Alpha = HealthPercent * 2
	return Color3.new(
		LowColor.R + (MidColor.R - LowColor.R) * Alpha,
		LowColor.G + (MidColor.G - LowColor.G) * Alpha,
		LowColor.B + (MidColor.B - LowColor.B) * Alpha
	)
end

local function GetArmorColor(ArmorPercent)
	ArmorPercent = math.clamp(ArmorPercent, 0, 1)

	local ArmorColor = Options.ESPArmorUpperColor.Value
	local MidColor = Options.ESPArmorMidColor.Value
	local LowColor = Options.ESPArmorLowerColor.Value

	if ArmorPercent >= 0.5 then
		local Alpha = (ArmorPercent - 0.5) * 2
		return Color3.new(
			MidColor.R + (ArmorColor.R - MidColor.R) * Alpha,
			MidColor.G + (ArmorColor.G - MidColor.G) * Alpha,
			MidColor.B + (ArmorColor.B - MidColor.B) * Alpha
		)
	end

	local Alpha = ArmorPercent * 2
	return Color3.new(
		LowColor.R + (MidColor.R - LowColor.R) * Alpha,
		LowColor.G + (MidColor.G - LowColor.G) * Alpha,
		LowColor.B + (MidColor.B - LowColor.B) * Alpha
	)
end

local function GetEquippedToolName(Character)
	local Tool = Character:FindFirstChildOfClass("Tool")
	return Tool and Tool.Name or nil
end

local function HideESP(EspData)
	for _, Object in pairs(EspData) do
		if Object then
			Object.Visible = false
		end
	end
end

local function CreateESP(Player)
	if Data[Player] then
		return
	end

	local EspData = {
		BoxOutline = Drawing.new("Square"),
		Box = Drawing.new("Square"),

		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Weapon = Drawing.new("Text"),

		HealthBackground = Drawing.new("Square"),
		Health = Drawing.new("Square"),
		HealthOutline = Drawing.new("Square"),

		ArmorBackground = Drawing.new("Square"),
		Armor = Drawing.new("Square"),
		ArmorOutline = Drawing.new("Square")
	}

	ApplyStyle(EspData.BoxOutline, Style.Box)
	ApplyStyle(EspData.Box, Style.Box)

	ApplyStyle(EspData.Name, Style.Name)
	ApplyStyle(EspData.Distance, Style.Distance)
	ApplyStyle(EspData.Weapon, Style.Weapon)

	EspData.HealthBackground.Filled = true
	EspData.HealthBackground.Transparency = Style.Health.BackgroundTransparency
	EspData.HealthBackground.Color = Style.Health.BackgroundColor

	EspData.Health.Filled = true
	EspData.Health.Transparency = 1

	EspData.HealthOutline.Filled = false
	EspData.HealthOutline.Thickness = Style.Health.OutlineThickness
	EspData.HealthOutline.Transparency = 1
	EspData.HealthOutline.Color = Style.Health.OutlineColor

	EspData.ArmorBackground.Filled = true
	EspData.ArmorBackground.Transparency = Style.Armor.BackgroundTransparency
	EspData.ArmorBackground.Color = Style.Armor.BackgroundColor

	EspData.Armor.Filled = true
	EspData.Armor.Transparency = 1

	EspData.ArmorOutline.Filled = false
	EspData.ArmorOutline.Thickness = Style.Armor.OutlineThickness
	EspData.ArmorOutline.Transparency = 1
	EspData.ArmorOutline.Color = Style.Armor.OutlineColor

	Data[Player] = EspData
end

local function RemoveESP(Player)
	local EspData = Data[Player]
	if not EspData then
		return
	end

	for _, Object in pairs(EspData) do
		if Object then
			pcall(function()
				Object:Remove()
			end)
		end
	end

	Data[Player] = nil
end

local function UpdateESP(Player, EspData)
	if Toggles.ESPCrewCheck.Value and checkCrew(Player) then
		HideESP(EspData)
		return
	end

	local Character = Player.Character
	if not Character then
		HideESP(EspData)
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	local Head = Character:FindFirstChild("Head")

	-- optional: may not be loaded yet after a respawn, so it must not stop the rest of the ESP
	local BodyEffects = Character:FindFirstChild("BodyEffects")

	if not Humanoid or not RootPart or not Head then
		HideESP(EspData)
		return
	end

	local RootPosition, RootVisible = Camera:WorldToViewportPoint(RootPart.Position)
	local HeadPosition = Camera:WorldToViewportPoint(Head.Position + HeadOff)
	local LegPosition = Camera:WorldToViewportPoint(RootPart.Position - LegOff)

	if not RootVisible or RootPosition.Z <= 0 then
		HideESP(EspData)
		return
	end

	local TopY = HeadPosition.Y
	local BottomY = LegPosition.Y
	local CenterX = RootPosition.X

	local CharacterHeight = BottomY - TopY

	if CharacterHeight <= 0 then
		HideESP(EspData)
		return
	end

	local CharacterWidth = CharacterHeight * BoxWidthRatio
	local BoxSize = Vector2.new(CharacterWidth, CharacterHeight)
	local BoxPosition = Vector2.new(CenterX - CharacterWidth / 2, TopY)

	-- BOX
	if Toggles.ESPBox.Value then
		EspData.BoxOutline.Size = BoxSize
		EspData.BoxOutline.Position = BoxPosition
		EspData.BoxOutline.Color = Style.Box.OutlineColor
		EspData.BoxOutline.Thickness = Style.Box.OutlineThickness
		EspData.BoxOutline.Transparency = Style.Box.OutlineTransparency
		EspData.BoxOutline.Visible = Toggles.ESPBoxOutline.Value

		EspData.Box.Size = BoxSize
		EspData.Box.Position = BoxPosition
		EspData.Box.Color = Options.ESPBoxColor.Value
		EspData.Box.Thickness = Style.Box.Thickness
		EspData.Box.Transparency = Style.Box.Transparency
		EspData.Box.Visible = true
	else
		EspData.Box.Visible = false
		EspData.BoxOutline.Visible = false
	end

	-- NAME
	if Toggles.ESPName.Value then
		local NameType = Options.ESPNametype.Value
		EspData.Name.Text = (NameType == "displayname") and Player.DisplayName or Player.Name
		EspData.Name.Position = Vector2.new(CenterX, TopY - 6)
		EspData.Name.Color = Options.ESPNameColor.Value
		EspData.Name.Outline = Toggles.ESPNameOutline.Value
		EspData.Name.Visible = true
	else
		EspData.Name.Visible = false
	end

	-- DISTANCE
	local LocalCharacter = LocalPlayer.Character
	local LocalRoot = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")

	local DistanceShown = false
	if Toggles.ESPDistance.Value and LocalRoot then
		local Distance = (LocalRoot.Position - RootPart.Position).Magnitude
		EspData.Distance.Text = string.format("%d studs", math.floor(Distance + 0.5))
		EspData.Distance.Color = Options.ESPDistanceColor.Value
		EspData.Distance.Outline = Toggles.ESPDistanceOutline.Value

		DistanceShown = true
	else
		EspData.Distance.Visible = false
	end

	-- WEAPON
	local WeaponShown = false
	if Toggles.ESPWeapon.Value then
		local WeaponName = GetEquippedToolName(Character)
		if WeaponName then
			EspData.Weapon.Text = "[" .. WeaponName .. "]"
			EspData.Weapon.Color = Options.ESPWeaponColor.Value
			EspData.Weapon.Outline = Toggles.ESPWeaponOutline.Value

			WeaponShown = true
		else
			EspData.Weapon.Visible = false
		end
	else
		EspData.Weapon.Visible = false
	end

	local TextGap = 3
	local TextSpacing = 2
	if WeaponShown and DistanceShown then
		EspData.Weapon.Position = Vector2.new(CenterX, BottomY + TextGap)
		EspData.Weapon.Visible = true

		EspData.Distance.Position = Vector2.new(CenterX, BottomY + TextGap + EspData.Weapon.Size + TextSpacing)
		EspData.Distance.Visible = true
	elseif WeaponShown then
		EspData.Weapon.Position = Vector2.new(CenterX, BottomY + TextGap)
		EspData.Weapon.Visible = true
	elseif DistanceShown then
		EspData.Distance.Position = Vector2.new(CenterX, BottomY + TextGap)
		EspData.Distance.Visible = true
	end

	-- BARS: stack outward from the box. Health first, then armor to its left.
	-- If health is off, armor takes health's spot.
	local NextBarRight = CenterX - CharacterWidth / 2 - BarGap

	-- HEALTH
	if Toggles.ESPHealth.Value then
		local Health = Humanoid.Health
		local MaxHealth = Humanoid.MaxHealth
		local HealthPercent = 0

		if MaxHealth > 0 then
			HealthPercent = math.clamp(Health / MaxHealth, 0, 1)
		end

		local BackgroundWidth = Style.Health.BackgroundWidth
		local HealthWidth = Style.Health.Width
		local Padding = Style.Health.Padding
		local HealthX = NextBarRight - BackgroundWidth

		EspData.HealthBackground.Position = Vector2.new(HealthX, TopY)
		EspData.HealthBackground.Size = Vector2.new(BackgroundWidth, CharacterHeight)
		EspData.HealthBackground.Visible = true

		local InnerHeight = math.max(CharacterHeight - Padding * 2, 0)
		local HealthHeight = InnerHeight * HealthPercent
		local HealthXInner = HealthX + (BackgroundWidth - HealthWidth) / 2
		local HealthY = TopY + Padding + InnerHeight - HealthHeight

		EspData.Health.Position = Vector2.new(HealthXInner, HealthY)
		EspData.Health.Size = Vector2.new(HealthWidth, HealthHeight)
		EspData.Health.Color = GetHealthColor(HealthPercent)
		EspData.Health.Visible = true

		EspData.HealthOutline.Position = Vector2.new(HealthXInner, TopY + Padding)
		EspData.HealthOutline.Size = Vector2.new(HealthWidth, InnerHeight)
		EspData.HealthOutline.Visible = true

		NextBarRight = HealthX - BarGap -- armor goes left of this
	else
		EspData.HealthBackground.Visible = false
		EspData.Health.Visible = false
		EspData.HealthOutline.Visible = false
	end

	-- ARMOR
	local ArmorObject = BodyEffects and BodyEffects:FindFirstChild("Armor")

	if Toggles.ESPArmor.Value and ArmorObject then
		local ArmorPercent = math.clamp(ArmorObject.Value / MaxArmor, 0, 1)

		local BackgroundWidth = Style.Armor.BackgroundWidth
		local ArmorWidth = Style.Armor.Width
		local Padding = Style.Armor.Padding
		local ArmorX = NextBarRight - BackgroundWidth

		EspData.ArmorBackground.Position = Vector2.new(ArmorX, TopY)
		EspData.ArmorBackground.Size = Vector2.new(BackgroundWidth, CharacterHeight)
		EspData.ArmorBackground.Visible = true

		local InnerHeight = math.max(CharacterHeight - Padding * 2, 0)
		local ArmorHeight = InnerHeight * ArmorPercent
		local ArmorXInner = ArmorX + (BackgroundWidth - ArmorWidth) / 2
		local ArmorY = TopY + Padding + InnerHeight - ArmorHeight

		EspData.Armor.Position = Vector2.new(ArmorXInner, ArmorY)
		EspData.Armor.Size = Vector2.new(ArmorWidth, ArmorHeight)
		EspData.Armor.Color = GetArmorColor(ArmorPercent)
		EspData.Armor.Visible = true

		EspData.ArmorOutline.Position = Vector2.new(ArmorXInner, TopY + Padding)
		EspData.ArmorOutline.Size = Vector2.new(ArmorWidth, InnerHeight)
		EspData.ArmorOutline.Visible = true
	else
		EspData.ArmorBackground.Visible = false
		EspData.Armor.Visible = false
		EspData.ArmorOutline.Visible = false
	end
end

function ESP:Initialize(SharedRefs)
	Toggles = SharedRefs.Toggles
	Options = SharedRefs.Options
	Library = SharedRefs.Library

	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			CreateESP(Player)
		end
	end

	Players.PlayerAdded:Connect(function(Player)
		if Player ~= LocalPlayer then
			CreateESP(Player)
		end
	end)

	Players.PlayerRemoving:Connect(RemoveESP)

	RunService.RenderStepped:Connect(function()
		for Player, EspData in pairs(Data) do
			if Player.Parent == Players then
				UpdateESP(Player, EspData)
			else
				RemoveESP(Player)
			end
		end
	end)
end

return ESP
