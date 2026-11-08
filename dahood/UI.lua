local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local generalChannel = TextChatService:FindFirstChild("RBXGeneral", true)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chamgagnepoetry/VantaLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/chamgagnepoetry/VantaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/chamgagnepoetry/VantaLib/refs/heads/main/addons/SaveManager.lua"))()

local IgnoredShopNames = {}
for i,v in ipairs(workspace.Ignored.Shop:GetChildren()) do
	if v:IsA("Model") and v:GetAttribute("itemlol") and not table.find(IgnoredShopNames,v.Name) then
		table.insert(IgnoredShopNames,v.Name)
	end
end

local UI = {}

function UI:Initialize()
    local Window = Library:CreateWindow({
        Title = "SOLITAIRE";
		SubTitle = "dahood";
        Centre = true;
        AutoShow = true;
        TabPadding = 12;
        MenuFadeTime = 0;
    })

    local Tabs = {
        Main = Window:AddTab("main");
        Character = Window:AddTab("character");
		ESP = Window:AddTab("esp");
		Visuals = Window:AddTab("visuals");
		Misc = Window:AddTab("misc");
        Settings = Window:AddTab("settings");
    }

    -- \\MAIN TAB//
	local AimTabBox = Tabs.Main:AddLeftTabbox("aim")
	local TargetingGroupBox = Tabs.Main:AddLeftGroupbox("targeting")
    local GunTabBox = Tabs.Main:AddRightTabbox("gun")
	local ExploitsGroupBox = Tabs.Main:AddRightGroupbox("exploits")


	local SilentAimTab = AimTabBox:AddTab("silent aim")
	SilentAimTab:AddToggle("SilentAimToggle", {
        Text = "silent aim"
    })
	local SilentAimDepBox = SilentAimTab:AddDependencyBox()
	SilentAimDepBox:SetupDependencies({
		{Toggles.SilentAimToggle, true}
	})
	SilentAimDepBox:AddSlider("SilentAimHitRate",{
		Text = "hit rate";
		Default = 100;
		Min = 1;
		Max = 100;
		Rounding = 0;
		Compact = true;
		Suffix = "%";
	})
	SilentAimDepBox:AddToggle("SilentAimClosestPart", {
        Text = "closest part"
    })
	SilentAimDepBox:AddToggle("SilentAimRadius",{
		Text = "radius"
	}):AddColorPicker("SilentAimRadiusColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	local SilentAimRadiusDepBox = SilentAimDepBox:AddDependencyBox()
	SilentAimRadiusDepBox:SetupDependencies({
		{Toggles.SilentAimRadius, true}
	})
	SilentAimRadiusDepBox:AddToggle("SilentAimRadiusFill",{
		Text = "fill"
	}):AddColorPicker("SilentAimRadiusFillColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	SilentAimRadiusDepBox:AddToggle("SilentAimRadiusMatchAccent",{
		Text = "match accent"
	})
	SilentAimRadiusDepBox:AddSlider("SilentAimRadiusSize",{
		Text = "size";
		Default = 200;
		Min = 50;
		Max = 800;
		Rounding = 2;
		Compact = true;
	})
	SilentAimRadiusDepBox:AddSlider("SilentAimRadiusThickness",{
		Text = "thickness";
		Default = 2;
		Min = 1;
		Max = 10;
		Rounding = 2;
		Compact = true;
	})
	SilentAimRadiusDepBox:AddSlider("SilentAimRadiusTransparency",{
		Text = "transparency";
		Default = 0.5;
		Min = 0;
		Max = 1;
		Rounding = 1;
		Compact = true;
	})

	-- Camera Group Box
	local CamLockAimTab = AimTabBox:AddTab("camlock")
    CamLockAimTab:AddToggle("CameraLock", {
        Text = "cam lock"
    }):AddKeyPicker("CameraLockKey",{
        Text = "cam lock";
        Default = "E";
        Mode = "Toggle";
        NoUI = false;
    })
	local CameraLockDepBox = CamLockAimTab:AddDependencyBox()
	CameraLockDepBox:SetupDependencies({
		{Toggles.CameraLock, true}
	})
	CameraLockDepBox:AddToggle("CameraLockClosestPart", {
        Text = "closest part"
    })
	CameraLockDepBox:AddToggle("CameraRadius",{
		Text = "radius"
	}):AddColorPicker("CameraRadiusColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	local CameraRadiusDepBox = CameraLockDepBox:AddDependencyBox()
	CameraRadiusDepBox:SetupDependencies({
		{Toggles.CameraRadius, true}
	})
	CameraRadiusDepBox:AddToggle("CameraRadiusFill",{
		Text = "fill"
	}):AddColorPicker("CameraRadiusFillColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	CameraRadiusDepBox:AddToggle("CameraRadiusMatchAccent",{
		Text = "match accent"
	})
	CameraRadiusDepBox:AddSlider("CameraRadiusSize",{
		Text = "size";
		Default = 200;
		Min = 50;
		Max = 800;
		Rounding = 2;
		Compact = true;
	})
	CameraRadiusDepBox:AddSlider("CameraRadiusThickness",{
		Text = "thickness";
		Default = 2;
		Min = 1;
		Max = 10;
		Rounding = 2;
		Compact = true;
	})
	CameraRadiusDepBox:AddSlider("CameraRadiusTransparency",{
		Text = "transparency";
		Default = 0.5;
		Min = 0;
		Max = 1;
		Rounding = 1;
		Compact = true;
	})
	CameraLockDepBox:AddDropdown("CameraLockToggleType",{
		Values = {"Toggle","Hold"};
		Default = 1;
		Multi = false;
		Text = "toggle type";
		Callback = function(Value)
			Options.CameraLockKey.Mode = tostring(Value)
		end,
	})

	local function ApplyTargetingFilter(value, keepExisting)
		local targets = {}
		local crewIds = {}
		local hasFilter = false
		for entry in string.gmatch(value or "", "[^,]+") do
			entry = entry:match("^%s*(.-)%s*$")
			if entry ~= "" then
				hasFilter = true
				local query = entry:lower()
				local num = tonumber(entry)
				if num then
					table.insert(crewIds, num)
				end
				local bestPlayer, bestScore = nil, 0
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer then
						local score = 0
						for _, name in ipairs({ player.Name:lower(), player.DisplayName:lower() }) do
							local s = 0
							if name == query then
								s = 3
							elseif not num then
								if name:sub(1, #query) == query then
									s = 2
								elseif name:find(query, 1, true) then
									s = 1
								end
							end
							if s > score then
								score = s
							end
						end
						if score > bestScore then
							bestScore = score
							bestPlayer = player
						end
					end
				end
				if bestPlayer then
					targets[bestPlayer.Name] = true
				end
			end
		end
	
		local whitelist = {}
		if keepExisting then
			local current = Options.TargetingWhitelist.Value
			if type(current) == "table" then
				for name, selected in pairs(current) do
					if selected and Players:FindFirstChild(name) then
						whitelist[name] = true
					end
				end
			end
		end
		if hasFilter then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local isTarget = targets[player.Name] == true
					if not isTarget then
						for _, id in ipairs(crewIds) do
							if checkCrew(player, id) then
								isTarget = true
								break
							end
						end
					end
					if not isTarget then
						whitelist[player.Name] = true
					end
				end
			end
		end
	
		Options.TargetingWhitelist:SetValue(whitelist)
	end

	TargetingGroupBox:AddToggle("TargetingFriendCheck",{
		Text = "friend check"
	})
	TargetingGroupBox:AddToggle("TargetingCrewCheck",{
		Text = "crew check"
	})
	TargetingGroupBox:AddToggle("TargetingWallCheck",{
		Text = "wall check"
	})
	TargetingGroupBox:AddToggle("TargetingKnockedCheck",{
		Text = "knocked check"
	})
	TargetingGroupBox:AddDropdown("TargetingWhitelist", {
		SpecialType = "Player";
		Multi = true;
		Text = "player whitelist";
	})
	TargetingGroupBox:AddInput("TargetingFilter", {
		Text = "player/crew blacklist",
		Placeholder = "press enter to confirm",
		Tooltip = "(usernames or crew ids comma separated)",
		Numeric = false,
		Finished = true,
		Callback = function(value)
			ApplyTargetingFilter(value)
		end,
	})
	TargetingGroupBox:AddButton({
		Text = "clear whitelist";
		Func = function()
			Options.TargetingFilter:SetValue("")
			Options.TargetingWhitelist:SetValue({})
		end,
	})

	Players.PlayerAdded:Connect(function()
		task.wait(1)
		local filter = Options.TargetingFilter.Value
		if filter and filter:match("%S") then
			ApplyTargetingFilter(filter)
		end
	end)

	TargetingGroupBox:AddToggle("TargetingLimitDistanceToggle",{
		Text = "limit distance"
	})
	local TargetingLimitDistanceDepBox = TargetingGroupBox:AddDependencyBox()
	TargetingLimitDistanceDepBox:SetupDependencies({
		{Toggles.TargetingLimitDistanceToggle, true}
	})
	TargetingLimitDistanceDepBox:AddSlider("TargetingLimitDistance",{
		Text = "distance";
		Default = 200;
		Min = 1;
		Max = 200;
		Rounding = 0;
		Compact = true;
		Suffix = "s";
	})
	TargetingGroupBox:AddDropdown("TargetingTargetPart",{
		Values = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","RightUpperArm","RightLowerArm","LeftLowerLeg","LeftUpperLeg","RightLowerLeg","RightUpperLeg"};
		Default = 1;
		Multi = false;
		Text = "target part";
	})

	-- Gun Group Box

	local GunTab = GunTabBox:AddTab("gun")
	GunTab:AddToggle("GunNoRecoil",{
		Text = "no recoil"
	})
	GunTab:AddToggle("GunAutoReload",{
		Text = "auto reload"
	})
	GunTab:AddToggle("GunTriggerBot",{
		Text = "trigger bot"
	}):AddKeyPicker("GunTriggerBotKey",{
        Text = "trigger bot";
        Default = "T";
        Mode = "Toggle";
        NoUI = false;
    })
	local TriggerBotDepBox = GunTab:AddDependencyBox()
	TriggerBotDepBox:SetupDependencies({
		{Toggles.GunTriggerBot, true}
	})
	TriggerBotDepBox:AddToggle("GunTriggerBotFriendCheck",{
		Text = "friend check"
	})
	TriggerBotDepBox:AddToggle("GunTriggerBotCrewCheck",{
		Text = "crew check"
	})
	TriggerBotDepBox:AddToggle("GunTriggerBotKnockedCheck",{
		Text = "knocked check"
	})

	local KillAuraTab = GunTabBox:AddTab("kill aura")
	KillAuraTab:AddToggle("KillAura",{
		Text = "kill aura"
	}):AddKeyPicker("KillAuraKey",{
        Text = "kill aura";
        Default = "H";
        Mode = "Toggle";
        NoUI = false;
    })
	KillAuraTab:AddToggle("KillAuraClosestToMouse",{
		Text = "kill closest to mouse"
	})
	KillAuraTab:AddToggle("KillAuraRandomHitPart",{
		Text = "random hit part"
	})
	KillAuraTab:AddToggle("KillAuraFocusOnlyTarget",{
		Text = "focus only target"
	})

    -- \\CHARACTER TAB//
    local MovementGroupBox = Tabs.Character:AddLeftGroupbox("movement")
	local CharacterExploitsGroupBox = Tabs.Character:AddRightGroupbox("character exploits")

	-- Movement Group Box
    MovementGroupBox:AddToggle("VelocityToggle",{
		Text = "velocity"
	}):AddKeyPicker("VelocityKey",{
		Text = "velocity";
		Default = "X";
		Mode = "Toggle";
		NoUI = false;
	})
	MovementGroupBox:AddToggle("WalkSpeedToggle",{
		Text = "walk speed",
	})
	MovementGroupBox:AddToggle("JumpPowerToggle",{
		Text = "jump power",
	})
	MovementGroupBox:AddSlider("VelocitySpeed",{
		Text = "velocity speed";
		Default = 99;
		Min = 1;
		Max = 1000;
		Rounding = 0;
		Compact = true;
		Suffix = "s";
	})
	MovementGroupBox:AddSlider("WalkSpeed",{
		Text = "walk speed";
		Default = 16;
		Min = 1;
		Max = 1000;
		Rounding = 0;
		UltraCompact = true;
		Suffix = "s";
	})
	MovementGroupBox:AddSlider("JumpPower",{
		Text = "jump power";
		Default = 50;
		Min = 1;
		Max = 1000;
		Rounding = 0;
		UltraCompact = true;
		Suffix = "s";
	})

	CharacterExploitsGroupBox:AddToggle("VelocityBreakerToggle",{
		Text = "velocity breaker"
	}):AddKeyPicker("VelocityBreakerKey",{
		Text = "velocity breaker";
		Default = "V";
		Mode = "Toggle";
		NoUI = false;
	})
	CharacterExploitsGroupBox:AddToggle("AntiStompToggle",{
		Text = "anti stomp"
	})

	-- \\ESP TAB//
	local ESPGroupBox = Tabs.ESP:AddLeftGroupbox("esp")
	
	-- Esp Group Box
	ESPGroupBox:AddToggle("ESPBox",{
	Text = "box";
	}):AddColorPicker("ESPBoxColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	local ESPBoxDepBox = ESPGroupBox:AddDependencyBox()
	ESPBoxDepBox:SetupDependencies({
		{Toggles.ESPBox, true}
	})
	ESPBoxDepBox:AddToggle("ESPBoxOutline",{
		Text = "outline"
	})
	ESPBoxDepBox:AddToggle("ESPBoxFill",{
		Text = "fill"
	}):AddColorPicker("ESPBoxFillColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	ESPBoxDepBox:AddDivider()

	ESPGroupBox:AddToggle("ESPName",{
		Text = "name";
	}):AddColorPicker("ESPNameColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	local ESPNameDepBox = ESPGroupBox:AddDependencyBox()
	ESPNameDepBox:SetupDependencies({
		{Toggles.ESPName, true}
	})
	ESPNameDepBox:AddToggle("ESPNameOutline",{
		Text = "outline"
	})
	ESPNameDepBox:AddDropdown("ESPNametype",{
		Text = "name type";
		Values = {"username","displayname"};
		Default = 1;
		Mutli = false;
	})
	ESPNameDepBox:AddDivider()

	ESPGroupBox:AddToggle("ESPWeapon",{
		Text = "weapon"
	}):AddColorPicker("ESPWeaponColor",{
		Default = Color3.fromRGB(255,255,255)
	})
	local ESPWeaponDepBox = ESPGroupBox:AddDependencyBox()
	ESPWeaponDepBox:SetupDependencies({
		{Toggles.ESPWeapon, true}
	})
	ESPWeaponDepBox:AddToggle("ESPWeaponOutline",{
		Text = "outline"
	})
	ESPWeaponDepBox:AddDivider()

	ESPGroupBox:AddToggle("ESPInformation",{
		Text = "information"
	}):AddColorPicker("ESPInformationColor",{
		Default = Color3.fromRGB(255,255,255)
	})
	local ESPInformationDepBox = ESPGroupBox:AddDependencyBox()
	ESPInformationDepBox:SetupDependencies({
		{Toggles.ESPInformation, true}
	})
	ESPInformationDepBox:AddToggle("ESPInformationOutline",{
		Text = "outline"
	})
	ESPInformationDepBox:AddDropdown("ESPInformationtype",{
		Text = "info type";
		Values = {"aim accuracy now","aim accuracy all time"};
		Default = 1;
		Mutli = false;
	})
	ESPInformationDepBox:AddDivider()

	ESPGroupBox:AddToggle("ESPDistance",{
		Text = "distance"
	}):AddColorPicker("ESPDistanceColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	local ESPDistanceDepBox = ESPGroupBox:AddDependencyBox()
	ESPDistanceDepBox:SetupDependencies({
		{Toggles.ESPDistance, true}
	})
	ESPDistanceDepBox:AddToggle("ESPDistanceOutline",{
		Text = "outline"
	})
	ESPDistanceDepBox:AddDivider()

	local ESPHealthTG = ESPGroupBox:AddToggle("ESPHealth",{
		Text = "health bar"
	})
	ESPHealthTG:AddColorPicker("ESPHealthUpperColor",{
		Default = Color3.fromRGB(60, 255, 100),
		Title = "upper"
	})
	ESPHealthTG:AddColorPicker("ESPHealthMidColor",{
		Default = Color3.fromRGB(255, 220, 60),
		Title = "middle"
	})
	ESPHealthTG:AddColorPicker("ESPHealthLowerColor",{
		Default = Color3.fromRGB(255, 60, 60),
		Title = "lower"
	})

	local ESPArmorTG = ESPGroupBox:AddToggle("ESPArmor",{
		Text = "armor bar"
	})
	ESPArmorTG:AddColorPicker("ESPArmorUpperColor",{
		Default = Color3.fromRGB(27, 27, 209),
		Title = "upper"
	})
	ESPArmorTG:AddColorPicker("ESPArmorMidColor",{
		Default = Color3.fromRGB(27, 27, 209),
		Title = "middle"
	})
	ESPArmorTG:AddColorPicker("ESPArmorLowerColor",{
		Default = Color3.fromRGB(27, 27, 209),
		Title = "lower"
	})

	ESPGroupBox:AddDivider()

	ESPGroupBox:AddToggle("ESPCrewCheck",{
		Text = "crew check"
	})

	-- \\VISUALS TAB//
	local TracerGroupBox = Tabs.Visuals:AddLeftGroupbox("tarcer")
	local HitFXTabBox = Tabs.Main:AddRightTabbox("HitEffects")

	TracerGroupBox:AddToggle("TracerDisable",{
		Text = "disable tracers"
	})
	TracerGroupBox:AddToggle("TracerSelect",{
		Text = "selected tracer"
	})
	TracerGroupBox:AddDropdown("TracerTypeDropdown",{
		Text = "tracer";
		Values = {"Electric","Blood"};
		Default = 1;
		Mutli = false;
	})

	local HitEffectsTab = HitFXTabBox:AddTab("hit effects")
	HitEffectsTab:AddToggle("HitEffectsEnabled",{
		Text = "enabled"
	})

	local HitSoundsTab = HitFXTabBox:AddTab("hit sounds")
	HitSoundsTab:AddToggle("HitSoundsEnabled",{
		Text = "enabled"
	})

	-- \\MISC TAB//
	local ShopGroupBox = Tabs.Misc:AddLeftGroupbox("shop")
	local ChatGroupBox = Tabs.Misc:AddLeftGroupbox("chat")
	local AutomationGroupBox = Tabs.Misc:AddRightGroupbox("automation")

	ShopGroupBox:AddDropdown("DahoodShop", {
		Values = IgnoredShopNames,
		Default = 0,
		Multi = false,
		Text = "item to buy";
		Tooltip = "select item to buy";
	})
	ShopGroupBox:AddInput("DahoodShopSearch", {
		Text = "shop search",
		Placeholder = "press enter to confirm",
		Tooltip = "search",
		Numeric = false,
		Finished = true,
	
		Callback = function(value)
			local Match = FindBestMatch(value, Options.DahoodShop.Values)
			if Match then
				Options.DahoodShop:SetValue(Match)
			end
		end,
	})
	ShopGroupBox:AddButton({
		Text = "buy item";
		Func = function()
			PurchaseItem(Options.DahoodShop.Value)
		end,
	}):AddButton({
		Text = "buy held ammo";
		Func = function()
			local gun = getEquippedGun()
			if not gun then return end
	
			local AmmoName = gun.Name:gsub("%]$", " Ammo]")
	
			for _, Item in ipairs(IgnoredShop) do
				if Item:FindFirstChild("Amount") and Item.Name:find(AmmoName, 1, true) then
					PurchaseItem(Item.Name)
					break
				end
			end
		end,
	})

	local NotificationTabBox = Tabs.Misc:AddRightTabbox("notification")

	local NotifyHitTab = NotificationTabBox:AddTab("notify hit")
	NotifyHitTab:AddToggle("NotifyHitToggle",{
		Text = "enabled";
	})
	NotifyHitTab:AddSlider("NotifyHitDuration",{
		Text = "duration";
		Default = 2;
		Min = 0.1;
		Max = 2;
		Rounding = 1;
		Compact = true;
		Suffix = "s";	
	})
	NotifyHitTab:AddInput("NotifyHitText", {
		Text = "text",
		Default = "HIT {NAME} FOR {DMG} IN THE {PART} USING {WEAPON}",
		Placeholder = "press enter to confirm",
		Tooltip = "HIT {NAME} FOR {DMG} IN THE {PART} USING {WEAPON}",
		Numeric = false,
		Finished = true,
	})
	NotifyHitTab:AddLabel("ALL FORMATTING:\n\n {NAME}, {DMG}, {PART}, {WEAPON}, ",true)

	local NotifyDamageTab = NotificationTabBox:AddTab("notify damage")
	NotifyDamageTab:AddToggle("NotifyDamageToggle",{
		Text = "enabled";
	})
	NotifyDamageTab:AddSlider("NotifyDamageDuration",{
		Text = "duration";
		Default = 2;
		Min = 0.1;
		Max = 2;
		Rounding = 1;
		Compact = true;
		Suffix = "s";
	})
	NotifyDamageTab:AddInput("NotifyDamageText", {
		Text = "text",
		Default = "{NAME} HIT US FOR {DMG} IN THE {PART} USING {WEAPON}",
		Placeholder = "press enter to confirm",
		Tooltip = "{NAME} HIT US FOR {DMG} IN THE {PART} USING {WEAPON}",
		Numeric = false,
		Finished = true,

	})
	NotifyDamageTab:AddLabel("ALL FORMATTING:\n\n {NAME}, {DMG}, {PART}, {WEAPON}, ",true)

	ChatGroupBox:AddToggle("ChatSpy",{
		Text = "chat spy";
		Callback = function(Value)
			TextChatService.ChatWindowConfiguration.Enabled = Value
		end,
	})
	ChatGroupBox:AddToggle("ChatShitTalk",{
		Text = "shit talk"
	})

	AutomationGroupBox:AddToggle("AutoStompToggle", {
        Text = "auto stomp"
    })
	local AutoStompDepBox = AutomationGroupBox:AddDependencyBox()
	AutoStompDepBox:SetupDependencies({
		{Toggles.AutoStompToggle, true}
	})
	AutoStompDepBox:AddToggle("AutoStompAnimation", {
        Text = "stomp animation"
    })
	AutoStompDepBox:AddDivider()

	AutomationGroupBox:AddToggle("AutoMaskToggle", {
        Text = "auto mask"
    })
	local AutoMaskDepBox = AutomationGroupBox:AddDependencyBox()
	AutoMaskDepBox:SetupDependencies({
		{Toggles.AutoMaskToggle, true}
	})
	AutoMaskDepBox:AddDropdown("AutoMaskItem", {
		Values = {"[Paintball Mask] - $68","[Surgeon Mask] - $28","[Riot Mask] - $68"},
		Default = 1,
		Multi = false,
		Text = "mask";
	})
	AutoMaskDepBox:AddDivider()

	AutomationGroupBox:AddToggle("AutoArmorToggle", {
        Text = "auto armor"
    })
	local AutoArmorDepBox = AutomationGroupBox:AddDependencyBox()
	AutoArmorDepBox:SetupDependencies({
		{Toggles.AutoArmorToggle, true}
	})
	AutoArmorDepBox:AddToggle("ArmorBuyOnDamageToggle", {
        Text = "buy on damage"
    })
	AutoArmorDepBox:AddDropdown("AutoArmorItem", {
		Values = {"[High-Medium Armor] - $2589","[Medium Armor] - $1126"},
		Default = 1,
		Multi = false,
		Text = "armor";
	})
	AutoArmorDepBox:AddDivider()

	-- \\SETTINGS TAB//

	local UIGroupBox = Tabs.Settings:AddLeftGroupbox("ui settings")
	UIGroupBox:AddRainbowAccentToggle("RainbowAccent",{
		Text = "rainbow accent";
		Default = false;
	})
	UIGroupBox:AddMouseIconChanger("MouseIcon", {
		AlwaysOn = true;
	})

	UIGroupBox:AddDivider()

	UIGroupBox:AddToggle("KeybindFrame",{
		Text = "keybind frame";
		Default = true;

		Callback = function(Value)
			Library.KeybindFrame.Visible = Value
		end
	})

	UIGroupBox:AddLabel("MenuToggle"):AddKeyPicker("MenuKeybind",{
		Default = "RightControl",
		NoUI = true,
		Text = "menu keybind"
	})

	Library.KeybindFrame.Visible = Toggles.KeybindFrame.Value
	Library.ToggleKeybind = Options.MenuKeybind

	SaveManager:SetLibrary(Library)
	ThemeManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
	SaveManager:BuildConfigSection(Tabs.Settings)
	SaveManager:LoadAutoloadConfig()
	ThemeManager:ApplyTheme("Solitaire Universal")

	return {
		Library = Library,
		Toggles = Toggles,
		Options = Options,
	}
end

return UI
