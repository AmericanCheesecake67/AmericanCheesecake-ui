--[[ Name: AetherUI Version: 1.1.0 Author: AmericanCheesecake67 ]]

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--// Custom Asset Constants
local ASSETS = {
	ToggleKnob = "rbxassetid://130969271294939",
	BackgroundImage = "rbxassetid://116274802250748",
	WindowLogo = "rbxassetid://100316831604862",
	TitleImage = "rbxassetid://126929770129914",
}

--// Global Theme Configuration
local THEME = {
	Colors = {
		Background = Color3.fromRGB(13, 15, 22),
		Topbar = Color3.fromRGB(18, 21, 31),
		Sidebar = Color3.fromRGB(16, 18, 27),
		Section = Color3.fromRGB(20, 23, 34),
		Element = Color3.fromRGB(25, 29, 42),
		ElementHover = Color3.fromRGB(32, 37, 54),
		DropdownBg = Color3.fromRGB(17, 20, 30),
		Border = Color3.fromRGB(42, 48, 70),
		Accent = Color3.fromRGB(230, 40, 50), -- American Red
		AccentSecondary = Color3.fromRGB(20, 40, 100), -- Navy Blue
		Text = Color3.fromRGB(240, 244, 255),
		SubText = Color3.fromRGB(156, 166, 194),
		Muted = Color3.fromRGB(98, 108, 138),
		Success = Color3.fromRGB(46, 213, 115),
		Warning = Color3.fromRGB(255, 177, 66),
		Error = Color3.fromRGB(255, 71, 87),
		Info = Color3.fromRGB(230, 40, 50),
	},
	Fonts = {
		Bold = Enum.Font.GothamBold,
		SemiBold = Enum.Font.GothamSemibold,
		Regular = Enum.Font.Gotham,
		Mono = Enum.Font.Code,
	},
	CornerRadius = {
		Window = UDim.new(0, 10),
		Section = UDim.new(0, 8),
		Element = UDim.new(0, 6),
		Small = UDim.new(0, 4),
		Pill = UDim.new(1, 0),
	},
	Tween = {
		Fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Normal = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		Slow = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	},
}

--// Environment Helpers (Executor + Studio Fallbacks)
local function GetSafeGuiParent()
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then
			return hui
		end
	end
	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		local okAccess = pcall(function()
			return coreGui.Name
		end)
		if okAccess then
			return coreGui
		end
	end
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		return localPlayer:WaitForChild("PlayerGui")
	end
	return nil
end

local VirtualFS = {}
local FS = {
	HasNative = (type(writefile) == "function" and type(readfile) == "function"),
}

function FS.EnsureFolder(folder)
	if type(isfolder) == "function" and type(makefolder) == "function" then
		local ok, exists = pcall(isfolder, folder)
		if ok and not exists then
			pcall(makefolder, folder)
		end
	else
		VirtualFS[folder] = VirtualFS[folder] or {}
	end
end

function FS.Write(path, content)
	if FS.HasNative then
		local ok, err = pcall(writefile, path, content)
		return ok, err
	end
	VirtualFS[path] = content
	return true
end

function FS.Read(path)
	if FS.HasNative then
		if type(isfile) == "function" then
			local okExists, exists = pcall(isfile, path)
			if not okExists or not exists then
				return nil, "File not found"
			end
		end
		local ok, data = pcall(readfile, path)
		if ok then
			return data
		end
		return nil, data
	end
	if VirtualFS[path] ~= nil then
		return VirtualFS[path]
	end
	return nil, "File not found in memory"
end

function FS.Delete(path)
	if type(delfile) == "function" then
		local ok, err = pcall(delfile, path)
		return ok, err
	end
	VirtualFS[path] = nil
	return true
end

