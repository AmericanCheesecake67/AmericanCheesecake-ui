-- ui-template.lua (เวอร์ชันอัปเดต รองรับรูปภาพปุ่มกลม และรันผ่าน GitHub ได้)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UITemplate = {}
UITemplate.__index = UITemplate

-- // Theme Palette (Dark Neon Aesthetic)
local THEME = {
	Bg = Color3.fromRGB(10, 10, 12),
	Card = Color3.fromRGB(16, 16, 20),
	Border = Color3.fromRGB(30, 30, 35),
	Divider = Color3.fromRGB(24, 24, 28),
	Text = Color3.fromRGB(220, 220, 225),
	SubText = Color3.fromRGB(130, 130, 140),
	Accent = Color3.fromRGB(0, 230, 90),
	Inactive = Color3.fromRGB(40, 40, 48),
	White = Color3.fromRGB(255, 255, 255),
}

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- // Helper: Instance Creator
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

-- // Helper: Smooth Dragging (PC & Mobile with Click-vs-Drag Threshold)
local function makeDraggable(dragHandle, targetFrame, onClickCallback)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	local moved = false

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = targetFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onClickCallback then
						onClickCallback()
					end
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			if delta.Magnitude > 5 then
				moved = true
			end
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- // Main Window Constructor
function UITemplate:CreateWindow(config)
	config = config or {}
	local windowTitle = config.Title or "NEON UI"
	local toggleKey = config.ToggleKey or Enum.KeyCode.Home
	local buttonImage = config.ButtonImage -- 📌 ใส่ ID รูปภาพตรงนี้ (เช่น "rbxassetid://1234567")

	local player = Players.LocalPlayer
	local parentGui = (player and player:FindFirstChild("PlayerGui")) or game:GetService("CoreGui")

	-- Clean up old instance if re-executed
	if parentGui:FindFirstChild("DarkNeonUI") then
		parentGui.DarkNeonUI:Destroy()
	end

	local screenGui = create("ScreenGui", {
		Name = "DarkNeonUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parentGui,
	})

	local isOpen = true

	-- // Main Window Container
	local mainFrame = create("Frame", {
		Name = "MainWindow",
		Size = UDim2.fromOffset(420, 480),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIStroke", { Color = THEME.Border, Thickness = 1.5 }),
	})

	local uiScale = create("UIScale", { Scale = 1, Parent = mainFrame })

	-- // Top Header Bar
	local topBar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = THEME.Card,
		BorderSizePixel = 0,
		Parent = mainFrame,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("Frame", { -- Bottom border line
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = THEME.Border,
			BorderSizePixel = 0,
		}),
		create("TextLabel", {
			Size = UDim2.new(1, -90, 1, 0),
			Position = UDim2.fromOffset(16, 0),
			BackgroundTransparency = 1,
			Text = windowTitle,
			TextColor3 = THEME.Accent,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		create("TextLabel", {
			Size = UDim2.fromOffset(70, 20),
			Position = UDim2.new(1, -82, 0.5, -10),
			BackgroundTransparency = 1,
			Text = "[" .. toggleKey.Name .. "]",
			TextColor3 = THEME.SubText,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})

	makeDraggable(topBar, mainFrame)

	-- // Scrollable Content Container
	local scrollFrame = create("ScrollingFrame", {
		Name = "Content",
		Size = UDim2.new(1, -16, 1, -54),
		Position = UDim2.fromOffset(8, 48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.Accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = mainFrame,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 6),
		}),
	})

	-- // Floating "Messenger Chat Head" Toggle Button
	local chatHead = create("TextButton", {
		Name = "FloatingToggle",
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, 24, 0.5, -25),
		BackgroundColor3 = THEME.Bg,
		Text = buttonImage and "" or "UI", -- ถ้ามีรูป จะไม่แสดงข้อความ "UI"
		TextColor3 = THEME.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Parent = screenGui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = THEME.Accent, Thickness = 2, Name = "Stroke" }),
	})

	-- หากส่งรูปภาพมา จะแอบสร้าง ImageLabel ทับปุ่มกลมด้านในให้มนตามขอบรูปภาพ
	local btnImageLabel = nil
	if buttonImage then
		btnImageLabel = create("ImageLabel", {
			Size = UDim2.new(1, -4, 1, -4), -- ขยับหลบเส้นขอบนีออนเล็กน้อย
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = buttonImage,
			Parent = chatHead,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end

	-- // Toggle Open/Close Logic (Smooth Scale & Fade)
	local function toggleWindow()
		isOpen = not isOpen
		if isOpen then
			mainFrame.Visible = true
			TweenService:Create(uiScale, TWEEN_SMOOTH, { Scale = 1 }):Play()
			
			-- อนิเมชั่นปุ่มเปิด: คืนค่าขอบสีเขียวนีออน พื้นหลังดำ
			TweenService:Create(chatHead, TWEEN_FAST, { BackgroundColor3 = THEME.Bg }):Play()
			TweenService:Create(chatHead.Stroke, TWEEN_FAST, { Color = THEME.Accent }):Play()
			if btnImageLabel then
				TweenService:Create(btnImageLabel, TWEEN_FAST, { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
			else
				TweenService:Create(chatHead, TWEEN_FAST, { TextColor3 = THEME.Accent }):Play()
			end
		else
			local closeTween = TweenService:Create(uiScale, TWEEN_FAST, { Scale = 0 })
			closeTween:Play()
			
			-- อนิเมชั่นปุ่มปิด: เปลี่ยนทั้งปุ่มเป็นสีนีออนสว่างนำสายตา
			TweenService:Create(chatHead, TWEEN_FAST, { BackgroundColor3 = THEME.Accent }):Play()
			TweenService:Create(chatHead.Stroke, TWEEN_FAST, { Color = THEME.Accent }):Play()
			if btnImageLabel then
				-- ถ้าเป็นรูปภาพ ภาพจะย้อมเป็นสีดำกลืนกับปุ่มกลมที่กลายเป็นสีเขียวสว่าง
				TweenService:Create(btnImageLabel, TWEEN_FAST, { ImageColor3 = THEME.Bg }):Play()
			else
				TweenService:Create(chatHead, TWEEN_FAST, { TextColor3 = THEME.Bg }):Play()
			end
			
			closeTween.Completed:Once(function()
				if not isOpen then
					mainFrame.Visible = false
				end
			end)
		end
	end

	makeDraggable(chatHead, chatHead, toggleWindow)

	-- Bind Keyboard Toggle (Default: Home key, ignores typing in TextBoxes)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and UserInputService:GetFocusedTextBox() == nil then
			if input.KeyCode == toggleKey then
				toggleWindow()
			end
		end
	end)

	local WindowObj = {}

	-- // Section Constructor
	function WindowObj:CreateSection(title)
		local totalToggles = 0
		local activeToggles = 0

		local sectionCard = create("Frame", {
			Name = title .. "_Section",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = THEME.Card,
			BorderSizePixel = 0,
			Parent = scrollFrame,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}),
		})

		-- Section Header
		local header = create("Frame", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			Parent = sectionCard,
		}, {
			create("TextLabel", {
				Size = UDim2.new(0.65, 0, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				BackgroundTransparency = 1,
				Text = string.upper(title),
				TextColor3 = THEME.Text,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})

		local counterLabel = create("TextLabel", {
			Size = UDim2.new(0.35, -12, 1, 0),
			Position = UDim2.new(0.65, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = "0 / 0 on",
			TextColor3 = THEME.Accent,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = header,
		})

		local function updateCounter()
			counterLabel.Text = string.format("%d / %d on", activeToggles, totalToggles)
			counterLabel.TextColor3 = (activeToggles > 0) and THEME.Accent or THEME.SubText
		end

		local itemOrder = 1
		local function addRow(height)
			itemOrder += 1
			local row = create("Frame", {
				Size = UDim2.new(1, 0, 0, height),
				BackgroundTransparency = 1,
				LayoutOrder = itemOrder,
				Parent = sectionCard,
			}, {
				create("Frame", { -- Subtle Top Divider
					Size = UDim2.new(1, -24, 0, 1),
					Position = UDim2.fromOffset(12, 0),
					BackgroundColor3 = THEME.Divider,
					BorderSizePixel = 0,
				}),
			})
			return row
		end

		local SectionObj = {}

		-- // 1. Toggle Switch (42x22 px Pill)
		function SectionObj:AddToggle(text, default, callback)
			totalToggles += 1
			local state = (default == true)
			if state then
				activeToggles += 1
			end
			updateCounter()

			local row = addRow(38)

			create("TextLabel", {
				Size = UDim2.new(1, -70, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = THEME.Text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local pill = create("TextButton", {
				Size = UDim2.fromOffset(42, 22),
				Position = UDim2.new(1, -54, 0.5, -11),
				BackgroundColor3 = state and THEME.Accent or THEME.Inactive,
				Text = "",
				AutoButtonColor = false,
				Parent = row,
			}, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})

			local knob = create("Frame", {
				Size = UDim2.fromOffset(16, 16),
				Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
				BackgroundColor3 = THEME.White,
				BorderSizePixel = 0,
				Parent = pill,
			}, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})

			local function setState(newState)
				if state == newState then return end
				state = newState
				activeToggles += (state and 1 or -1)
				updateCounter()

				TweenService:Create(pill, TWEEN_FAST, {
					BackgroundColor3 = state and THEME.Accent or THEME.Inactive,
				}):Play()
				TweenService:Create(knob, TWEEN_FAST, {
					Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
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

			return { Set = setState, Get = function() return state end }
		end

		-- // 2. Slider (With Direct Numeric TextBox & Progress Bar)
		function SectionObj:AddSlider(text, min, max, default, callback)
			local value = math.clamp(default or min, min, max)
			local row = addRow(50)

			create("TextLabel", {
				Size = UDim2.new(1, -80, 0, 22),
				Position = UDim2.fromOffset(12, 4),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = THEME.Text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local valueBox = create("TextBox", {
				Size = UDim2.fromOffset(54, 20),
				Position = UDim2.new(1, -66, 0, 5),
				BackgroundColor3 = THEME.Bg,
				Text = tostring(value),
				TextColor3 = THEME.Accent,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				ClearTextOnFocus = false,
				Parent = row,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				create("UIStroke", { Color = THEME.Border, Thickness = 1 }),
			})

			local track = create("Frame", {
				Size = UDim2.new(1, -24, 0, 5),
				Position = UDim2.fromOffset(12, 34),
				BackgroundColor3 = THEME.Inactive,
				BorderSizePixel = 0,
				Parent = row,
			}, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})

			local initialAlpha = (value - min) / math.max(max - min, 1)
			local fill = create("Frame", {
				Size = UDim2.new(initialAlpha, 0, 1, 0),
				BackgroundColor3 = THEME.Accent,
				BorderSizePixel = 0,
				Parent = track,
			}, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})

			local thumb = create("Frame", {
				Size = UDim2.fromOffset(13, 13),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = THEME.White,
				BorderSizePixel = 0,
				Parent = fill,
			}, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})

			local function setValue(newVal)
				value = math.clamp(math.round(newVal), min, max)
				local alpha = (value - min) / math.max(max - min, 1)
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

			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			valueBox.FocusLost:Connect(function()
				local num = tonumber(valueBox.Text)
				if num then
					setValue(num)
				else
					valueBox.Text = tostring(value)
				end
			end)

			return { Set = setValue, Get = function() return value end }
		end

		-- // 3. Color Picker Box (Preset Neon Swatch Selector)
		function SectionObj:AddColorBox(text, defaultColor, callback)
			local presets = {
				defaultColor or THEME.Accent,
				Color3.fromRGB(0, 230, 90),   -- Neon Green
				Color3.fromRGB(255, 55, 95),  -- Neon Crimson
				Color3.fromRGB(0, 195, 255),  -- Cyber Cyan
				Color3.fromRGB(255, 200, 0),  -- Neon Gold
				Color3.fromRGB(185, 80, 255), -- Electric Purple
				Color3.fromRGB(255, 255, 255) -- Pure White
			}
			local index = 1
			local currentColor = presets[1]

			local row = addRow(38)

			create("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = THEME.Text,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local swatch = create("TextButton", {
				Size = UDim2.fromOffset(28, 20),
				Position = UDim2.new(1, -40, 0.5, -10),
				BackgroundColor3 = currentColor,
				Text = "",
				AutoButtonColor = false,
				Parent = row,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0, 5) }),
				create("UIStroke", { Color = THEME.Border, Thickness = 1.5 }),
			})

			swatch.MouseButton1Click:Connect(function()
				index = (index % #presets) + 1
				currentColor = presets[index]
				TweenService:Create(swatch, TWEEN_FAST, { BackgroundColor3 = currentColor }):Play()
				if callback then
					task.spawn(callback, currentColor)
				end
			end)

			return {
				Set = function(col)
					currentColor = col
					swatch.BackgroundColor3 = col
					if callback then task.spawn(callback, col) end
				end,
				Get = function() return currentColor end,
			}
		end

		return SectionObj
	end

	return WindowObj
end

return UITemplate
