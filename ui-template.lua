-- ui-template.lua | Standalone OOP Dark-Green UI Library
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UITemplate = {}
UITemplate.__index = UITemplate

local WindowClass = {}
WindowClass.__index = WindowClass

local TabClass = {}
TabClass.__index = TabClass

local SectionClass = {}
SectionClass.__index = SectionClass

local THEME = {
	Bg = Color3.fromRGB(10, 10, 12),
	Card = Color3.fromRGB(16, 16, 20),
	Border = Color3.fromRGB(30, 30, 35),
	Divider = Color3.fromRGB(24, 24, 28),
	Accent = Color3.fromRGB(0, 230, 90),
	Text = Color3.fromRGB(220, 220, 225),
	SubText = Color3.fromRGB(130, 130, 140),
	Inactive = Color3.fromRGB(40, 40, 48),
	White = Color3.fromRGB(255, 255, 255),
}

local TWEEN_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function resolveButtonImage(img, defaultUserId)
	if not img or img == "" then
		return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", defaultUserId)
	end
	img = tostring(img)
	if string.match(img, "^%d+$") then
		return "rbxassetid://" .. img
	end
	return img
end

function UITemplate:CreateWindow(config)
	config = config or {}
	local player = Players.LocalPlayer
	local userId = (player and player.UserId) or 1

	local self = setmetatable({}, WindowClass)
	self.Title = config.Title or "COLDWAR | AmericanCheesecake67"
	self.ToggleKey = config.ToggleKey or Enum.KeyCode.Home
	self.ButtonImage = resolveButtonImage(config.ButtonImage, userId)
	self.Tabs = {}
	self.ActiveTab = nil
	self.IsOpen = true
	self._connections = {}
	self._lastDragEnd = 0

	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	local parentGui = (ok and coreGui) or (player and player:FindFirstChild("PlayerGui"))

	if parentGui:FindFirstChild("DarkNeonOOP_UI") then
		parentGui.DarkNeonOOP_UI:Destroy()
	end

	local screenGui = create("ScreenGui", {
		Name = "DarkNeonOOP_UI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parentGui,
	})
	self.ScreenGui = screenGui

	screenGui.Destroying:Connect(function()
		for _, conn in ipairs(self._connections) do
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end)

	local function makeDraggable(dragHandle, targetFrame)
		local dragging = false
		local dragStart = nil
		local startPos = nil
		local hasMoved = false

		dragHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				hasMoved = false
				dragStart = input.Position
				startPos = targetFrame.Position

				local endConn
				endConn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if hasMoved then
							self._lastDragEnd = os.clock()
						end
						if endConn then
							endConn:Disconnect()
						end
					end
				end)
			end
		end)

		local moveConn = UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				if delta.Magnitude > 6 then
					hasMoved = true
				end
				targetFrame.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
		table.insert(self._connections, moveConn)
	end

	-- Main Window (520x480)
	local mainFrame = create("Frame", {
		Name = "MainWindow",
		Size = UDim2.fromOffset(520, 480),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		Parent = screenGui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1.5 }),
	})
	self.MainFrame = mainFrame

	local uiScale = create("UIScale", { Scale = 1, Parent = mainFrame })

	-- Top Bar
	local topBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
		Parent = mainFrame,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = THEME.Border,
			BorderSizePixel = 0,
		}),
		create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(0.55, 0, 1, 0),
			Position = UDim2.fromOffset(14, 0),
			BackgroundTransparency = 1,
			Text = self.Title,
			TextColor3 = THEME.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		create("TextLabel", {
			Name = "WatermarkTop",
			Size = UDim2.new(0.42, -38, 1, 0),
			Position = UDim2.new(0.58, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "AmericanCheesecake67",
			TextColor3 = THEME.Accent,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})

	local minimizeBtn = create("TextButton", {
		Name = "MinimizeBtn",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -32, 0.5, -12),
		BackgroundColor3 = THEME.Bg,
		Text = "—",
		TextColor3 = THEME.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		Parent = topBar,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
	})

	makeDraggable(topBar, mainFrame)

	-- Bottom Footer Watermark
	create("Frame", {
		Name = "FooterBar",
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 1, -26),
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
		Parent = mainFrame,
	}, {
		create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = THEME.Border,
			BorderSizePixel = 0,
		}),
		create("TextLabel", {
			Size = UDim2.new(0.5, -14, 1, 0),
			Position = UDim2.fromOffset(14, 0),
			BackgroundTransparency = 1,
			Text = "Toggle Key: [" .. self.ToggleKey.Name .. "]",
			TextColor3 = THEME.SubText,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		create("TextLabel", {
			Name = "WatermarkBottom",
			Size = UDim2.new(0.5, -14, 1, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "AmericanCheesecake67",
			TextColor3 = THEME.Accent,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})

	-- Left Sidebar Navigation (120px wide)
	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 120, 1, -68),
		Position = UDim2.fromOffset(0, 42),
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
		Parent = mainFrame,
	}, {
		create("Frame", {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -1, 0, 0),
			BackgroundColor3 = THEME.Border,
			BorderSizePixel = 0,
		}),
	})

	self.TabList = create("ScrollingFrame", {
		Name = "TabButtons",
		Size = UDim2.new(1, -1, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = THEME.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = sidebar,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
	})

	-- Right Content Area
	self.ContentArea = create("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -120, 1, -68),
		Position = UDim2.fromOffset(120, 42),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = mainFrame,
	})

	-- Floating Circular Avatar Toggle Button (Top-Right of Screen)
	local chatHead = create("TextButton", {
		Name = "FloatingToggle",
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(1, -74, 0, 24),
		BackgroundColor3 = THEME.Card,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		Parent = screenGui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Name = "Stroke", Color = THEME.Accent, Thickness = 2 }),
		create("ImageLabel", {
			Name = "AvatarIcon",
			Size = UDim2.new(1, -4, 1, -4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = self.ButtonImage,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
	})

	local function toggleWindow()
		if os.clock() - self._lastDragEnd < 0.08 then
			return
		end
		self.IsOpen = not self.IsOpen
		if self.IsOpen then
			mainFrame.Visible = true
			TweenService:Create(uiScale, TWEEN_SMOOTH, { Scale = 1 }):Play()
			TweenService:Create(chatHead.Stroke, TWEEN_FAST, { Color = THEME.Accent }):Play()
		else
			local closeTween = TweenService:Create(uiScale, TWEEN_FAST, { Scale = 0 })
			closeTween:Play()
			TweenService:Create(chatHead.Stroke, TWEEN_FAST, { Color = THEME.Inactive }):Play()
			closeTween.Completed:Once(function()
				if not self.IsOpen then
					mainFrame.Visible = false
				end
			end)
		end
	end

	makeDraggable(chatHead, chatHead)
	chatHead.MouseButton1Click:Connect(toggleWindow)
	minimizeBtn.MouseButton1Click:Connect(toggleWindow)

	local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.ToggleKey then
			toggleWindow()
		end
	end)
	table.insert(self._connections, keyConn)

	return self