function FS.List(folder)
	local names = {}
	if type(listfiles) == "function" then
		local ok, files = pcall(listfiles, folder)
		if ok and type(files) == "table" then
			for _, fullPath in ipairs(files) do
				local clean = tostring(fullPath):gsub("\\", "/")
				local fileName = clean:match("([^/]+)%.json$")
				if fileName then
					table.insert(names, fileName)
				end
			end
			return names
		end
	end
	local prefix = folder .. "/"
	for k in pairs(VirtualFS) do
		if type(k) == "string" and k:sub(1, #prefix) == prefix then
			local fileName = k:sub(#prefix + 1):match("^(.+)%.json$")
			if fileName then
				table.insert(names, fileName)
			end
		end
	end
	return names
end

--// UI Construction Helpers
local Utility = {}

function Utility.Create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

function Utility.Tween(instance, tweenInfo, goal)
	local tween = TweenService:Create(instance, tweenInfo, goal)
	tween:Play()
	return tween
end

function Utility.AddCorner(parent, radius)
	return Utility.Create("UICorner", {
		CornerRadius = radius or THEME.CornerRadius.Element,
		Parent = parent,
	})
end

function Utility.AddStroke(parent, color, thickness, transparency)
	return Utility.Create("UIStroke", {
		Color = color or THEME.Colors.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Utility.AddPadding(parent, top, bottom, left, right)
	return Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		Parent = parent,
	})
end

function Utility.FormatKey(keyCode)
	if typeof(keyCode) ~= "EnumItem" then
		return "None"
	end
	local short = {
		RightShift = "RShift",
		LeftShift = "LShift",
		RightControl = "RCtrl",
		LeftControl = "LCtrl",
		RightAlt = "RAlt",
		LeftAlt = "LAlt",
		Backspace = "Bksp",
		Return = "Enter",
	}
	return short[keyCode.Name] or keyCode.Name
end

function Utility.ColorToHex(c)
	return string.format(
		"#%02X%02X%02X",
		math.clamp(math.round(c.R * 255), 0, 255),
		math.clamp(math.round(c.G * 255), 0, 255),
		math.clamp(math.round(c.B * 255), 0, 255)
	)
end

function Utility.Round(num, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(num * mult + 0.5) / mult
end

--// Base Interactive Control Class (Strict OOP State Management)
local BaseControl = {}
BaseControl.__index = BaseControl

function BaseControl.new(initialValue, elementType, defaultCallback)
	local self = setmetatable({}, BaseControl)
	self._value = initialValue
	self._type = elementType or "Generic"
	self._listeners = {}
	self._applyVisual = nil
	if type(defaultCallback) == "function" then
		table.insert(self._listeners, defaultCallback)
	end
	return self
end

function BaseControl:GetValue()
	return self._value
end

function BaseControl:SetValue(newValue, silent)
	self._value = newValue
	if self._applyVisual then
		self._applyVisual(newValue)
	end
	if not silent then
		for _, fn in ipairs(self._listeners) do
			task.spawn(fn, newValue)
		end
	end
	return self
end

function BaseControl:OnChanged(callback)
	assert(type(callback) == "function", "OnChanged expects a function callback")
	table.insert(self._listeners, callback)
	local listeners = self._listeners
	return {
		Disconnect = function()
			local idx = table.find(listeners, callback)
			if idx then
				table.remove(listeners, idx)
			end
		end,
	}
end

--// ConfigManager Class
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(window, folderName)
	local self = setmetatable({}, ConfigManager)
	self.Window = window
	self.Folder = folderName or "AetherUI_Configs"
	self.Registry = {}
	FS.EnsureFolder(self.Folder)
	return self
end

function ConfigManager:Register(flag, control)
	if flag and flag ~= "" then
		self.Registry[flag] = control
	end
end

function ConfigManager:_Serialize(val)
	local t = typeof(val)
	if t == "Color3" then
		return { __type = "Color3", r = val.R, g = val.G, b = val.B }
	elseif t == "EnumItem" then
		return { __type = "KeyCode", name = val.Name }
	elseif t == "boolean" or t == "number" or t == "string" or t == "table" then
		return val
	end
	return nil
end

function ConfigManager:_Deserialize(data)
	if type(data) == "table" and data.__type == "Color3" then
		return Color3.new(tonumber(data.r) or 1, tonumber(data.g) or 1, tonumber(data.b) or 1)
	elseif type(data) == "table" and data.__type == "KeyCode" then
		return Enum.KeyCode[data.name] or Enum.KeyCode.Unknown
	end
	return data
end

function ConfigManager:Save(configName)
	if not configName or configName == "" then
		return false, "Config name cannot be empty"
	end
	FS.EnsureFolder(self.Folder)
	local payload = {}
	for flag, ctrl in pairs(self.Registry) do
		local serialized = self:_Serialize(ctrl:GetValue())
		if serialized ~= nil then
			payload[flag] = serialized
		end
	end
	local okEncode, json = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not okEncode then
		return false, "Failed to encode JSON"
	end
	local path = string.format("%s/%s.json", self.Folder, configName)
	return FS.Write(path, json)
end

function ConfigManager:Load(configName)
	if not configName or configName == "" then
		return false, "Config name cannot be empty"
	end
	local path = string.format("%s/%s.json", self.Folder, configName)
	local raw, err = FS.Read(path)
	if not raw then
		return false, err or "Config file not found"
	end
	local okDecode, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not okDecode or type(decoded) ~= "table" then
		return false, "Corrupted JSON config"
	end
	for flag, savedVal in pairs(decoded) do
		local ctrl = self.Registry[flag]
		if ctrl then
			ctrl:SetValue(self:_Deserialize(savedVal), false)
		end
	end
	return true
end

function ConfigManager:Delete(configName)
	if not configName or configName == "" then
		return false, "Config name cannot be empty"
	end
	local path = string.format("%s/%s.json", self.Folder, configName)
	return FS.Delete(path)
end

function ConfigManager:List()
	local list = FS.List(self.Folder)
	if #list == 0 then
		return { "default" }
	end
	table.sort(list)
	return list
end

--// Main Library Table
local AetherUI = {
	Theme = THEME,
	Assets = ASSETS,
	Version = "1.1.0",
}
AetherUI.__index = AetherUI

--// Section Class
local Section = {}
Section.__index = Section

--// Tab Class
local Tab = {}
Tab.__index = Tab

--// Window Class
local Window = {}
Window.__index = Window

function AetherUI:CreateWindow(opts)
	opts = type(opts) == "table" and opts or { Title = tostring(opts or "AetherUI") }

	local titleText = opts.Title or "AetherUI"
	local subtitleText = opts.Subtitle or "v1.1.0 • Precision Overlay"
	local logoAsset = opts.Icon or opts.Logo or ASSETS.WindowLogo
	local titleImageAsset = opts.TitleImage or ASSETS.TitleImage
	local bgImageAsset = (opts.BackgroundImage ~= nil) and opts.BackgroundImage or ASSETS.BackgroundImage
	local bgDarkening = tonumber(opts.BackgroundDarkening) or 0.6
	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	local windowSize = opts.Size or Vector2.new(640, 440)
	local minSize = opts.MinSize or Vector2.new(480, 320)
	local configFolder = opts.ConfigFolder or "AetherUI_Configs"

	local parentGui = GetSafeGuiParent()
	assert(parentGui, "AetherUI: Unable to locate a valid GUI parent")

	local guiName = "AetherUI_Overlay_" .. titleText:gsub("%W", "")
	local old = parentGui:FindFirstChild(guiName)
	if old then
		old:Destroy()
	end

	local self = setmetatable({}, Window)
	self.Tabs = {}
	self.ActiveTab = nil
	self.ToggleKey = toggleKey
	self.Visible = true
	self._connections = {}
	self._themeUpdaters = {}
	self._translatableFrames = {}
	self._currentTransparency = 0

	function self:_RegisterThemeUpdater(fn)
		table.insert(self._themeUpdaters, fn)
	end

	function self:_RegisterFrame(frame, baseTransparency)
		if frame then
			table.insert(self._translatableFrames, {
				Instance = frame,
				Base = baseTransparency or 0,
			})
			if self._currentTransparency > 0 then
				frame.BackgroundTransparency = math.clamp((baseTransparency or 0) + self._currentTransparency, 0, 0.95)
			end
		end
	end

	local screenGui = Utility.Create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parentGui,
	})
	self.ScreenGui = screenGui
	self.ConfigManager = ConfigManager.new(self, configFolder)

	-- Shared Tooltip
	local tooltipFrame = Utility.Create("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = THEME.Colors.Topbar,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 900,
		Parent = screenGui,
	})
	Utility.AddCorner(tooltipFrame, THEME.CornerRadius.Small)
	local tooltipStroke = Utility.AddStroke(tooltipFrame, THEME.Colors.Accent, 1, 1)
	Utility.AddPadding(tooltipFrame, 5, 5, 8, 8)
	local tooltipLabel = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextColor3 = THEME.Colors.Text,
		TextTransparency = 1,
		Text = "",
		ZIndex = 901,
		Parent = tooltipFrame,
	})

	self:_RegisterThemeUpdater(function(accent)
		tooltipStroke.Color = accent
	end)

	function self:AttachTooltip(target, text)
		if not text or text == "" then
			return
		end
		target.MouseEnter:Connect(function()
			tooltipLabel.Text = text
			tooltipFrame.Visible = true
			Utility.Tween(tooltipFrame, THEME.Tween.Fast, { BackgroundTransparency = 0.05 })
			Utility.Tween(tooltipStroke, THEME.Tween.Fast, { Transparency = 0.35 })
			Utility.Tween(tooltipLabel, THEME.Tween.Fast, { TextTransparency = 0 })
		end)
		target.MouseLeave:Connect(function()
			Utility.Tween(tooltipFrame, THEME.Tween.Fast, { BackgroundTransparency = 1 })
			Utility.Tween(tooltipStroke, THEME.Tween.Fast, { Transparency = 1 })
			local tw = Utility.Tween(tooltipLabel, THEME.Tween.Fast, { TextTransparency = 1 })
			tw.Completed:Connect(function()
				if tooltipLabel.TextTransparency >= 0.99 then
					tooltipFrame.Visible = false
				end
			end)
		end)
	end

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if tooltipFrame.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
			local abs = tooltipFrame.AbsoluteSize
			local x = math.clamp(input.Position.X + 14, 6, math.max(6, vp.X - abs.X - 6))
			local y = math.clamp(input.Position.Y + 16, 6, math.max(6, vp.Y - abs.Y - 6))
			tooltipFrame.Position = UDim2.fromOffset(x, y)
		end
	end))

	-- Notification Stack Container (Bottom-Right)
	local notifContainer = Utility.Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.new(0, 300, 1, -36),
		BackgroundTransparency = 1,
		ZIndex = 800,
		Parent = screenGui,
	})
	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifContainer,
	})
	self._notifContainer = notifContainer

	-- Main Window Container
	local mainFrame = Utility.Create("Frame", {
		Name = "MainWindow",
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		Position = UDim2.new(0.5, -math.floor(windowSize.X / 2), 0.5, -math.floor(windowSize.Y / 2)),
		BackgroundColor3 = THEME.Colors.Background,
		ClipsDescendants = true,
		Parent = screenGui,
	})
	Utility.AddCorner(mainFrame, THEME.CornerRadius.Window)
	local windowStroke = Utility.AddStroke(mainFrame, THEME.Colors.Border, 1, 0)
	local windowGradient = Utility.Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.Colors.Accent),
			ColorSequenceKeypoint.new(0.35, THEME.Colors.Border),
			ColorSequenceKeypoint.new(1, THEME.Colors.AccentSecondary),
		}),
		Rotation = 35,
		Parent = windowStroke,
	})
	self.MainFrame = mainFrame
	self:_RegisterFrame(mainFrame, 0)

	self:_RegisterThemeUpdater(function(accent)
		windowGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accent),
			ColorSequenceKeypoint.new(0.35, THEME.Colors.Border),
			ColorSequenceKeypoint.new(1, THEME.Colors.AccentSecondary),
		})
	end)

	-- [Requirement 3] Global Background Image & Darkening Overlay
	local bgImageLabel = Utility.Create("ImageLabel", {
		Name = "BackgroundImage",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		Image = tostring(bgImageAsset or ""),
		ScaleType = Enum.ScaleType.Crop,
		Visible = (bgImageAsset ~= nil and bgImageAsset ~= ""),
		ZIndex = 0,
		Parent = mainFrame,
	})
	Utility.AddCorner(bgImageLabel, THEME.CornerRadius.Window)

	local bgOverlayFrame = Utility.Create("Frame", {
		Name = "BackgroundOverlay",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = bgDarkening,
		BorderSizePixel = 0,
		Visible = (bgImageAsset ~= nil and bgImageAsset ~= ""),
		ZIndex = 1,
		Parent = mainFrame,
	})
	Utility.AddCorner(bgOverlayFrame, THEME.CornerRadius.Window)
	self.BackgroundImageLabel = bgImageLabel
	self.BackgroundOverlayFrame = bgOverlayFrame

	function self:SetBackgroundImage(assetId, darkening)
		local hasImage = (assetId ~= nil and tostring(assetId) ~= "")
		bgImageLabel.Image = hasImage and tostring(assetId) or ""
		bgImageLabel.Visible = hasImage
		bgOverlayFrame.Visible = hasImage
		if darkening ~= nil then
			bgOverlayFrame.BackgroundTransparency = math.clamp(tonumber(darkening) or 0.6, 0, 1)
		end
	end

	-- [Requirement 5] Smart Mobile Pill (Draggable & Auto-Size)
	local mobilePill = Utility.Create("TextButton", {
		Name = "MobileTogglePill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = THEME.Colors.Topbar,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 750,
		Parent = screenGui,
	})
	Utility.AddCorner(mobilePill, THEME.CornerRadius.Pill)
	Utility.AddPadding(mobilePill, 6, 6, 10, 10)
	local pillStroke = Utility.AddStroke(mobilePill, THEME.Colors.Accent, 1, 0.25)

	local pillLabel = Utility.Create("TextLabel", {
		Name = "PillText",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Bold,
		TextSize = 12,
		TextColor3 = THEME.Colors.Accent,
		Text = "◆ Open " .. titleText,
		ZIndex = 751,
		Parent = mobilePill,
	})
	self.MobilePill = mobilePill

	self:_RegisterThemeUpdater(function(accent)
		pillStroke.Color = accent
		pillLabel.TextColor3 = accent
	end)

	-- Topbar (ZIndex = 2+)
	local topbar = Utility.Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = THEME.Colors.Topbar,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = mainFrame,
	})
	Utility.AddCorner(topbar, THEME.CornerRadius.Window)
	self:_RegisterFrame(topbar, 0.15)

	local topbarPatch = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = THEME.Colors.Topbar,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = topbar,
	})
	self:_RegisterFrame(topbarPatch, 0.15)

	Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = THEME.Colors.Border,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = topbar,
	})

	-- Logo Icon (Uncle Sam Trump default)
	local logoIcon = Utility.Create("ImageLabel", {
		Name = "Logo",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(0, 12, 0.5, -14),
		BackgroundTransparency = 1,
		Image = logoAsset,
		ImageColor3 = Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
		Parent = topbar,
	})
	self.Logo = logoIcon

	-- [Requirement 1] Custom Title Image (Replaces Title TextLabel)
	local titleImage = Utility.Create("ImageLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(48, 5),
		Size = UDim2.fromOffset(150, 24),
		BackgroundTransparency = 1,
		Image = titleImageAsset,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
		Parent = topbar,
	})
	self.TitleImage = titleImage

	-- Subtitle
	Utility.Create("TextLabel", {
		Name = "Subtitle",
		Position = UDim2.fromOffset(48, 28),
		Size = UDim2.new(1, -160, 0, 14),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.SubText,
		Text = subtitleText,
		ZIndex = 3,
		Parent = topbar,
	})

	-- Minimize / Hide Button
	local hideBtn = Utility.Create("TextButton", {
		Name = "HideBtn",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(28, 26),
		BackgroundColor3 = THEME.Colors.Element,
		AutoButtonColor = false,
		Font = THEME.Fonts.Bold,
		TextSize = 14,
		TextColor3 = THEME.Colors.SubText,
		Text = "—",
		ZIndex = 3,
		Parent = topbar,
	})
	Utility.AddCorner(hideBtn, THEME.CornerRadius.Small)
	self:_RegisterFrame(hideBtn, 0)
	self:AttachTooltip(hideBtn, "Hide Overlay (" .. Utility.FormatKey(self.ToggleKey) .. ")")

	function self:SetVisible(state)
		self.Visible = state
		mainFrame.Visible = state
		mobilePill.Visible = not state
		if not state then
			tooltipFrame.Visible = false
		end
	end

	function self:Toggle()
		self:SetVisible(not self.Visible)
	end

	function self:SetToggleKey(newKey)
		if typeof(newKey) == "EnumItem" then
			self.ToggleKey = newKey
		end
	end

	hideBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	-- Draggable + Clickable Smart Mobile Pill Logic
	do
		local pillDragging = false
		local pillPointer = nil
		local pillIsMouse = false
		local pillDragStart = Vector2.zero
		local pillStartPos = UDim2.new()
		local pillMoved = false

		mobilePill.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				pillDragging = true
				pillPointer = input
				pillIsMouse = (input.UserInputType == Enum.UserInputType.MouseButton1)
				pillDragStart = Vector2.new(input.Position.X, input.Position.Y)
				pillStartPos = mobilePill.Position
				pillMoved = false

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						if pillDragging and not pillMoved then
							self:SetVisible(true)
						end
						pillDragging = false
						pillPointer = nil
					end
				end)
			end
		end)

		table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
			if pillDragging and (input == pillPointer or (pillIsMouse and input.UserInputType == Enum.UserInputType.MouseMovement)) then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - pillDragStart
				if delta.Magnitude > 5 then
					pillMoved = true
				end
				if pillMoved then
					mobilePill.Position = UDim2.new(
						pillStartPos.X.Scale,
						pillStartPos.X.Offset + delta.X,
						pillStartPos.Y.Scale,
						pillStartPos.Y.Offset + delta.Y
					)
				end
			end
		end))
	end

	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and UserInputService:GetFocusedTextBox() == nil then
			if input.KeyCode == self.ToggleKey and self.ToggleKey ~= Enum.KeyCode.Unknown then
				self:Toggle()
			end
		end
	end))

	-- Body Container (Sidebar + Pages, ZIndex = 2+)
	local body = Utility.Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = mainFrame,
	})

	local sidebar = Utility.Create("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 168, 1, 0),
		BackgroundColor3 = THEME.Colors.Sidebar,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = THEME.Colors.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 2,
		Parent = body,
	})
	Utility.AddPadding(sidebar, 10, 10, 8, 8)
	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar,
	})
	self:_RegisterFrame(sidebar, 0.2)
	self:_RegisterThemeUpdater(function(accent)
		sidebar.ScrollBarImageColor3 = accent
	end)

	Utility.Create("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.fromOffset(168, 0),
		BackgroundColor3 = THEME.Colors.Border,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = body,
	})
	self.Sidebar = sidebar

	local pagesHolder = Utility.Create("Frame", {
		Name = "Pages",
		Position = UDim2.fromOffset(169, 0),
		Size = UDim2.new(1, -169, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = body,
	})
	self.PagesHolder = pagesHolder

	-- Resize Grip (Desktop Mouse + Mobile Touch)
	local resizeGrip = Utility.Create("TextButton", {
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -3),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "◢",
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextColor3 = THEME.Colors.Muted,
		AutoButtonColor = false,
		ZIndex = 50,
		Parent = mainFrame,
	})

	-- Unified Dragging & Resizing (Supports MouseButton1 & Mobile Touch)
	do
		local dragging = false
		local dragPointer = nil
		local isMouseDrag = false
		local dragStart = Vector2.zero
		local startPos = UDim2.new()

		topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragPointer = input
				isMouseDrag = (input.UserInputType == Enum.UserInputType.MouseButton1)
				dragStart = Vector2.new(input.Position.X, input.Position.Y)
				startPos = mainFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						dragPointer = nil
					end
				end)
			end
		end)

		local resizing = false
		local resizePointer = nil
		local isMouseResize = false
		local resizeStart = Vector2.zero
		local startSize = Vector2.zero

		resizeGrip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				resizePointer = input
				isMouseResize = (input.UserInputType == Enum.UserInputType.MouseButton1)
				resizeStart = Vector2.new(input.Position.X, input.Position.Y)
				startSize = mainFrame.AbsoluteSize
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						resizing = false
						resizePointer = nil
					end
				end)
			end
		end)

		table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input == dragPointer or (isMouseDrag and input.UserInputType == Enum.UserInputType.MouseMovement)) then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
				mainFrame.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			elseif resizing and (input == resizePointer or (isMouseResize and input.UserInputType == Enum.UserInputType.MouseMovement)) then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - resizeStart
				local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
				local newW = math.clamp(startSize.X + delta.X, minSize.X, vp.X - 24)
				local newH = math.clamp(startSize.Y + delta.Y, minSize.Y, vp.Y - 24)
				mainFrame.Size = UDim2.fromOffset(newW, newH)
			end
		end))
	end

	return self
