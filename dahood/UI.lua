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
		Visuals = Window:AddTab("visuals");
		Misc = Window:AddTab("misc");
        Settings = Window:AddTab("settings");
    }

    -- \\MAIN TAB//
	local GameplayGroupBox = Tabs.Main:AddRightGroupbox("gameplay")
	local SilentAimGroupBox = Tabs.Main:AddLeftGroupbox("silent aim")
    local CameraGroupBox = Tabs.Main:AddLeftGroupbox("camera")
	local MouseGroupBox = Tabs.Main:AddLeftGroupbox("mouse")
    local GunGroupBox = Tabs.Main:AddRightGroupbox("gun")

	-- Gameplay group box
	
	GameplayGroupBox:AddToggle("AutoStompToggle", {
        Text = "auto stomp"
    })
	local AutoStompDepBox = GameplayGroupBox:AddDependencyBox()
	AutoStompDepBox:SetupDependencies({
		{Toggles.AutoStompToggle, true}
	})
	AutoStompDepBox:AddToggle("AutoStompAnimation", {
        Text = "stomp animation"
    })
	AutoStompDepBox:AddDivider()

	GameplayGroupBox:AddToggle("AutoMaskToggle", {
        Text = "auto mask"
    })
	GameplayGroupBox:AddToggle("AutoArmorToggle", {
        Text = "auto armor"
    })

	-- Silent Aim group box
	SilentAimGroupBox:AddToggle("SilentAimToggle", {
        Text = "silent aim"
    })
	local SilentAimDepBox = SilentAimGroupBox:AddDependencyBox()
	SilentAimDepBox:SetupDependencies({
		{Toggles.SilentAimToggle, true}
	})
	SilentAimDepBox:AddToggle("SilentAimFriendCheck",{
		Text = "friend check"
	})
	SilentAimDepBox:AddToggle("SilentAimCrewCheck",{
		Text = "crew check"
	})
	SilentAimDepBox:AddToggle("SilentAimWallCheck",{
		Text = "wall check"
	})
	SilentAimDepBox:AddToggle("SilentAimKnockedCheck",{
		Text = "knocked check"
	})
	SilentAimDepBox:AddToggle("SilentAimRadius",{
		Text = "radius"
	}):AddColorPicker("SilentAimColor", {
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

    CameraGroupBox:AddToggle("CameraLock", {
        Text = "cam lock"
    }):AddKeyPicker("CameraLockKey",{
        Text = "cam lock";
        Default = "E";
        Mode = "Toggle";
        NoUI = false;
    })
	local CameraLockDepBox = CameraGroupBox:AddDependencyBox()
	CameraLockDepBox:SetupDependencies({
		{Toggles.CameraLock, true}
	})
	CameraLockDepBox:AddToggle("CameraFriendCheck",{
		Text = "friend check"
	})
	CameraLockDepBox:AddToggle("CameraCrewCheck",{
		Text = "crew check"
	})
	CameraLockDepBox:AddToggle("CameraWallCheck",{
		Text = "wall check"
	})
	CameraLockDepBox:AddToggle("CameraKnockedCheck",{
		Text = "knocked check"
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

	-- Mouse Group Box

	MouseGroupBox:AddToggle("MouseLock", {
        Text = "mouse lock"
    }):AddKeyPicker("MouseLockKey",{
        Text = "mouse lock";
        Default = "F";
        Mode = "Toggle";
        NoUI = false;
    })
	local MouseDepBox = MouseGroupBox:AddDependencyBox()
	MouseDepBox:SetupDependencies({
		{Toggles.MouseLock, true}
	})
	MouseDepBox:AddToggle("MouseFriendCheck",{
		Text = "friend check"
	})
	MouseDepBox:AddToggle("MouseCrewCheck",{
		Text = "crew check"
	})
	MouseDepBox:AddToggle("MouseWallCheck",{
		Text = "wall check"
	})
	MouseDepBox:AddToggle("MouseKnockedCheck",{
		Text = "knocked check"
	})
	MouseDepBox:AddToggle("MouseRadius",{
		Text = "radius"
	}):AddColorPicker("MouseRadiusColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	local MouseRadiusDepBox = MouseDepBox:AddDependencyBox()
	MouseRadiusDepBox:SetupDependencies({
		{Toggles.MouseRadius, true}
	})
	MouseRadiusDepBox:AddToggle("MouseRadiusFill",{
		Text = "fill"
	}):AddColorPicker("MouseRadiusFillColor", {
		Default = Color3.fromRGB(255,255,255)
	})
	MouseRadiusDepBox:AddToggle("MouseRadiusMatchAccent",{
		Text = "match accent"
	})
	MouseRadiusDepBox:AddSlider("MouseRadiusSize",{
		Text = "size";
		Default = 200;
		Min = 50;
		Max = 800;
		Rounding = 2;
		Compact = true;
	})
	MouseRadiusDepBox:AddSlider("MouseRadiusThickness",{
		Text = "thickness";
		Default = 2;
		Min = 1;
		Max = 10;
		Rounding = 2;
		Compact = true;
	})
	MouseRadiusDepBox:AddSlider("MouseRadiusTransparency",{
		Text = "transparency";
		Default = 0.5;
		Min = 0;
		Max = 1;
		Rounding = 1;
		Compact = true;
	})
	MouseDepBox:AddDropdown("MouseLockToggleType",{
		Values = {"Toggle","Hold"};
		Default = 1;
		Multi = false;
		Text = "toggle type";
		Callback = function(Value)
			Options.MouseLockKey.Mode = tostring(Value)
		end,
	})

	-- Gun Group Box

	GunGroupBox:AddToggle("GunNoRecoil",{
		Text = "no recoil"
	})
	GunGroupBox:AddToggle("GunAutoReload",{
		Text = "auto reload"
	})
	GunGroupBox:AddToggle("GunTriggerBot",{
		Text = "trigger bot"
	}):AddKeyPicker("GunTriggerBotKey",{
        Text = "trigger bot";
        Default = "T";
        Mode = "Toggle";
        NoUI = false;
    })
	local TriggerBotDepBox = GunGroupBox:AddDependencyBox()
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

	-- \\VISUALS TAB//
	local ESPGroupBox = Tabs.Visuals:AddLeftGroupbox("esp")
	
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

	ESPGroupBox:AddDropdown("ESPNametype",{
		Text = "name type";
		Values = {"username","displayname"};
		Default = 1;
		Mutli = false;
	})

	-- \\MISC TAB//
	local ShopGroupBox = Tabs.Misc:AddLeftGroupbox("shop")
	ShopGroupBox:AddDropdown("DahoodShop", {
		Values = IgnoredShopNames,
		Default = 0,
		Multi = false,
		Text = "item to buy";
		Tooltip = "select item to buy";
	})
	ShopGroupBox:AddInput("DahoodShopSearch", {
		Text = "shop search",
		Placeholder = "search",
		Tooltip = "press enter to confirm",
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
	})
	NotifyHitTab:AddInput("NotifyHitText", {
		Text = "text",
		Default = "HIT {NAME} FOR {DMG} IN THE {PART} USING {WEAPON}",
		Placeholder = "E.G. HIT {NAME} FOR {DMG} IN THE {PART} USING {WEAPON}",
		Tooltip = "press enter to confirm",
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
	})
	NotifyDamageTab:AddInput("NotifyDamageText", {
		Text = "text",
		Default = "{NAME} HIT US FOR {DMG} IN THE {PART} USING {WEAPON}",
		Placeholder = "{NAME} HIT US FOR {DMG} IN THE {PART} USING {WEAPON}",
		Tooltip = "press enter to confirm",
		Numeric = false,
		Finished = true,

	})
	NotifyDamageTab:AddLabel("ALL FORMATTING:\n\n {NAME}, {DMG}, {PART}, {WEAPON}, ",true)

	local ChatGroupBox = Tabs.Misc:AddLeftGroupbox("chat")
	ChatGroupBox:AddToggle("ChatSpy",{
		Text = "chat spy";
		Callback = function(Value)
			TextChatService.ChatWindowConfiguration.Enabled = Value
		end,
	})
	ChatGroupBox:AddToggle("ChatShitTalk",{
		Text = "shit talk"
	})

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