end

function WindowClass:SelectTab(targetTab)
	self.ActiveTab = targetTab
	for _, tab in ipairs(self.Tabs) do
		local isSelected = (tab == targetTab)
		tab.Page.Visible = isSelected
		TweenService:Create(tab.Button, TWEEN_FAST, {
			BackgroundColor3 = isSelected and THEME.Bg or THEME.Card,
			TextColor3 = isSelected and THEME.Accent or THEME.SubText,
		}):Play()
		TweenService:Create(tab.Indicator, TWEEN_FAST, {
			BackgroundTransparency = isSelected and 0 or 1,
		}):Play()
		TweenService:Create(tab.Stroke, TWEEN_FAST, {
			Color = isSelected and THEME.Accent or THEME.Border,
			Transparency = isSelected and 0.4 or 1,
		}):Play()
	end
end

function WindowClass:CreateTab(tabName)
	local tab = setmetatable({}, TabClass)
	tab.Window = self
	tab.Name = tabName or "Tab"

	local tabIndex = #self.Tabs + 1

	local tabBtn = create("TextButton", {
		Name = tab.Name .. "_TabBtn",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.Card,
		Text = "   " .. tab.Name,
		TextColor3 = THEME.SubText,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		LayoutOrder = tabIndex,
		Parent = self.TabList,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
	})

	local tabStroke = create("UIStroke", {
		Color = THEME.Border,
		Thickness = 1,
		Transparency = 1,
		Parent = tabBtn,
	})

	local indicator = create("Frame", {
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 0, 0.5, -9),
		BackgroundColor3 = THEME.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = tabBtn,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local page = create("ScrollingFrame", {
		Name = tab.Name .. "_Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Visible = false,
		Parent = self.ContentArea,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 12),
		}),
	})

	tab.Button = tabBtn
	tab.Indicator = indicator
	tab.Stroke = tabStroke
	tab.Page = page
	tab._sectionCount = 0

	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function TabClass:CreateSection(sectionTitle)
	local section = setmetatable({}, SectionClass)
	section.Tab = self
	section.Window = self.Window
	section._itemOrder = 1
	section._totalToggles = 0
	section._activeToggles = 0

	self._sectionCount += 1

	local card = create("Frame", {
		Name = (sectionTitle or "Section") .. "_Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
		LayoutOrder = self._sectionCount,
		Parent = self.Page,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),
	})
	section.Card = card

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = card,
	}, {
		create("TextLabel", {
			Size = UDim2.new(0.68, 0, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			BackgroundTransparency = 1,
			Text = string.upper(sectionTitle or "SECTION"),
			TextColor3 = THEME.Accent,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	section.CounterLabel = create("TextLabel", {
		Size = UDim2.new(0.32, -12, 1, 0),
		Position = UDim2.new(0.68, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = THEME.SubText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	return section
end

function SectionClass:_updateCounter()
	if self._totalToggles > 0 then
		self.CounterLabel.Text = string.format("%d / %d on", self._activeToggles, self._totalToggles)
		self.CounterLabel.TextColor3 = (self._activeToggles > 0) and THEME.Accent or THEME.SubText
	end
end

function SectionClass:_newRow(height)
	self._itemOrder += 1
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = self._itemOrder,
		Parent = self.Card,
	}, {
		create("Frame", {
			Size = UDim2.new(1, -24, 0, 1),
			Position = UDim2.fromOffset(12, 0),
			BackgroundColor3 = THEME.Divider,
			BorderSizePixel = 0,
		}),
	})
end

function SectionClass:AddToggle(text, default, callback)
	self._totalToggles += 1
	local state = (default == true)
	if state then
		self._activeToggles += 1
	end
	self:_updateCounter()

	local row = self:_newRow(36)

	create("TextLabel", {
		Size = UDim2.new(1, -68, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text or "Toggle",
		TextColor3 = THEME.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local pill = create("TextButton", {
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -52, 0.5, -10),
		BackgroundColor3 = state and THEME.Accent or THEME.Inactive,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local knob = create("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = THEME.White,
		BorderSizePixel = 0,
		Parent = pill,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local function setState(newState)
		newState = (newState == true)
		if state == newState then
			return
		end
		state = newState
		self._activeToggles += (state and 1 or -1)
		self:_updateCounter()

		TweenService:Create(pill, TWEEN_FAST, {
			BackgroundColor3 = state and THEME.Accent or THEME.Inactive,
		}):Play()
		TweenService:Create(knob, TWEEN_FAST, {
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		}):Play()

		if callback then
			task.spawn(callback, state)
		end
	end

	pill.MouseButton1Click:Connect(function()
		setState(not state)
	end)

	if callback and state then
		task.spawn(callback, state)
	end

	return setmetatable({
		Set = function(_, val) setState(val) end,
		Get = function() return state end,
	}, { __index = self })
end

function SectionClass:AddSlider(text, min, max, default, callback)
	min = min or 0
	max = max or 100
	local isFloat = (min % 1 ~= 0) or (max % 1 ~= 0) or ((default or 0) % 1 ~= 0)

	local function roundValue(v)
		v = math.clamp(v, min, max)
		if isFloat then
			return tonumber(string.format("%.2f", v))
		end
		return math.round(v)
	end

	local value = roundValue(default or min)
	local row = self:_newRow(48)

	create("TextLabel", {
		Size = UDim2.new(1, -76, 0, 20),
		Position = UDim2.fromOffset(12, 4),
		BackgroundTransparency = 1,
		Text = text or "Slider",
		TextColor3 = THEME.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local valueBox = create("TextBox", {
		Size = UDim2.fromOffset(50, 18),
		Position = UDim2.new(1, -62, 0, 5),
		BackgroundColor3 = THEME.Bg,
		Text = tostring(value),
		TextColor3 = THEME.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		ClearTextOnFocus = false,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 4) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
	})

	local track = create("TextButton", {
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.fromOffset(12, 32),
		BackgroundColor3 = THEME.Inactive,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local range = math.max(max - min, 0.0001)
	local fill = create("Frame", {
		Size = UDim2.new((value - min) / range, 0, 1, 0),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Parent = track,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("Frame", {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = THEME.White,
			BorderSizePixel = 0,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
	})

	local function setValue(newVal)
		value = roundValue(newVal)
		local alpha = (value - min) / range
		valueBox.Text = tostring(value)
		TweenService:Create(fill, TWEEN_FAST, { Size = UDim2.new(alpha, 0, 1, 0) }):Play()
		if callback then
			task.spawn(callback, value)
		end
	end

	local sliding = false
	local function updateFromInput(input)
		local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setValue(min + (max - min) * relX)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateFromInput(input)
		end
	end)

	local moveConn = UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)

	local endConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)

	table.insert(self.Window._connections, moveConn)
	table.insert(self.Window._connections, endConn)

	valueBox.FocusLost:Connect(function()
		local num = tonumber(valueBox.Text)
		if num then
			setValue(num)
		else
			valueBox.Text = tostring(value)
		end
	end)

	return setmetatable({
		Set = function(_, val) setValue(val) end,
		Get = function() return value end,
	}, { __index = self })
end

function SectionClass:AddDropdown(text, options, default, callback)
	options = options or {}
	local selected = default or options[1] or "None"
	local isExpanded = false

	local row = self:_newRow(38)

	create("TextLabel", {
		Size = UDim2.new(0.46, 0, 0, 38),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text or "Dropdown",
		TextColor3 = THEME.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local dropBtn = create("TextButton", {
		Size = UDim2.new(0.54, -20, 0, 24),
		Position = UDim2.new(0.46, 8, 0, 7),
		BackgroundColor3 = THEME.Bg,
		Text = tostring(selected) .. "  ▼",
		TextColor3 = THEME.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		AutoButtonColor = false,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 5) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
	})

	local listFrame = create("Frame", {
		Size = UDim2.new(1, -24, 0, #options * 26),
		Position = UDim2.fromOffset(12, 40),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local function selectOption(opt)
		selected = opt
		isExpanded = false
		dropBtn.Text = tostring(selected) .. "  ▼"
		TweenService:Create(row, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, 38) }):Play()
		if callback then
			task.spawn(callback, selected)
		end
	end

	local function rebuildOptions(newOptions)
		options = newOptions or {}
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		listFrame.Size = UDim2.new(1, -24, 0, #options * 26)

		for i, opt in ipairs(options) do
			local optBtn = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = THEME.Bg,
				Text = tostring(opt),
				TextColor3 = (opt == selected) and THEME.Accent or THEME.Text,
				Font = Enum.Font.GothamMedium,
				TextSize = 11,
				LayoutOrder = i,
				Parent = listFrame,
			})

			optBtn.MouseButton1Click:Connect(function()
				for _, sibling in ipairs(listFrame:GetChildren()) do
					if sibling:IsA("TextButton") then
						sibling.TextColor3 = THEME.Text
					end
				end
				optBtn.TextColor3 = THEME.Accent
				selectOption(opt)
			end)
		end
	end

	rebuildOptions(options)

	dropBtn.MouseButton1Click:Connect(function()
		isExpanded = not isExpanded
		dropBtn.Text = tostring(selected) .. (isExpanded and "  ▲" or "  ▼")
		local targetHeight = isExpanded and (46 + (#options * 26)) or 38
		TweenService:Create(row, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, targetHeight) }):Play()
	end)

	return setmetatable({
		Set = function(_, val) selectOption(val) end,
		Refresh = function(_, list) rebuildOptions(list) end,
		Get = function() return selected end,
	}, { __index = self })
end

function SectionClass:AddColorBox(text, defaultColor, callback)
	local presets = {
		defaultColor or THEME.Accent,
		Color3.fromRGB(0, 230, 90),
		Color3.fromRGB(255, 60, 90),
		Color3.fromRGB(0, 195, 255),
		Color3.fromRGB(255, 200, 0),
		Color3.fromRGB(185, 80, 255),
		Color3.fromRGB(255, 125, 40),
		Color3.fromRGB(255, 255, 255),
	}
	local currentColor = presets[1]
	local isOpenPicker = false

	local row = self:_newRow(36)

	create("TextLabel", {
		Size = UDim2.new(1, -60, 0, 36),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text = text or "Color",
		TextColor3 = THEME.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local swatchBtn = create("TextButton", {
		Size = UDim2.fromOffset(28, 18),
		Position = UDim2.new(1, -40, 0, 9),
		BackgroundColor3 = currentColor,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 5) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1.5 }),
	})

	local paletteRow = create("Frame", {
		Size = UDim2.new(1, -24, 0, 26),
		Position = UDim2.fromOffset(12, 38),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
	})

	local function applyColor(col)
		currentColor = col
		TweenService:Create(swatchBtn, TWEEN_FAST, { BackgroundColor3 = col }):Play()
		if callback then
			task.spawn(callback, col)
		end
	end

	for _, col in ipairs(presets) do
		local item = create("TextButton", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = col,
			Text = "",
			AutoButtonColor = false,
			Parent = paletteRow,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
		item.MouseButton1Click:Connect(function()
			applyColor(col)
			isOpenPicker = false
			TweenService:Create(row, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, 36) }):Play()
		end)
	end

	swatchBtn.MouseButton1Click:Connect(function()
		isOpenPicker = not isOpenPicker
		TweenService:Create(row, TWEEN_FAST, {
			Size = UDim2.new(1, 0, 0, isOpenPicker and 70 or 36),
		}):Play()
	end)

	return setmetatable({
		Set = function(_, col) applyColor(col) end,
		Get = function() return currentColor end,
	}, { __index = self })
end

return UITemplate