end

--// [Requirement 4] Global Theme Color & Transparency APIs
function Window:SetThemeColor(newColor)
	if typeof(newColor) ~= "Color3" then
		return
	end
	THEME.Colors.Accent = newColor
	THEME.Colors.Info = newColor
	for _, updater in ipairs(self._themeUpdaters) do
		task.spawn(updater, newColor)
	end
end

function Window:SetTransparency(alpha)
	local clamped = math.clamp(tonumber(alpha) or 0, 0, 0.95)
	self._currentTransparency = clamped
	for _, entry in ipairs(self._translatableFrames) do
		local inst = entry.Instance
		if inst and inst.Parent then
			inst.BackgroundTransparency = math.clamp(entry.Base + clamped, 0, 0.95)
		end
	end
end

--// Toast Notification System
function Window:Notify(opts)
	opts = type(opts) == "table" and opts or { Content = tostring(opts) }
	local title = opts.Title or "Notification"
	local content = opts.Content or opts.Text or ""
	local nType = opts.Type or "Info"
	local duration = tonumber(opts.Duration) or 4

	local typeColors = {
		Info = THEME.Colors.Accent,
		Success = THEME.Colors.Success,
		Warning = THEME.Colors.Warning,
		Error = THEME.Colors.Error,
	}
	local defaultIcons = {
		Info = "rbxassetid://10723415903",
		Success = "rbxassetid://10709790644",
		Warning = "rbxassetid://10709753149",
		Error = "rbxassetid://10709752996",
	}

	local accent = typeColors[nType] or THEME.Colors.Accent
	local iconId = opts.Icon or defaultIcons[nType] or defaultIcons.Info

	local wrapper = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 68),
		BackgroundTransparency = 1,
		Parent = self._notifContainer,
	})

	local card = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(1, 330, 0, 0),
		BackgroundColor3 = THEME.Colors.Topbar,
		ClipsDescendants = true,
		Parent = wrapper,
	})
	Utility.AddCorner(card, THEME.CornerRadius.Section)
	Utility.AddStroke(card, accent, 1, 0.25)

	Utility.Create("ImageLabel", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.fromOffset(12, 14),
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = accent,
		Parent = card,
	})

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(40, 10),
		Size = UDim2.new(1, -52, 0, 18),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Bold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		Parent = card,
	})

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(40, 28),
		Size = UDim2.new(1, -52, 0, 30),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = THEME.Colors.SubText,
		Text = content,
		Parent = card,
	})

	local progress = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = card,
	})

	local dismissBtn = Utility.Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = card,
	})

	local closed = false
	local function CloseToast()
		if closed then
			return
		end
		closed = true
		local out = Utility.Tween(card, THEME.Tween.Normal, { Position = UDim2.new(1, 340, 0, 0) })
		out.Completed:Connect(function()
			wrapper:Destroy()
		end)
	end

	dismissBtn.MouseButton1Click:Connect(CloseToast)
	Utility.Tween(card, THEME.Tween.Normal, { Position = UDim2.fromOffset(0, 0) })
	Utility.Tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) })
	task.delay(duration, CloseToast)
end

