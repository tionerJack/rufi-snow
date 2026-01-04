local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local AdminUI = {}

local RunService = game:GetService("RunService")

function AdminUI.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Admin/VIP Detection
	local isVIP = false
	-- We can't easily check UserOwnsGamePassAsync from client safely without a remote, 
	-- but we'll try or just rely on the server to reject unauthorized attempts.
	-- For UI visibility, let's check a whitelist on client too.
	local isAdmin = false
	for _, id in ipairs(GameConstants.ADMIN_WHITELIST) do
		if player.UserId == id then isAdmin = true break end
	end

	-- Developer/Studio Bypass
	if RunService:IsStudio() or player.UserId <= 0 or game.CreatorId == player.UserId then
		isAdmin = true
	end

	print("ADMIN PANEL: Checking access for " .. player.Name .. " (ID: " .. player.UserId .. ") -> Admin: " .. tostring(isAdmin))

	-- Only show if Admin/VIP (Server-side check is more robust)
	-- To handle VIP, we'd normally use a RemoteFunction to check.
	-- For now, let's assume if they have the UI, they can try to use it.
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanelUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999 -- Ensure it's on top
	screenGui.Enabled = isAdmin -- Enable immediately if admin
	screenGui.Parent = playerGui

	-- Admin Button (To open panel)
	local adminButton = Instance.new("TextButton")
	adminButton.Name = "ToggleAdmin"
	adminButton.Size = UDim2.new(0, 120, 0, 45)
	adminButton.Position = UDim2.new(0, 15, 0.4, 0) -- Adjusted to be more visible
	adminButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Brighter Yellow
	adminButton.TextColor3 = Color3.new(0, 0, 0)
	adminButton.Text = "🛠 ADMIN"
	adminButton.Font = Enum.Font.FredokaOne
	adminButton.TextSize = 20
	adminButton.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = adminButton
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = adminButton

	-- Main Panel
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 400, 0, 500)
	panel.Position = UDim2.new(0.5, -200, 0.5, -250)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	panel.Visible = false
	panel.Parent = screenGui
	
	Instance.new("UICorner").Parent = panel
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Text = "PANEL DE ADMINISTRACIÓN VIP"
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.new(1, 1, 1)
	title.BackgroundTransparency = 1
	title.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(0.9, 0, 0.8, 0)
	list.Position = UDim2.new(0.05, 0, 0.15, 0)
	list.BackgroundTransparency = 1
	list.CanvasSize = UDim2.new(0, 0, 2, 0)
	list.ScrollBarThickness = 6
	list.Parent = panel
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = list

	-- Helper for controls
	local function createControl(text, callback)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.95, 0, 0, 40)
		frame.BackgroundTransparency = 0.8
		frame.Parent = list
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 1, 0)
		label.Text = text
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = frame
		
		return frame, label
	end

	-- 1. Kills to Win
	local kFrame, _ = createControl("Kills para Ganar:")
	local kInput = Instance.new("TextBox")
	kInput.Size = UDim2.new(0.3, 0, 0.8, 0)
	kInput.Position = UDim2.new(0.65, 0, 0.1, 0)
	kInput.BackgroundColor3 = Color3.new(1, 1, 1)
	kInput.TextColor3 = Color3.new(0, 0, 0)
	kInput.Text = "10"
	kInput.Parent = kFrame
	
	kInput.FocusLost:Connect(function(enter)
		if enter then
			ReplicatedStorage.AdminAction:FireServer("UpdateKills", kInput.Text)
		end
	end)

	-- 2. Map Selector
	local mFrame, _ = createControl("Cambiar Mapa:")
	local mSelect = Instance.new("TextButton")
	mSelect.Size = UDim2.new(0.3, 0, 0.8, 0)
	mSelect.Position = UDim2.new(0.65, 0, 0.1, 0)
	mSelect.Text = "CAMBIAR"
	mSelect.Parent = mFrame
	
	local currentMapIdx = 1
	mSelect.MouseButton1Click:Connect(function()
		currentMapIdx = (currentMapIdx % #GameConstants.MAP_OPTIONS) + 1
		local map = GameConstants.MAP_OPTIONS[currentMapIdx]
		mSelect.Text = map.Name
		ReplicatedStorage.AdminAction:FireServer("ChangeMap", map.ID)
	end)

	-- 3. Power-Up Toggles (Generating dynamically)
	local pLabel = Instance.new("TextLabel")
	pLabel.Size = UDim2.new(1, 0, 0, 30)
	pLabel.Text = "Habilidades (TODAS OFF POR DEFAULT):"
	pLabel.TextColor3 = Color3.new(1, 1, 0)
	pLabel.BackgroundTransparency = 1
	pLabel.Font = Enum.Font.FredokaOne
	pLabel.Parent = list
	
	local powerButtons = {}
	for key, data in pairs(GameConstants.POWERUP_TYPES) do
		local f, _ = createControl(data.Name)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.3, 0, 0.8, 0)
		btn.Position = UDim2.new(0.65, 0, 0.1, 0)
		btn.Text = "OFF"
		btn.BackgroundColor3 = Color3.new(1, 0, 0)
		btn.Parent = f
		powerButtons[key] = btn
		
		btn.MouseButton1Click:Connect(function()
			ReplicatedStorage.AdminAction:FireServer("TogglePowerUp", key)
		end)
	end

	-- Toggle Panel
	adminButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	-- Update UI from Server State
	local function updateUIState(state)
		if state.KillsToWin then kInput.Text = tostring(state.KillsToWin) end
		
		if state.DisabledPowerUps then
			for key, btn in pairs(powerButtons) do
				local isDisabled = state.DisabledPowerUps[key] == true
				btn.Text = isDisabled and "OFF" or "ON"
				btn.BackgroundColor3 = isDisabled and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
			end
		end
	end

	ReplicatedStorage.AdminStateUpdate.OnClientEvent:Connect(updateUIState)
end

return AdminUI
