local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Onboarding = {}

function Onboarding.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OnboardingUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	
	-- Background blur/dim
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 1
	background.Parent = screenGui
	
	-- Main Container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0.4, 400, 0.5, 300)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = background
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 200, 255)
	stroke.Thickness = 4
	stroke.Transparency = 0.5
	stroke.Parent = container
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 40, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 35))
	})
	gradient.Rotation = 45
	gradient.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 80)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 42
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "¡BIENVENIDO A RUFI SNOW!"
	title.Parent = container
	
	-- List Container
	local list = Instance.new("Frame")
	list.Name = "List"
	list.Size = UDim2.new(0.9, 0, 0.6, 0)
	list.Position = UDim2.new(0.5, 0, 0.15, 0)
	list.AnchorPoint = Vector2.new(0.5, 0)
	list.BackgroundTransparency = 1
	list.Parent = container
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 25)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = list

	local function createInstruction(emoji, text, color)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 0, 60)
		frame.BackgroundTransparency = 1
		
		local emojiLabel = Instance.new("TextLabel")
		emojiLabel.Size = UDim2.new(0.2, 0, 1, 0)
		emojiLabel.BackgroundTransparency = 1
		emojiLabel.Font = Enum.Font.FredokaOne
		emojiLabel.TextSize = 40
		emojiLabel.Text = emoji
		emojiLabel.Parent = frame
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(0.8, 0, 1, 0)
		textLabel.Position = UDim2.new(0.2, 0, 0, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextSize = 28
		textLabel.TextColor3 = color or Color3.new(1, 1, 1)
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Text = text
		textLabel.Parent = frame
		
		-- Add stroke for readability
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Transparency = 0.5
		s.Parent = textLabel
		
		return frame
	end

	createInstruction("❄️", "DISPARA PARA CONGELAR", Color3.fromRGB(150, 230, 255)).Parent = list
	createInstruction("👊", "EMPUJA PARA MATAR", Color3.fromRGB(255, 100, 100)).Parent = list
	createInstruction("💎", "AGARRA PODERES", ColorSequence.new(Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 150, 0)).Keypoints[1].Value).Parent = list

	-- Button
	local button = Instance.new("TextButton")
	button.Name = "ReadyButton"
	button.Size = UDim2.new(0, 200, 0, 60)
	button.Position = UDim2.new(0.5, 0, 0.9, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 32
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "LISTO"
	button.Parent = container
	
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0.5, 0)
	bCorner.Parent = button
	
	local bStroke = Instance.new("UIStroke")
	bStroke.Thickness = 3
	bStroke.Color = Color3.new(1, 1, 1)
	bStroke.Parent = button

	-- Animations
	screenGui.Parent = playerGui
	container.Size = UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	title.TextTransparency = 1
	button.BackgroundTransparency = 1
	button.TextTransparency = 1
	
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			for _, label in ipairs(child:GetChildren()) do
				if label:IsA("TextLabel") then
					label.TextTransparency = 1
				end
			end
		end
	end

	-- Intro Tween
	TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()
	TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
		Size = UDim2.new(0.4, 400, 0.5, 300),
		BackgroundTransparency = 0.2
	}):Play()
	
	task.delay(0.4, function()
		TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
		local i = 0
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then
				i += 1
				task.delay(0.2 * i, function()
					for _, label in ipairs(child:GetChildren()) do
						if label:IsA("TextLabel") then
							TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
						end
					end
				end)
			end
		end
		task.delay(1, function()
			TweenService:Create(button, TweenInfo.new(0.4), {
				BackgroundTransparency = 0,
				TextTransparency = 0
			}):Play()
		end)
	end)

	-- Button Interactivity
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 210, 255), Size = UDim2.new(0, 220, 0, 65)}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 255), Size = UDim2.new(0, 200, 0, 60)}):Play()
	end)

	local function dismiss()
		TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
		TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.delay(0.5, function()
			screenGui:Destroy()
		end)
	end

	button.MouseButton1Click:Connect(dismiss)
	
	-- Auto-dismiss after 15 seconds
	task.delay(15, function()
		if screenGui.Parent then
			dismiss()
		end
	end)
end

return Onboarding