--// Tab Creation (Supports Text + Left/Right Icons, ZIndex = 2+)
function Window:CreateTab(opts, iconArg, iconPosArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Tab"),
		Icon = iconArg,
		IconPosition = iconPosArg,
	}

	local tabTitle = cfg.Title or cfg.Name or "Tab"
	local tabIcon = cfg.Icon or ""
	local iconPos = (cfg.IconPosition == "Right") and "Right" or "Left"

	local tabObj = setmetatable({
		Window = self,
		Sections = {},
		_defaultSection = nil,
	}, Tab)

	local tabBtn = Utility.Create("TextButton", {
		Name = tabTitle .. "_Tab",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Colors.Element,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = self.Sidebar,
	})
	Utility.AddCorner(tabBtn, THEME.CornerRadius.Element)
	local indicator = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BackgroundColor3 = THEME.Colors.Accent,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = tabBtn,
	})
	Utility.AddCorner(indicator, THEME.CornerRadius.Pill)

	local hasIcon = (tabIcon ~= nil and tabIcon ~= "")
	local iconImg = nil
	if hasIcon then
		iconImg = Utility.Create("ImageLabel", {
			AnchorPoint = Vector2.new(iconPos == "Right" and 1 or 0, 0.5),
			Position = iconPos == "Right" and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Image = tabIcon,
			ImageColor3 = THEME.Colors.SubText,
			ZIndex = 4,
			Parent = tabBtn,
		})
	end

	local leftPad = (hasIcon and iconPos == "Left") and 34 or 12
	local rightPad = (hasIcon and iconPos == "Right") and 34 or 10
	local tabLabel = Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(leftPad, 0),
		Size = UDim2.new(1, -(leftPad + rightPad), 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.SemiBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.SubText,
		Text = tabTitle,
		ZIndex = 4,
		Parent = tabBtn,
	})

	local page = Utility.Create("ScrollingFrame", {
		Name = tabTitle .. "_Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.Colors.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 2,
		Parent = self.PagesHolder,
	})
	Utility.AddPadding(page, 12, 14, 12, 12)
	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})

	self:_RegisterThemeUpdater(function(accent)
		indicator.BackgroundColor3 = accent
		page.ScrollBarImageColor3 = accent
		if self.ActiveTab == tabObj and iconImg then
			iconImg.ImageColor3 = accent
		end
	end)

	tabObj.Button = tabBtn
	tabObj.Page = page
	tabObj._indicator = indicator
	tabObj._label = tabLabel
	tabObj._icon = iconImg

	function tabObj:Select()
		for _, other in ipairs(self.Window.Tabs) do
			other.Page.Visible = false
			Utility.Tween(other.Button, THEME.Tween.Fast, { BackgroundTransparency = 1 })
			Utility.Tween(other._indicator, THEME.Tween.Fast, { Size = UDim2.fromOffset(3, 0) })
			Utility.Tween(other._label, THEME.Tween.Fast, { TextColor3 = THEME.Colors.SubText })
			if other._icon then
				Utility.Tween(other._icon, THEME.Tween.Fast, { ImageColor3 = THEME.Colors.SubText })
			end
		end
		self.Window.ActiveTab = self
		self.Page.Visible = true
		Utility.Tween(self.Button, THEME.Tween.Fast, { BackgroundTransparency = 0 })
		Utility.Tween(self._indicator, THEME.Tween.Normal, { Size = UDim2.fromOffset(3, 20) })
		Utility.Tween(self._label, THEME.Tween.Fast, { TextColor3 = THEME.Colors.Text })
		if self._icon then
			Utility.Tween(self._icon, THEME.Tween.Fast, { ImageColor3 = THEME.Colors.Accent })
		end
	end

	tabBtn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabObj then
			Utility.Tween(tabBtn, THEME.Tween.Fast, { BackgroundTransparency = 0.45 })
		end
	end)
	tabBtn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabObj then
			Utility.Tween(tabBtn, THEME.Tween.Fast, { BackgroundTransparency = 1 })
		end
	end)
	tabBtn.MouseButton1Click:Connect(function()
		tabObj:Select()
	end)

	table.insert(self.Tabs, tabObj)
	if #self.Tabs == 1 then
		tabObj:Select()
	end

	return tabObj
end
Window.AddTab = Window.CreateTab

--// Section Creation (Scrollable / Overflow-Safe Grouping, ZIndex = 2+)
function Tab:CreateSection(opts)
	local cfg = type(opts) == "table" and opts or { Title = tostring(opts or "Section") }
	local secTitle = cfg.Title or cfg.Name or "Section"
	local maxHeight = tonumber(cfg.MaxHeight)

	local secObj = setmetatable({
		Tab = self,
		Window = self.Window,
	}, Section)

	local card = Utility.Create("Frame", {
		Name = secTitle .. "_Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Colors.Section,
		BackgroundTransparency = 0.15,
		ZIndex = 2,
		Parent = self.Page,
	})
	Utility.AddCorner(card, THEME.CornerRadius.Section)
	Utility.AddStroke(card, THEME.Colors.Border, 1, 0.2)
	Utility.AddPadding(card, 10, 10, 10, 10)
	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = card,
	})
	self.Window:_RegisterFrame(card, 0.15)

	if secTitle ~= "" then
		local secHeader = Utility.Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = THEME.Fonts.Bold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = THEME.Colors.Accent,
			Text = string.upper(secTitle),
			ZIndex = 3,
			Parent = card,
		})
		self.Window:_RegisterThemeUpdater(function(accent)
			secHeader.TextColor3 = accent
		end)
	end

	local contentParent
	if maxHeight then
		contentParent = Utility.Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, maxHeight),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = THEME.Colors.Accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = 3,
			Parent = card,
		})
		self.Window:_RegisterThemeUpdater(function(accent)
			contentParent.ScrollBarImageColor3 = accent
		end)
	else
		contentParent = Utility.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = card,
		})
	end

	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = contentParent,
	})

	secObj.Container = contentParent
	table.insert(self.Sections, secObj)
	return secObj
end
Tab.AddSection = Tab.CreateSection

function Tab:_GetDefaultSection()
	if not self._defaultSection then
		self._defaultSection = self:CreateSection({ Title = "Controls" })
	end
	return self._defaultSection
end

--// [Requirement 2] UI Element 1: Toggle (Custom ImageLabel Knob)
function Section:AddToggle(opts, defaultArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Toggle"),
		Default = defaultArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or cfg.Name or "Toggle"
	local defaultVal = (cfg.Default == true)
	local flag = cfg.Flag or title

	local ctrl = BaseControl.new(defaultVal, "Toggle", cfg.Callback)

	local row = Utility.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Colors.Element,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(row, THEME.CornerRadius.Element)
	Utility.AddStroke(row, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(row, 0)

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		ZIndex = 4,
		Parent = row,
	})

	local switchBg = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = THEME.Colors.Sidebar,
		ZIndex = 4,
		Parent = row,
	})
	Utility.AddCorner(switchBg, THEME.CornerRadius.Pill)
	local switchStroke = Utility.AddStroke(switchBg, THEME.Colors.Border, 1, 0.2)
	self.Window:_RegisterFrame(switchBg, 0)

	-- Custom Toggle Knob ImageLabel
	local knob = Utility.Create("ImageLabel", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = ASSETS.ToggleKnob,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
		Parent = switchBg,
	})
	Utility.AddCorner(knob, THEME.CornerRadius.Pill)

	ctrl._applyVisual = function(state)
		Utility.Tween(switchBg, THEME.Tween.Fast, {
			BackgroundColor3 = state and THEME.Colors.Accent or THEME.Colors.Sidebar,
		})
		Utility.Tween(switchStroke, THEME.Tween.Fast, {
			Color = state and THEME.Colors.Accent or THEME.Colors.Border,
		})
		Utility.Tween(knob, THEME.Tween.Fast, {
			Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		})
	end
	ctrl._applyVisual(defaultVal)

	self.Window:_RegisterThemeUpdater(function()
		ctrl._applyVisual(ctrl:GetValue())
	end)

	row.MouseEnter:Connect(function()
		Utility.Tween(row, THEME.Tween.Fast, { BackgroundColor3 = THEME.Colors.ElementHover })
	end)
	row.MouseLeave:Connect(function()
		Utility.Tween(row, THEME.Tween.Fast, { BackgroundColor3 = THEME.Colors.Element })
	end)
	row.MouseButton1Click:Connect(function()
		ctrl:SetValue(not ctrl:GetValue())
	end)

	self.Window:AttachTooltip(row, cfg.Tooltip)
	self.Window.ConfigManager:Register(flag, ctrl)
	return ctrl
end

