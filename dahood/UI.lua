print("yep2323")
local TextChatService = game:GetService("TextChatService")
local generalChannel = TextChatService:FindFirstChild("RBXGeneral", true)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/chamgagnepoetry/VantaLib/refs/heads/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/chamgagnepoetry/VantaLib/refs/heads/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/chamgagnepoetry/VantaLib/refs/heads/main/addons/SaveManager.lua"))()

local UI = {}

function UI:Initialize()
    local Window = Library:CreateWindow({
        Title = "SOLITAIRE BOOSTED";
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
    local CameraGroupBox = Tabs.Main:AddLeftGroupbox("camera")
	local MouseGroupBox = Tabs.Main:AddLeftGroupbox("mouse")
    local GunGroupBox = Tabs.Main:AddRightGroupbox("gun")

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
		Default = 1;
		Min = 0;
		Max = 1;
		Rounding = 1;
		Compact = true;
	})
	CameraGroupBox:AddDivider()
	CameraGroupBox:AddDropdown("CameraLockToggleType",{
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
		Default = 1;
		Min = 0;
		Max = 1;
		Rounding = 1;
		Compact = true;
	})
	MouseGroupBox:AddDivider()
	MouseGroupBox:AddDropdown("MouseLockToggleType",{
		Values = {"Toggle","Hold"};
		Default = 1;
		Multi = false;
		Text = "toggle type";
		Callback = function(Value)
			Options.MouseLockKey.Mode = tostring(Value)
		end,
	})

	-- Gun Group Box

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

	GunGroupBox:AddDivider()

	GunGroupBox:AddToggle("GunAutoReload",{
		Text = "auto reload"
	})

    -- \\CHARACTER TAB//
    local MovementGroupBox = Tabs.Character:AddLeftGroupbox("movement")

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

	ESPGroupBox:AddDivider()

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

	ESPGroupBox:AddDivider()

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

	ESPGroupBox:AddDivider()

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

	ESPGroupBox:AddDivider()

	ESPGroupBox:AddToggle("ESPCrewCheck",{
		Text = "crew check"
	})

	ESPGroupBox:AddDivider()

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

	ESPGroupBox:AddDivider()

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

	ESPGroupBox:AddDropdown("ESPNametype",{
		Text = "name type";
		Values = {"username","displayname"};
		Default = 1;
		Mutli = false;
	})

	-- \\MISC TAB//
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
