local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local AdminUI = {}
AdminUI.IconMap = {}

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
	adminButton.Size = UDim2.new(0, 35, 0, 35) -- ~20% smaller than previous 40px, but square for icon
	adminButton.Position = UDim2.new(1, -10, 0, 10) 
	adminButton.AnchorPoint = Vector2.new(1, 0)
	adminButton.ZIndex = 1100
	adminButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	adminButton.TextColor3 = Color3.new(0, 0, 0)
	adminButton.Text = "👑"
	adminButton.Font = Enum.Font.FredokaOne
	adminButton.TextSize = 22
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
	mSelect.Size = UDim2.new(0, 120, 0, 30)
	mSelect.Position = UDim2.new(1, -130, 0, 5)
	mSelect.TextSize = 12
	mSelect.Text = "CAMBIAR"
	mSelect.Parent = mFrame
	
	local currentMapIdx = 1
	mSelect.MouseButton1Click:Connect(function()
		currentMapIdx = (currentMapIdx % #GameConstants.MAP_OPTIONS) + 1
		local map = GameConstants.MAP_OPTIONS[currentMapIdx]
		mSelect.Text = map.Name
		ReplicatedStorage.AdminAction:FireServer("ChangeMap", map.ID)
	end)

	-- 2b. Force Spawn Button
	local fFrame, _ = createControl("Debug Pócima:")
	local fBtn = Instance.new("TextButton")
	fBtn.Size = UDim2.new(0, 120, 0, 30)
	fBtn.Position = UDim2.new(1, -130, 0, 5)
	fBtn.Text = "FORZAR SPAWN"
	fBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	fBtn.Parent = fFrame
	
	fBtn.MouseButton1Click:Connect(function()
		ReplicatedStorage.AdminAction:FireServer("ForceSpawn")
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

	-- 4. ROTATION HUD (For all players)
	local rotationGui = Instance.new("ScreenGui")
	rotationGui.Name = "RotationHUD"
	rotationGui.ResetOnSpawn = false
	rotationGui.Parent = playerGui

	local rotFrame = Instance.new("Frame")
	rotFrame.Size = UDim2.new(0.85, -50, 0, 50) 
	rotFrame.Position = UDim2.new(0.02, 0, 0, 10)
	rotFrame.AnchorPoint = Vector2.new(0, 0)
	rotFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	rotFrame.BackgroundTransparency = 0.2
	rotFrame.Parent = rotationGui
	Instance.new("UICorner").Parent = rotFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.8
	stroke.Parent = rotFrame

	local rotLayout = Instance.new("UIListLayout")
	rotLayout.FillDirection = Enum.FillDirection.Horizontal
	rotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rotLayout.Padding = UDim.new(0.02, 0)
	rotLayout.Parent = rotFrame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(0.15, 0, 0.7, 0)
	timerLabel.Text = "00:00"
	timerLabel.Font = Enum.Font.FredokaOne
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.TextScaled = true
	timerLabel.BackgroundTransparency = 1
	timerLabel.Parent = rotFrame
	
	local tStroke = Instance.new("UIStroke")
	tStroke.Thickness = 2
	tStroke.Parent = timerLabel

	local powersList = Instance.new("Frame")
	powersList.Size = UDim2.new(0.75, 0, 1, 0)
	powersList.BackgroundTransparency = 1
	powersList.Parent = rotFrame
	
	local pLayout = Instance.new("UIListLayout")
	pLayout.FillDirection = Enum.FillDirection.Horizontal
	pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pLayout.Padding = UDim.new(0.015, 0)
	pLayout.Parent = powersList
	
	local pPadding = Instance.new("UIPadding")
	pPadding.PaddingLeft = UDim.new(0.05, 0)
	pPadding.PaddingRight = UDim.new(0.05, 0)
	pPadding.Parent = powersList


	local nextRotationTs = 0
	
	-- Update UI from Server State
	local function updateUIState(state)
		AdminUI.IconMap = {} -- Reset map on full update
		if state.KillsToWin then kInput.Text = tostring(state.KillsToWin) end
		
		if state.DisabledPowerUps then
			for key, btn in pairs(powerButtons) do
				local isDisabled = state.DisabledPowerUps[key] == true
				btn.Text = isDisabled and "OFF" or "ON"
				btn.BackgroundColor3 = isDisabled and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
			end
		end

		if state.NextRotationTime then
			nextRotationTs = state.NextRotationTime
		end

		if state.ActiveRotation then
			-- Clear existing power display
			for _, v in ipairs(powersList:GetChildren()) do
				if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
			end

			-- Show active ones
			for key, _ in pairs(state.ActiveRotation) do
				local data = GameConstants.POWERUP_TYPES[key]
				local category = nil
				for _, cat in pairs(GameConstants.POWERUP_CATEGORIES) do
					for _, ab in ipairs(cat.Abilities) do
						if ab == key then category = cat break end
					end
					if category then break end
				end

				if data and category then
					-- Main container for icon + name expansion
					local itemFrame = Instance.new("Frame")
					itemFrame.Size = UDim2.new(0, 50, 1, 0)
					itemFrame.BackgroundTransparency = 1
					itemFrame.Parent = powersList

					local lab = Instance.new("TextLabel")
					lab.Size = UDim2.new(0, 42, 0, 42)
					lab.Position = UDim2.new(0, 4, 0.5, 0)
					lab.AnchorPoint = Vector2.new(0, 0.5)
					lab.Text = data.Emoji or "❓"
					lab.Font = Enum.Font.FredokaOne
					lab.TextScaled = true
					lab.TextTransparency = 0.6
					lab.BackgroundTransparency = 1
					lab.ZIndex = 3
					lab.Parent = itemFrame
					
					local lStroke = Instance.new("UIStroke")
					lStroke.Thickness = 2.5
					lStroke.Color = Color3.new(1, 1, 1)
					lStroke.Transparency = 0.6
					lStroke.Parent = lab

					-- Selection Ring (The silhouette)
					local ring = Instance.new("Frame")
					ring.Name = "SelectionRing"
					ring.Size = UDim2.new(1.2, 0, 1.2, 0)
					ring.Position = UDim2.new(0.5, 0, 0.5, 0)
					ring.AnchorPoint = Vector2.new(0.5, 0.5)
					ring.BackgroundColor3 = Color3.new(0, 1, 1)
					ring.BackgroundTransparency = 1
					ring.Visible = false
					ring.ZIndex = 1
					ring.Parent = lab
					
					local ringCorner = Instance.new("UICorner")
					ringCorner.CornerRadius = UDim.new(1, 0)
					ringCorner.Parent = ring
					
					local ringStroke = Instance.new("UIStroke")
					ringStroke.Thickness = 3
					ringStroke.Color = Color3.fromRGB(0, 255, 255) -- Cyan glow
					ringStroke.Parent = ring

					-- Background glow/circle behind icon
					local bg = Instance.new("Frame")
					bg.Name = "IconBG"
					bg.Size = UDim2.new(1, 0, 1, 0)
					bg.Position = UDim2.new(0.5, 0, 0.5, 0)
					bg.AnchorPoint = Vector2.new(0.5, 0.5)
					bg.BackgroundColor3 = data.Color
					bg.BackgroundTransparency = 0.8
					bg.ZIndex = 2
					bg.Parent = lab
					
					local bCorner = Instance.new("UICorner")
					bCorner.CornerRadius = UDim.new(1, 0)
					bCorner.Parent = bg

					-- Countdown timer
					local countdown = Instance.new("TextLabel")
					countdown.Size = UDim2.new(1.2, 0, 0.4, 0)
					countdown.Position = UDim2.new(0.5, 0, 1, 4)
					countdown.AnchorPoint = Vector2.new(0.5, 0)
					countdown.BackgroundTransparency = 1
					countdown.Font = Enum.Font.FredokaOne
					countdown.TextColor3 = Color3.new(1, 1, 1)
					countdown.TextSize = 13
					countdown.Text = ""
					countdown.Visible = false
					countdown.Parent = lab
					
					local cStroke = Instance.new("UIStroke")
					cStroke.Thickness = 2
					cStroke.Parent = countdown

					AdminUI.IconMap[key] = {
						Container = itemFrame,
						Icon = lab,
						BG = bg,
						Stroke = lStroke,
						Timer = countdown,
						Ring = ring
					}
				end
			end
		end
	end

	-- Live Timer Loop
	task.spawn(function()
		while true do
			local remaining = math.max(0, nextRotationTs - os.time())
			local mins = math.floor(remaining / 60)
			local secs = remaining % 60
			timerLabel.Text = string.format("🕒 %02d:%02d", mins, secs)
			
			if remaining <= 10 then
				timerLabel.TextColor3 = (remaining % 2 == 0) and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
			else
				timerLabel.TextColor3 = Color3.new(1, 1, 1)
			end
			task.wait(1)
		end
	end)

	ReplicatedStorage.AdminStateUpdate.OnClientEvent:Connect(updateUIState)
	
	-- Initial State Sync
	task.spawn(function()
		local success, initialState = pcall(function()
			return ReplicatedStorage:WaitForChild("GetAdminState"):InvokeServer()
		end)
		if success and initialState then
			updateUIState(initialState)
		end
	end)
end

function AdminUI.HighlightPower(key, duration)
	local entry = AdminUI.IconMap[key]
	if not entry then return end
	
	-- Brighten icon & Show Effects
	entry.Icon.TextTransparency = 0
	entry.Stroke.Transparency = 0
	entry.BG.BackgroundTransparency = 0.2
	entry.Ring.Visible = true
	
	-- Pulse effect for ring
	local pulse = TweenService:Create(entry.Ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.new(1.4, 0, 1.4, 0)})
	pulse:Play()
	
	-- Start Timer
	entry.Timer.Visible = true
	
	task.spawn(function()
		local timeLeft = duration
		while timeLeft > 0 and AdminUI.IconMap[key] == entry do
			entry.Timer.Text = string.format("%.1fs", timeLeft)
			if timeLeft < 3 then
				entry.Timer.TextColor3 = (math.floor(timeLeft * 10) % 2 == 0) and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
			else
				entry.Timer.TextColor3 = Color3.new(1, 1, 1)
			end
			timeLeft -= task.wait(0.1)
		end
		
		-- Fade back
		if AdminUI.IconMap[key] == entry then
			pulse:Cancel()
			entry.Icon.TextTransparency = 0.6
			entry.Stroke.Transparency = 0.6
			entry.BG.BackgroundTransparency = 0.8
			entry.Ring.Visible = false
			entry.Timer.Visible = false
		end
	end)
end

return AdminUI