--// UI Element 2: Slider (Min/Max, Decimals, Editable TextBox Input)
function Section:AddSlider(opts, minArg, maxArg, defaultArg, decimalsArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Slider"),
		Min = minArg,
		Max = maxArg,
		Default = defaultArg,
		Decimals = decimalsArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or cfg.Name or "Slider"
	local minVal = tonumber(cfg.Min) or 0
	local maxVal = tonumber(cfg.Max) or 100
	local decimals = tonumber(cfg.Decimals) or 0
	local defaultVal = math.clamp(tonumber(cfg.Default) or minVal, minVal, maxVal)
	local suffix = cfg.Suffix or ""
	local flag = cfg.Flag or title

	local ctrl = BaseControl.new(Utility.Round(defaultVal, decimals), "Slider", cfg.Callback)

	local box = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = THEME.Colors.Element,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(box, THEME.CornerRadius.Element)
	Utility.AddStroke(box, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(box, 0)

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -92, 0, 20),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		ZIndex = 4,
		Parent = box,
	})

	local valueInput = Utility.Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(64, 20),
		BackgroundColor3 = THEME.Colors.Sidebar,
		Font = THEME.Fonts.Mono,
		TextSize = 12,
		TextColor3 = THEME.Colors.Accent,
		ClearTextOnFocus = false,
		Text = tostring(ctrl:GetValue()) .. suffix,
		ZIndex = 4,
		Parent = box,
	})
	Utility.AddCorner(valueInput, THEME.CornerRadius.Small)
	Utility.AddStroke(valueInput, THEME.Colors.Border, 1, 0.4)
	self.Window:_RegisterFrame(valueInput, 0)

	local track = Utility.Create("Frame", {
		Position = UDim2.fromOffset(12, 35),
		Size = UDim2.new(1, -24, 0, 6),
		BackgroundColor3 = THEME.Colors.Sidebar,
		ZIndex = 4,
		Parent = box,
	})
	Utility.AddCorner(track, THEME.CornerRadius.Pill)
	self.Window:_RegisterFrame(track, 0)

	local fill = Utility.Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = THEME.Colors.Accent,
		ZIndex = 5,
		Parent = track,
	})
	Utility.AddCorner(fill, THEME.CornerRadius.Pill)

	local thumb = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = THEME.Colors.Text,
		ZIndex = 6,
		Parent = track,
	})
	Utility.AddCorner(thumb, THEME.CornerRadius.Pill)

	self.Window:_RegisterThemeUpdater(function(accent)
		fill.BackgroundColor3 = accent
		valueInput.TextColor3 = accent
	end)

	ctrl._applyVisual = function(val)
		local clamped = Utility.Round(math.clamp(tonumber(val) or minVal, minVal, maxVal), decimals)
		ctrl._value = clamped
		local alpha = (maxVal > minVal) and ((clamped - minVal) / (maxVal - minVal)) or 0
		Utility.Tween(fill, THEME.Tween.Fast, { Size = UDim2.fromScale(alpha, 1) })
		Utility.Tween(thumb, THEME.Tween.Fast, { Position = UDim2.fromScale(alpha, 0.5) })
		valueInput.Text = string.format("%." .. tostring(decimals) .. "f", clamped) .. suffix
	end
	ctrl._applyVisual(defaultVal)

	local sliding = false
	local slidePointer = nil
	local isMouseSlide = false

	local function UpdateFromX(screenX)
		local rel = math.clamp((screenX - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		local raw = minVal + (maxVal - minVal) * rel
		ctrl:SetValue(Utility.Round(raw, decimals))
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			slidePointer = input
			isMouseSlide = (input.UserInputType == Enum.UserInputType.MouseButton1)
			UpdateFromX(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					sliding = false
					slidePointer = nil
				end
			end)
		end
	end)

	table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
		if sliding and (input == slidePointer or (isMouseSlide and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			UpdateFromX(input.Position.X)
		end
	end))

	valueInput.FocusLost:Connect(function()
		local cleaned = valueInput.Text:gsub("[^%d%.%-]", "")
		local parsed = tonumber(cleaned)
		if parsed then
			ctrl:SetValue(Utility.Round(math.clamp(parsed, minVal, maxVal), decimals))
		else
			ctrl._applyVisual(ctrl:GetValue())
		end
	end)

	self.Window:AttachTooltip(box, cfg.Tooltip)
	self.Window.ConfigManager:Register(flag, ctrl)
	return ctrl
end

--// UI Element 3: Dropdown (Scrollable, Searchable, Single & Multi-Select)
function Section:AddDropdown(opts, optionsArg, defaultArg, multiArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Dropdown"),
		Options = optionsArg,
		Default = defaultArg,
		Multi = multiArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or cfg.Name or "Dropdown"
	local options = cfg.Options or {}
	local isMulti = (cfg.Multi == true)
	local flag = cfg.Flag or title

	local initialVal
	if isMulti then
		initialVal = {}
		if type(cfg.Default) == "table" then
			for k, v in pairs(cfg.Default) do
				if type(k) == "number" then
					initialVal[tostring(v)] = true
				elseif v == true then
					initialVal[tostring(k)] = true
				end
			end
		end
	else
		initialVal = cfg.Default or options[1] or ""
	end

	local ctrl = BaseControl.new(initialVal, "Dropdown", cfg.Callback)
	local expanded = false

	local container = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = THEME.Colors.Element,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(container, THEME.CornerRadius.Element)
	Utility.AddStroke(container, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(container, 0)

	local headerBtn = Utility.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 4,
		Parent = container,
	})

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.45, -12, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		ZIndex = 4,
		Parent = headerBtn,
	})

	local selectedLabel = Utility.Create("TextLabel", {
		Position = UDim2.new(0.45, 0, 0, 0),
		Size = UDim2.new(0.55, -30, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.SemiBold,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = THEME.Colors.Accent,
		Text = "",
		ZIndex = 4,
		Parent = headerBtn,
	})

	local arrow = Utility.Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Bold,
		TextSize = 12,
		TextColor3 = THEME.Colors.SubText,
		Text = "▾",
		ZIndex = 4,
		Parent = headerBtn,
	})

	local searchBox = Utility.Create("TextBox", {
		Position = UDim2.fromOffset(8, 42),
		Size = UDim2.new(1, -16, 0, 26),
		BackgroundColor3 = THEME.Colors.DropdownBg,
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextColor3 = THEME.Colors.Text,
		PlaceholderText = "Search options...",
		PlaceholderColor3 = THEME.Colors.Muted,
		ClearTextOnFocus = false,
		Text = "",
		ZIndex = 4,
		Parent = container,
	})
	Utility.AddCorner(searchBox, THEME.CornerRadius.Small)
	Utility.AddPadding(searchBox, 0, 0, 8, 8)
	Utility.AddStroke(searchBox, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(searchBox, 0)

	local listScroll = Utility.Create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 74),
		Size = UDim2.new(1, -16, 0, 112),
		BackgroundColor3 = THEME.Colors.DropdownBg,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = THEME.Colors.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 4,
		Parent = container,
	})
	Utility.AddCorner(listScroll, THEME.CornerRadius.Small)
	Utility.AddPadding(listScroll, 4, 4, 4, 4)
	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listScroll,
	})
	self.Window:_RegisterFrame(listScroll, 0)

	local optionButtons = {}

	local function FormatDisplay(val)
		if isMulti then
			local picked = {}
			if type(val) == "table" then
				for _, opt in ipairs(options) do
					if val[tostring(opt)] then
						table.insert(picked, tostring(opt))
					end
				end
			end
			return (#picked > 0) and table.concat(picked, ", ") or "None"
		end
		return (val ~= nil and tostring(val) ~= "") and tostring(val) or "None"
	end

	local function RefreshHighlights()
		local cur = ctrl:GetValue()
		selectedLabel.Text = FormatDisplay(cur)
		selectedLabel.TextColor3 = THEME.Colors.Accent
		listScroll.ScrollBarImageColor3 = THEME.Colors.Accent
		for optName, btnRefs in pairs(optionButtons) do
			local active = isMulti and (type(cur) == "table" and cur[optName] == true) or (tostring(cur) == optName)
			btnRefs.Label.TextColor3 = active and THEME.Colors.Accent or THEME.Colors.SubText
			btnRefs.Check.TextColor3 = THEME.Colors.Accent
			btnRefs.Check.Text = active and "✓" or ""
		end
	end

	self.Window:_RegisterThemeUpdater(function()
		RefreshHighlights()
	end)

	local function RebuildOptions()
		for _, child in ipairs(listScroll:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		table.clear(optionButtons)
		local query = string.lower(searchBox.Text or "")
		for _, opt in ipairs(options) do
			local optStr = tostring(opt)
			if query == "" or string.find(string.lower(optStr), query, 1, true) then
				local itemBtn = Utility.Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = THEME.Colors.Element,
					BackgroundTransparency = 0.35,
					AutoButtonColor = false,
					Text = "",
					ZIndex = 5,
					Parent = listScroll,
				})
				Utility.AddCorner(itemBtn, THEME.CornerRadius.Small)
				local lbl = Utility.Create("TextLabel", {
					Position = UDim2.fromOffset(8, 0),
					Size = UDim2.new(1, -28, 1, 0),
					BackgroundTransparency = 1,
					Font = THEME.Fonts.Regular,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = THEME.Colors.SubText,
					Text = optStr,
					ZIndex = 6,
					Parent = itemBtn,
				})
				local chk = Utility.Create("TextLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Font = THEME.Fonts.Bold,
					TextSize = 12,
					TextColor3 = THEME.Colors.Accent,
					Text = "",
					ZIndex = 6,
					Parent = itemBtn,
				})
				optionButtons[optStr] = { Button = itemBtn, Label = lbl, Check = chk }

				itemBtn.MouseButton1Click:Connect(function()
					if isMulti then
						local nextTbl = {}
						for k, v in pairs(ctrl:GetValue() or {}) do
							nextTbl[k] = v
						end
						nextTbl[optStr] = not nextTbl[optStr] or nil
						ctrl:SetValue(nextTbl)
					else
						ctrl:SetValue(optStr)
						expanded = false
						Utility.Tween(container, THEME.Tween.Normal, { Size = UDim2.new(1, 0, 0, 38) })
						arrow.Text = "▾"
					end
				end)
			end
		end
		RefreshHighlights()
	end

	ctrl._applyVisual = function()
		RefreshHighlights()
	end

	function ctrl:Refresh(newOptions, keepCurrent)
		options = newOptions or {}
		if not keepCurrent then
			ctrl:SetValue(isMulti and {} or (options[1] or ""), true)
		end
		RebuildOptions()
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(RebuildOptions)
	headerBtn.MouseButton1Click:Connect(function()
		expanded = not expanded
		arrow.Text = expanded and "▴" or "▾"
		Utility.Tween(container, THEME.Tween.Normal, {
			Size = expanded and UDim2.new(1, 0, 0, 194) or UDim2.new(1, 0, 0, 38),
		})
	end)

	RebuildOptions()
	self.Window:AttachTooltip(headerBtn, cfg.Tooltip)
	self.Window.ConfigManager:Register(flag, ctrl)
	return ctrl
end

--// UI Element 4: Color Picker (HSV Pad + Hue Slider + RGB Sliders + Preview)
function Section:AddColorPicker(opts, defaultColorArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Color Picker"),
		Default = defaultColorArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or cfg.Name or "Color Picker"
	local defaultColor = (typeof(cfg.Default) == "Color3") and cfg.Default or THEME.Colors.Accent
	local flag = cfg.Flag or title

	local ctrl = BaseControl.new(defaultColor, "ColorPicker", cfg.Callback)
	local h, s, v = defaultColor:ToHSV()
	local open = false

	local container = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = THEME.Colors.Element,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(container, THEME.CornerRadius.Element)
	Utility.AddStroke(container, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(container, 0)

	local header = Utility.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 4,
		Parent = container,
	})

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -120, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		ZIndex = 4,
		Parent = header,
	})

	local hexLabel = Utility.Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -44, 0.5, 0),
		Size = UDim2.fromOffset(62, 18),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Mono,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = THEME.Colors.SubText,
		Text = Utility.ColorToHex(defaultColor),
		ZIndex = 4,
		Parent = header,
	})

	local preview = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(24, 18),
		BackgroundColor3 = defaultColor,
		ZIndex = 4,
		Parent = header,
	})
	Utility.AddCorner(preview, THEME.CornerRadius.Small)
	Utility.AddStroke(preview, THEME.Colors.Border, 1, 0.2)

	-- Saturation/Value 2D Box
	local svBox = Utility.Create("Frame", {
		Position = UDim2.fromOffset(12, 44),
		Size = UDim2.new(1, -50, 0, 96),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		ZIndex = 4,
		Parent = container,
	})
	Utility.AddCorner(svBox, THEME.CornerRadius.Small)

	local satOverlay = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = svBox,
	})
	Utility.AddCorner(satOverlay, THEME.CornerRadius.Small)
	Utility.Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = satOverlay,
	})

	local valOverlay = Utility.Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = svBox,
	})
	Utility.AddCorner(valOverlay, THEME.CornerRadius.Small)
	Utility.Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = valOverlay,
	})

	local svCursor = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(s, 1 - v),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 7,
		Parent = svBox,
	})
	Utility.AddCorner(svCursor, THEME.CornerRadius.Pill)
	Utility.AddStroke(svCursor, Color3.new(0, 0, 0), 1, 0)

	-- Vertical Hue Bar
	local hueBar = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 44),
		Size = UDim2.fromOffset(18, 96),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 4,
		Parent = container,
	})
	Utility.AddCorner(hueBar, THEME.CornerRadius.Small)
	Utility.Create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueBar,
	})

	local hueCursor = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, h),
		Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
		Parent = hueBar,
	})
	Utility.AddStroke(hueCursor, Color3.new(0, 0, 0), 1, 0)

	-- RGB Mini Sliders
	local rgbBars = {}
	local channels = {
		{ Name = "R", Y = 148, Color = Color3.fromRGB(255, 75, 90) },
		{ Name = "G", Y = 168, Color = Color3.fromRGB(46, 213, 115) },
		{ Name = "B", Y = 188, Color = Color3.fromRGB(0, 190, 255) },
	}

	for idx, ch in ipairs(channels) do
		Utility.Create("TextLabel", {
			Position = UDim2.fromOffset(12, ch.Y - 3),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			Font = THEME.Fonts.Bold,
			TextSize = 11,
			TextColor3 = ch.Color,
			Text = ch.Name,
			ZIndex = 4,
			Parent = container,
		})
		local cTrack = Utility.Create("Frame", {
			Position = UDim2.fromOffset(30, ch.Y + 2),
			Size = UDim2.new(1, -76, 0, 5),
			BackgroundColor3 = THEME.Colors.Sidebar,
			ZIndex = 4,
			Parent = container,
		})
		Utility.AddCorner(cTrack, THEME.CornerRadius.Pill)
		local cFill = Utility.Create("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = ch.Color,
			ZIndex = 5,
			Parent = cTrack,
		})
		Utility.AddCorner(cFill, THEME.CornerRadius.Pill)
		local cNum = Utility.Create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, ch.Y - 3),
			Size = UDim2.fromOffset(30, 14),
			BackgroundTransparency = 1,
			Font = THEME.Fonts.Mono,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = THEME.Colors.SubText,
			Text = "0",
			ZIndex = 4,
			Parent = container,
		})
		rgbBars[idx] = { Track = cTrack, Fill = cFill, Label = cNum }

		local draggingChannel = false
		local chPointer = nil
		local isMouseCh = false
		local function UpdateChannel(screenX)
			local alpha = math.clamp((screenX - cTrack.AbsolutePosition.X) / math.max(1, cTrack.AbsoluteSize.X), 0, 1)
			local cur = ctrl:GetValue()
			local r, g, b = cur.R, cur.G, cur.B
			if idx == 1 then r = alpha elseif idx == 2 then g = alpha else b = alpha end
			local nextC = Color3.new(r, g, b)
			local nh, ns, nv = nextC:ToHSV()
			if ns > 0 and nv > 0 then h = nh end
			s, v = ns, nv
			ctrl:SetValue(nextC)
		end

		cTrack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingChannel = true
				chPointer = input
				isMouseCh = (input.UserInputType == Enum.UserInputType.MouseButton1)
				UpdateChannel(input.Position.X)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						draggingChannel = false
						chPointer = nil
					end
				end)
			end
		end)
		table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
			if draggingChannel and (input == chPointer or (isMouseCh and input.UserInputType == Enum.UserInputType.MouseMovement)) then
				UpdateChannel(input.Position.X)
			end
		end))
	end

	ctrl._applyVisual = function(c)
		if typeof(c) ~= "Color3" then
			return
		end
		local nh, ns, nv = c:ToHSV()
		if ns > 0.001 and nv > 0.001 then
			h = nh
		end
		s, v = ns, nv
		preview.BackgroundColor3 = c
		hexLabel.Text = Utility.ColorToHex(c)
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.fromScale(0.5, h)

		local comps = { c.R, c.G, c.B }
		for i = 1, 3 do
			rgbBars[i].Fill.Size = UDim2.fromScale(comps[i], 1)
			rgbBars[i].Label.Text = tostring(math.round(comps[i] * 255))
		end
	end
	ctrl._applyVisual(defaultColor)

	local dragSV, dragHue = false, false
	local svPtr, huePtr = nil, nil
	local mouseSV, mouseHue = false, false

	local function UpdateSV(pos)
		s = math.clamp((pos.X - svBox.AbsolutePosition.X) / math.max(1, svBox.AbsoluteSize.X), 0, 1)
		v = 1 - math.clamp((pos.Y - svBox.AbsolutePosition.Y) / math.max(1, svBox.AbsoluteSize.Y), 0, 1)
		ctrl:SetValue(Color3.fromHSV(h, s, v))
	end

	local function UpdateHue(pos)
		h = math.clamp((pos.Y - hueBar.AbsolutePosition.Y) / math.max(1, hueBar.AbsoluteSize.Y), 0, 1)
		ctrl:SetValue(Color3.fromHSV(h, s, v))
	end

	svBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragSV, svPtr, mouseSV = true, input, (input.UserInputType == Enum.UserInputType.MouseButton1)
			UpdateSV(input.Position)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragSV, svPtr = false, nil end
			end)
		end
	end)

	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragHue, huePtr, mouseHue = true, input, (input.UserInputType == Enum.UserInputType.MouseButton1)
			UpdateHue(input.Position)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragHue, huePtr = false, nil end
			end)
		end
	end)

	table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
		if dragSV and (input == svPtr or (mouseSV and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			UpdateSV(input.Position)
		elseif dragHue and (input == huePtr or (mouseHue and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			UpdateHue(input.Position)
		end
	end))

	header.MouseButton1Click:Connect(function()
		open = not open
		Utility.Tween(container, THEME.Tween.Normal, {
			Size = open and UDim2.new(1, 0, 0, 212) or UDim2.new(1, 0, 0, 38),
		})
	end)

	self.Window:AttachTooltip(header, cfg.Tooltip)
	self.Window.ConfigManager:Register(flag, ctrl)
	return ctrl
end

--// UI Element 5: Keybind (Click to Bind, Returns Enum.KeyCode)
function Section:AddKeybind(opts, defaultKeyArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Keybind"),
		Default = defaultKeyArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or cfg.Name or "Keybind"
	local defaultKey = (typeof(cfg.Default) == "EnumItem") and cfg.Default or Enum.KeyCode.E
	local flag = cfg.Flag or title

	local ctrl = BaseControl.new(defaultKey, "Keybind", cfg.Callback)
	local binding = false

	local row = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Colors.Element,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(row, THEME.CornerRadius.Element)
	Utility.AddStroke(row, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(row, 0)

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		ZIndex = 4,
		Parent = row,
	})

	local bindBtn = Utility.Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(82, 22),
		BackgroundColor3 = THEME.Colors.Sidebar,
		AutoButtonColor = false,
		Font = THEME.Fonts.Mono,
		TextSize = 11,
		TextColor3 = THEME.Colors.Accent,
		Text = "[" .. Utility.FormatKey(defaultKey) .. "]",
		ZIndex = 4,
		Parent = row,
	})
	Utility.AddCorner(bindBtn, THEME.CornerRadius.Small)
	local bindStroke = Utility.AddStroke(bindBtn, THEME.Colors.Border, 1, 0.3)
	self.Window:_RegisterFrame(bindBtn, 0)

	self.Window:_RegisterThemeUpdater(function(accent)
		bindBtn.TextColor3 = accent
	end)

	ctrl._applyVisual = function(keyItem)
		bindBtn.Text = "[" .. Utility.FormatKey(keyItem) .. "]"
		bindStroke.Color = THEME.Colors.Border
	end

	bindBtn.MouseButton1Click:Connect(function()
		binding = true
		bindBtn.Text = "[ ... ]"
		bindStroke.Color = THEME.Colors.Accent
	end)

	table.insert(self.Window._connections, UserInputService.InputBegan:Connect(function(input, gpe)
		if binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				binding = false
				local chosen = (input.KeyCode == Enum.KeyCode.Escape) and Enum.KeyCode.Unknown or input.KeyCode
				ctrl:SetValue(chosen)
			end
			return
		end
		if not gpe and UserInputService:GetFocusedTextBox() == nil then
			if input.KeyCode == ctrl:GetValue() and ctrl:GetValue() ~= Enum.KeyCode.Unknown then
				if type(cfg.OnPressed) == "function" then
					task.spawn(cfg.OnPressed, ctrl:GetValue())
				end
			end
		end
	end))

	self.Window:AttachTooltip(row, cfg.Tooltip)
	self.Window.ConfigManager:Register(flag, ctrl)
	return ctrl
end

--// UI Element 6: Textbox (Supports Standard & Obscured Password Mode)
function Section:AddTextbox(opts, placeholderArg, passwordArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Textbox"),
		Placeholder = placeholderArg,
		Password = passwordArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or cfg.Name or "Textbox"
	local placeholder = cfg.Placeholder or "Enter text..."
	local isPassword = (cfg.Password == true)
	local defaultText = tostring(cfg.Default or "")
	local flag = cfg.Flag or title

	local ctrl = BaseControl.new(defaultText, "Textbox", cfg.Callback)
	local revealPassword = false

	local box = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = THEME.Colors.Element,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(box, THEME.CornerRadius.Element)
	Utility.AddStroke(box, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(box, 0)

	Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(12, 5),
		Size = UDim2.new(1, -60, 0, 18),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.SubText,
		Text = title,
		ZIndex = 4,
		Parent = box,
	})

	local inputHolder = Utility.Create("Frame", {
		Position = UDim2.fromOffset(10, 26),
		Size = UDim2.new(1, -20, 0, 26),
		BackgroundColor3 = THEME.Colors.Sidebar,
		ClipsDescendants = true,
		ZIndex = 4,
		Parent = box,
	})
	Utility.AddCorner(inputHolder, THEME.CornerRadius.Small)
	local inputStroke = Utility.AddStroke(inputHolder, THEME.Colors.Border, 1, 0.35)
	self.Window:_RegisterFrame(inputHolder, 0)

	local rightOffset = isPassword and 32 or 8
	local maskLabel = Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -(8 + rightOffset), 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Visible = isPassword,
		Text = "",
		ZIndex = 5,
		Parent = inputHolder,
	})

	local realInput = Utility.Create("TextBox", {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -(8 + rightOffset), 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		TextTransparency = isPassword and 1 or 0,
		PlaceholderText = isPassword and "" or placeholder,
		PlaceholderColor3 = THEME.Colors.Muted,
		ClearTextOnFocus = false,
		Text = defaultText,
		ZIndex = 5,
		Parent = inputHolder,
	})

	local function SyncMask()
		local txt = realInput.Text
		if isPassword and not revealPassword then
			realInput.TextTransparency = 1
			maskLabel.Visible = true
			if #txt == 0 then
				maskLabel.TextColor3 = THEME.Colors.Muted
				maskLabel.Text = placeholder
			else
				maskLabel.TextColor3 = THEME.Colors.Text
				local count = utf8.len(txt) or #txt
				maskLabel.Text = string.rep("•", count)
			end
		else
			realInput.TextTransparency = 0
			realInput.PlaceholderText = placeholder
			maskLabel.Visible = false
		end
	end

	if isPassword then
		local eyeBtn = Utility.Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.fromOffset(24, 20),
			BackgroundTransparency = 1,
			Font = THEME.Fonts.Bold,
			TextSize = 11,
			TextColor3 = THEME.Colors.SubText,
			Text = "👁",
			ZIndex = 6,
			Parent = inputHolder,
		})
		eyeBtn.MouseButton1Click:Connect(function()
			revealPassword = not revealPassword
			eyeBtn.TextColor3 = revealPassword and THEME.Colors.Accent or THEME.Colors.SubText
			SyncMask()
		end)
	end

	ctrl._applyVisual = function(val)
		realInput.Text = tostring(val or "")
		SyncMask()
	end
	SyncMask()

	realInput:GetPropertyChangedSignal("Text"):Connect(SyncMask)
	realInput.Focused:Connect(function()
		Utility.Tween(inputStroke, THEME.Tween.Fast, { Color = THEME.Colors.Accent })
	end)
	realInput.FocusLost:Connect(function()
		Utility.Tween(inputStroke, THEME.Tween.Fast, { Color = THEME.Colors.Border })
		ctrl:SetValue(realInput.Text)
	end)

	self.Window:AttachTooltip(box, cfg.Tooltip)
	self.Window.ConfigManager:Register(flag, ctrl)
	return ctrl
end

--// UI Element 7: Button (Supports Text + Optional Left/Right Icons)
function Section:AddButton(opts, callbackArg, iconArg, iconPosArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Button"),
		Callback = callbackArg,
		Icon = iconArg,
		IconPosition = iconPosArg,
	}
	local title = cfg.Title or cfg.Name or "Button"
	local icon = cfg.Icon or ""
	local iconPos = (cfg.IconPosition == "Right") and "Right" or "Left"

	local ctrl = BaseControl.new(0, "Button", cfg.Callback)

	local btn = Utility.Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Colors.Element,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(btn, THEME.CornerRadius.Element)
	local stroke = Utility.AddStroke(btn, THEME.Colors.Border, 1, 0.4)
	self.Window:_RegisterFrame(btn, 0)

	local hasIcon = (icon ~= "")
	local iconImg = nil
	if hasIcon then
		iconImg = Utility.Create("ImageLabel", {
			AnchorPoint = Vector2.new(iconPos == "Right" and 1 or 0, 0.5),
			Position = iconPos == "Right" and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Image = icon,
			ImageColor3 = THEME.Colors.Accent,
			ZIndex = 4,
			Parent = btn,
		})
		self.Window:_RegisterThemeUpdater(function(accent)
			iconImg.ImageColor3 = accent
		end)
	end

	local lbl = Utility.Create("TextLabel", {
		Position = UDim2.fromOffset(hasIcon and iconPos == "Left" and 34 or 12, 0),
		Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.Fonts.SemiBold,
		TextSize = 13,
		TextXAlignment = hasIcon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
		TextColor3 = THEME.Colors.Text,
		Text = title,
		ZIndex = 4,
		Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		Utility.Tween(btn, THEME.Tween.Fast, { BackgroundColor3 = THEME.Colors.ElementHover })
		Utility.Tween(stroke, THEME.Tween.Fast, { Color = THEME.Colors.Accent })
	end)
	btn.MouseLeave:Connect(function()
		Utility.Tween(btn, THEME.Tween.Fast, { BackgroundColor3 = THEME.Colors.Element })
		Utility.Tween(stroke, THEME.Tween.Fast, { Color = THEME.Colors.Border })
	end)
	btn.MouseButton1Click:Connect(function()
		Utility.Tween(lbl, THEME.Tween.Fast, { TextColor3 = THEME.Colors.Accent })
		task.delay(0.15, function()
			Utility.Tween(lbl, THEME.Tween.Fast, { TextColor3 = THEME.Colors.Text })
		end)
		ctrl:SetValue((tonumber(ctrl:GetValue()) or 0) + 1)
	end)

	self.Window:AttachTooltip(btn, cfg.Tooltip)
	return ctrl
end

--// UI Element 8a: Dedicated Image Element
function Section:AddImage(opts, imageArg, heightArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or ""),
		Image = imageArg or tostring(opts or ""),
		Height = heightArg,
	}
	local asset = cfg.Image or ASSETS.WindowLogo
	local height = tonumber(cfg.Height) or 96
	local caption = cfg.Title or ""

	local ctrl = BaseControl.new(asset, "Image", cfg.Callback)

	local frame = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, height + (caption ~= "" and 24 or 12)),
		BackgroundColor3 = THEME.Colors.Element,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(frame, THEME.CornerRadius.Element)
	Utility.AddStroke(frame, THEME.Colors.Border, 1, 0.5)
	self.Window:_RegisterFrame(frame, 0)

	local img = Utility.Create("ImageLabel", {
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 0, height),
		BackgroundTransparency = 1,
		Image = asset,
		ScaleType = cfg.ScaleType or Enum.ScaleType.Fit,
		ZIndex = 4,
		Parent = frame,
	})

	if caption ~= "" then
		Utility.Create("TextLabel", {
			Position = UDim2.fromOffset(10, height + 6),
			Size = UDim2.new(1, -20, 0, 16),
			BackgroundTransparency = 1,
			Font = THEME.Fonts.Regular,
			TextSize = 11,
			TextColor3 = THEME.Colors.SubText,
			Text = caption,
			ZIndex = 4,
			Parent = frame,
		})
	end

	ctrl._applyVisual = function(newAsset)
		img.Image = tostring(newAsset)
	end

	self.Window:AttachTooltip(frame, cfg.Tooltip)
	return ctrl
end

--// UI Element 8b: Dedicated Clickable ImageButton Element
function Section:AddImageButton(opts, imageArg, callbackArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Image Action"),
		Image = imageArg,
		Callback = callbackArg,
	}
	local title = cfg.Title or ""
	local asset = cfg.Image or ASSETS.WindowLogo
	local height = tonumber(cfg.Height) or 64

	local ctrl = BaseControl.new(0, "ImageButton", cfg.Callback)

	local btn = Utility.Create("ImageButton", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = THEME.Colors.Element,
		AutoButtonColor = false,
		Image = asset,
		ScaleType = cfg.ScaleType or Enum.ScaleType.Fit,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(btn, THEME.CornerRadius.Element)
	local stroke = Utility.AddStroke(btn, THEME.Colors.Border, 1, 0.4)
	self.Window:_RegisterFrame(btn, 0)

	if title ~= "" then
		Utility.Create("TextLabel", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 8, 1, -4),
			Size = UDim2.new(1, -16, 0, 16),
			BackgroundTransparency = 1,
			Font = THEME.Fonts.SemiBold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = THEME.Colors.Text,
			Text = title,
			ZIndex = 4,
			Parent = btn,
		})
	end

	btn.MouseEnter:Connect(function()
		Utility.Tween(btn, THEME.Tween.Fast, { BackgroundColor3 = THEME.Colors.ElementHover })
		Utility.Tween(stroke, THEME.Tween.Fast, { Color = THEME.Colors.Accent })
	end)
	btn.MouseLeave:Connect(function()
		Utility.Tween(btn, THEME.Tween.Fast, { BackgroundColor3 = THEME.Colors.Element })
		Utility.Tween(stroke, THEME.Tween.Fast, { Color = THEME.Colors.Border })
	end)
	btn.MouseButton1Click:Connect(function()
		ctrl:SetValue((tonumber(ctrl:GetValue()) or 0) + 1)
	end)

	self.Window:AttachTooltip(btn, cfg.Tooltip)
	return ctrl
end

--// UI Element 9a: Label (RichText + WordWrap)
function Section:AddLabel(textOrOpts)
	local cfg = type(textOrOpts) == "table" and textOrOpts or { Text = tostring(textOrOpts or "") }
	local txt = cfg.Text or cfg.Title or ""
	local ctrl = BaseControl.new(txt, "Label", cfg.Callback)

	local lbl = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 13,
		RichText = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = txt,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddPadding(lbl, 3, 3, 4, 4)

	ctrl._applyVisual = function(newText)
		lbl.Text = tostring(newText)
	end
	function ctrl:SetText(newText)
		return self:SetValue(newText)
	end

	return ctrl
end

--// UI Element 9b: Paragraph (RichText + WordWrap)
function Section:AddParagraph(opts, contentArg)
	local cfg = type(opts) == "table" and opts or {
		Title = tostring(opts or "Information"),
		Content = tostring(contentArg or ""),
	}
	local heading = cfg.Title or "Information"
	local body = cfg.Content or cfg.Text or ""

	local ctrl = BaseControl.new(body, "Paragraph", cfg.Callback)

	local card = Utility.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Colors.Element,
		ZIndex = 3,
		Parent = self.Container,
	})
	Utility.AddCorner(card, THEME.CornerRadius.Element)
	Utility.AddStroke(card, THEME.Colors.Border, 1, 0.5)
	Utility.AddPadding(card, 8, 8, 10, 10)
	Utility.Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = card,
	})
	self.Window:_RegisterFrame(card, 0)

	local titleLbl = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Bold,
		TextSize = 13,
		RichText = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.Text,
		Text = heading,
		ZIndex = 4,
		Parent = card,
	})

	local bodyLbl = Utility.Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = THEME.Fonts.Regular,
		TextSize = 12,
		RichText = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Colors.SubText,
		Text = body,
		ZIndex = 4,
		Parent = card,
	})

	ctrl._applyVisual = function(val)
		if type(val) == "table" then
			titleLbl.Text = tostring(val.Title or heading)
			bodyLbl.Text = tostring(val.Content or "")
		else
			bodyLbl.Text = tostring(val)
		end
	end

	return ctrl
end

-- Forward direct Tab:Add* calls seamlessly to a default Section
for _, methodName in ipairs({
	"AddToggle",
	"AddSlider",
	"AddDropdown",
	"AddColorPicker",
	"AddKeybind",
	"AddTextbox",
	"AddButton",
	"AddImage",
	"AddImageButton",
	"AddLabel",
	"AddParagraph",
}) do
	Tab[methodName] = function(self, ...)
		return self:_GetDefaultSection()[methodName](self:_GetDefaultSection(), ...)
	end
end

--// Built-In Config Tab Generator (Save, Load, Delete, Refresh + Live Theme/Transparency)
function Window:CreateConfigTab(tabTitle)
	local cfgTab = self:CreateTab({
		Title = tabTitle or "Configs",
		Icon = "rbxassetid://10734950309",
		IconPosition = "Left",
	})

	local sec = cfgTab:CreateSection("Configuration Profiles")
	local nameBox = sec:AddTextbox({
		Title = "New / Target Config Name",
		Placeholder = "e.g. tournament_profile",
		Default = "default",
		Flag = "",
		Tooltip = "Type a profile name to save or overwrite",
	})

	local existingDropdown = sec:AddDropdown({
		Title = "Saved Profiles",
		Options = self.ConfigManager:List(),
		Default = "default",
		Flag = "",
		Tooltip = "Select an existing JSON config file",
		Callback = function(selected)
			if selected and selected ~= "" then
				nameBox:SetValue(selected, true)
			end
		end,
	})

	sec:AddButton({
		Title = "Save Config",
		Icon = "rbxassetid://10734941499",
		IconPosition = "Left",
		Tooltip = "Write all registered element states to JSON",
		Callback = function()
			local target = nameBox:GetValue()
			local ok, err = self.ConfigManager:Save(target)
			existingDropdown:Refresh(self.ConfigManager:List(), true)
			self:Notify({
				Title = ok and "Config Saved" or "Save Failed",
				Content = ok and ("Saved profile '" .. target .. ".json'") or tostring(err),
				Type = ok and "Success" or "Error",
			})
		end,
	})

	sec:AddButton({
		Title = "Load Selected Config",
		Icon = "rbxassetid://10723407389",
		IconPosition = "Left",
		Tooltip = "Restore all UI elements from JSON",
		Callback = function()
			local target = nameBox:GetValue()
			local ok, err = self.ConfigManager:Load(target)
			self:Notify({
				Title = ok and "Config Loaded" or "Load Failed",
				Content = ok and ("Applied profile '" .. target .. ".json'") or tostring(err),
				Type = ok and "Info" or "Warning",
			})
		end,
	})

	sec:AddButton({
		Title = "Delete Selected Config",
		Icon = "rbxassetid://10747362393",
		IconPosition = "Left",
		Tooltip = "Permanently remove the selected JSON profile",
		Callback = function()
			local target = nameBox:GetValue()
			local ok, err = self.ConfigManager:Delete(target)
			existingDropdown:Refresh(self.ConfigManager:List(), false)
			self:Notify({
				Title = ok and "Config Deleted" or "Delete Failed",
				Content = ok and ("Deleted '" .. target .. ".json'") or tostring(err),
				Type = ok and "Warning" or "Error",
			})
		end,
	})

	local uiSec = cfgTab:CreateSection("Interface Customization")
	uiSec:AddColorPicker({
		Title = "Global Accent Color",
		Default = THEME.Colors.Accent,
		Flag = "UI_GlobalAccent",
		Callback = function(col)
			self:SetThemeColor(col)
		end,
	})

	uiSec:AddSlider({
		Title = "Window Transparency",
		Min = 0,
		Max = 0.85,
		Default = 0,
		Decimals = 2,
		Flag = "UI_WindowTransparency",
		Callback = function(alpha)
			self:SetTransparency(alpha)
		end,
	})

	uiSec:AddSlider({
		Title = "Background Dimming",
		Min = 0,
		Max = 1,
		Default = 0.6,
		Decimals = 2,
		Flag = "UI_BackgroundDarkening",
		Callback = function(darkening)
			self:SetBackgroundImage(self.BackgroundImageLabel.Image, darkening)
		end,
	})

	return cfgTab
end

--============================================================================--
-- [Requirement 6] DEMO UI DISABLED BY DEFAULT
-- Uncomment the block below only if you want to test standalone inside Studio.
--============================================================================--
--[[
local Win = AetherUI:CreateWindow({
	Title = "AetherUI",
	Subtitle = "v1.1.0 • Custom Edition",
	ToggleKey = Enum.KeyCode.RightShift,
})
local Tab = Win:CreateTab("Visuals")
local MyToggle = Tab:AddToggle("Visuals", false)
local MySlider = Tab:AddSlider("FOV", 50, 800, 200)
Win:CreateConfigTab("Configs")
]]

return AetherUI
