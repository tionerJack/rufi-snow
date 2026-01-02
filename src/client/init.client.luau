local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

print("--- FROST BROS DEBUG: CLIENT STARTING ---")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local lastFire = 0
local activePowerHUD = nil
local activeTweens = {}

-- HUD Death Cleanup & Scale Monitoring
local function setupCharacterListeners(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		if activePowerHUD then
			activePowerHUD:Destroy()
			activePowerHUD = nil
		end
	end)
	
	-- Monitor scale changes to prevent arm dislocation
	char.AttributeChanged:Connect(function(attr)
		if attr == "BodyHeightScale" or attr == "BodyWidthScale" then
			-- Invalidate cache
			shoulderC0Cache[char] = nil
			-- Cancel any ongoing procedural animations that might be using old scale data
			if activeTweens[char] then
				for _, t in ipairs(activeTweens[char]) do t:Cancel() end
				activeTweens[char] = nil
			end
		end
	end)
end

if player.Character then setupCharacterListeners(player.Character) end
player.CharacterAdded:Connect(setupCharacterListeners)
local function getScreenToWorld(screenPos)
	local unitRay = workspace.CurrentCamera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)
	return rayResult and rayResult.Position or (unitRay.Origin + unitRay.Direction * 1000)
end

local function getMouseWorldPos()
	local pos = mouse.Hit.Position
	return pos
end

-- UI Notification System
local function showAnnouncement(playerName, powerKey, actionType)
	local data = GameConstants.POWERUP_TYPES[powerKey]
	if not data then return end
	
	local gui = player.PlayerGui:FindFirstChild("Announcements") or Instance.new("ScreenGui")
	gui.Name = "Announcements"
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0.1, 0)
	label.Position = UDim2.new(0.2, 0, -0.2, 0) -- Start off-screen
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 30
	label.TextColor3 = data.Color
	
	if actionType == "SPAWN" then
		label.Text = string.format("¡Ha aparecido una Pócima de %s!", data.Name:upper())
	else
		label.Text = string.format("¡%s obtuvo el poder: %s!", playerName:upper(), data.Name:upper())
	end
	
	label.TextStrokeTransparency = 0.5
	label.Parent = gui
	
	-- Manage LOCAL PLAYER HUD
	if actionType == "COLLECT" and playerName == player.Name then
		if activePowerHUD then activePowerHUD:Destroy() end
		
		local hud = Instance.new("Frame")
		hud.Name = "PowerUpHUD"
		hud.Size = UDim2.new(0, 200, 0, 50)
		hud.Position = UDim2.new(1, -220, 0.05, 0) -- Top Right
		hud.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
		hud.BackgroundTransparency = 0.4
		hud.Parent = gui
		activePowerHUD = hud
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = hud
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = data.Color
		stroke.Parent = hud
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextSize = 18
		textLabel.Text = string.format("%s\n%.1fs", data.Name:upper(), GameConstants.POWERUP_DURATION)
		textLabel.Parent = hud
		
		task.spawn(function()
			local timeLeft = GameConstants.POWERUP_DURATION
			while timeLeft > 0 and hud.Parent do
				timeLeft -= task.wait(0.1)
				textLabel.Text = string.format("%s\n%.1fs", data.Name:upper(), math.max(0, timeLeft))
				if timeLeft < 3 then
					textLabel.TextColor3 = (math.floor(timeLeft * 10) % 2 == 0) and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
				end
			end
			if hud.Parent then hud:Destroy() end
		end)
	end

	-- Global Animation (Label)
	local tweenIn = TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.2, 0, 0.1, 0)})
	local tweenOut = TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.2, 0, -0.2, 0)})
	
	tweenIn:Play()
	task.delay(3, function()
		if label and label.Parent then
			tweenOut:Play()
			tweenOut.Completed:Connect(function() if label then label:Destroy() end end)
		end
	end)
end

ReplicatedStorage:WaitForChild("PowerUpNotice").OnClientEvent:Connect(showAnnouncement)

local shoulderC0Cache = {}

-- Procedural Animation Helper
local function playProceduralAnim(character, animType)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	local rightShoulder = isR15 and character:FindFirstChild("RightUpperArm", true) and character.RightUpperArm:FindFirstChild("RightShoulder") 
						or character:FindFirstChild("Right Shoulder", true)
	local leftShoulder = isR15 and character:FindFirstChild("LeftUpperArm", true) and character.LeftUpperArm:FindFirstChild("LeftShoulder")
						or character:FindFirstChild("Left Shoulder", true)
	
	if not rightShoulder or not rightShoulder:IsA("Motor6D") then return end
	
	-- SCALE-AWARE CACHING
	-- We invalidate the cache if the character's height scale has changed
	local currentScale = character:GetAttribute("BodyHeightScale") or 1
	if shoulderC0Cache[character] and shoulderC0Cache[character].scale ~= currentScale then
		-- Clear cache to re-capture correct anatomical C0 at this scale
		shoulderC0Cache[character] = nil
	end

	if not shoulderC0Cache[character] then
		shoulderC0Cache[character] = {
			right = rightShoulder.C0,
			left = leftShoulder and leftShoulder.C0,
			scale = currentScale
		}
		-- Cleanup when character leaves
		character.AncestryChanged:Connect(function(_, parent)
			if not parent then shoulderC0Cache[character] = nil end
		end)
	end
	
	local rightOrigC0 = shoulderC0Cache[character].right
	local leftOrigC0 = shoulderC0Cache[character].left
	
	if animType == "Fire" then
		activeTweens[character] = {}
		-- Snappy throw (Right arm only)
		local targetC0 = rightOrigC0 * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(90), 0, 0)
		local t1 = TweenService:Create(rightShoulder, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = targetC0})
		local t2 = TweenService:Create(rightShoulder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = rightOrigC0})
		table.insert(activeTweens[character], t1)
		table.insert(activeTweens[character], t2)
		t1:Play()
		t1.Completed:Connect(function() t2:Play() end)
		
	elseif animType == "Push" then
		activeTweens[character] = {}
		-- Both arms forward push
		local rTarget = rightOrigC0 * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(90), 0, 0)
		local lTarget = leftOrigC0 and (leftOrigC0 * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(90), 0, 0))
		
		local rt1 = TweenService:Create(rightShoulder, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {C0 = rTarget})
		local rt2 = TweenService:Create(rightShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = rightOrigC0})
		table.insert(activeTweens[character], rt1)
		table.insert(activeTweens[character], rt2)
		rt1:Play()
		rt1.Completed:Connect(function() rt2:Play() end)
		
		if leftShoulder and lTarget then
			local lt1 = TweenService:Create(leftShoulder, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {C0 = lTarget})
			local lt2 = TweenService:Create(leftShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = leftOrigC0})
			table.insert(activeTweens[character], lt1)
			table.insert(activeTweens[character], lt2)
			lt1:Play()
			lt1.Completed:Connect(function() lt2:Play() end)
		end
	end
end

-- Listen for Push Animation from Server
ReplicatedStorage:WaitForChild("PlayAnim").OnClientEvent:Connect(function(animType)
	local char = player.Character
	if char then
		playProceduralAnim(char, animType)
	end
end)

local function fire(targetOverride)
	local character = player.Character
	if not character or character:GetAttribute("IsFrozen") then return end
	
	local hasRapid = character:GetAttribute("HasRapidFire")
	local rate = hasRapid and 0.05 or GameConstants.FIRE_RATE
	
	if os.clock() - lastFire < rate then return end
	lastFire = os.clock()
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local mousePos = targetOverride or getMouseWorldPos()
	if not mousePos then return end -- Safety for touch
	local startPos = root.Position + Vector3.new(0, 1.5, 0)
	
	local hasTriple = character:GetAttribute("HasTripleShot")
	local isMega = character:GetAttribute("HasMegaBalls")
	
	local function spawnProjectile(angleOffset)
		local direction = (mousePos - startPos).Unit
		if angleOffset ~= 0 then
			direction = (CFrame.new(Vector3.zero, direction) * CFrame.Angles(0, math.rad(angleOffset), 0)).LookVector
		end
		
		-- LEASER LOGIC (Instant Hit)
		if character:GetAttribute("HasLaser") then
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local result = workspace:Raycast(startPos, direction * 500, rayParams)
			
			local hitPos = startPos + direction * 500
			if result then
				hitPos = result.Position
				local remote = ReplicatedStorage:FindFirstChild("IceHit")
				if remote then remote:FireServer(result.Instance) end
			end
			
			-- Laser Visual
			local laser = Instance.new("Part")
			laser.Anchored = true laser.CanCollide = false
			laser.Color = Color3.fromRGB(255, 20, 147) laser.Material = Enum.Material.Neon
			local dist = (hitPos - startPos).Magnitude
			laser.Size = Vector3.new(0.2, 0.2, dist)
			laser.CFrame = CFrame.lookAt(startPos, hitPos) * CFrame.new(0, 0, -dist/2)
			laser.Parent = workspace
			task.delay(0.1, function() laser:Destroy() end)
			return
		end
		
		local projectile = Instance.new("Part")
		local isBeam = character:GetAttribute("HasFreezeBeam")
		local isShrink = character:GetAttribute("HasShrinkRay")
		local isExplo = character:GetAttribute("HasExplosiveBalls")
		
		projectile.Size = isBeam and Vector3.new(1, 1, 20) 
			or (isShrink and Vector3.new(0.4, 0.4, 1.2)
			or (isMega and Vector3.new(1.8, 1.8, 4.0) 
			or Vector3.new(0.6, 0.6, 2.5)))
			
		projectile.Color = isBeam and Color3.fromRGB(0, 191, 255) 
			or (isShrink and Color3.fromRGB(0, 255, 0)
			or (isExplo and Color3.fromRGB(255, 100, 0)
			or (isMega and Color3.fromRGB(255, 0, 0) 
			or Color3.fromRGB(180, 230, 255))))
			
		projectile.Material = Enum.Material.Neon
		projectile.CanCollide = false
		projectile.Anchored = true
		projectile.CFrame = CFrame.lookAt(startPos, startPos + direction)
		projectile.Parent = workspace
		
		local isBouncing = character:GetAttribute("HasBouncingBalls")
		
		task.spawn(function()
			local distance = 0
			local speed = isMega and GameConstants.PROJECTILE_SPEED * 1.5 or GameConstants.PROJECTILE_SPEED
			local bounces = 0
			local maxBounces = isBouncing and 3 or 0
			local currentDir = direction
			
			while distance < GameConstants.PROJECTILE_RANGE * 2 do
				local step = speed * task.wait()
				distance += step
				projectile.CFrame = projectile.CFrame * CFrame.new(0, 0, -step)
				
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {character, projectile}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				
				local rayLength = isMega and 4 or 2
				local result = workspace:Raycast(projectile.Position, projectile.CFrame.LookVector * rayLength, rayParams)
				
				if result then
					local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
					local hum = hitModel and hitModel:FindFirstChildOfClass("Humanoid")
					
					if hum then
						local remote = ReplicatedStorage:FindFirstChild("IceHit")
						if remote then
							remote:FireServer(result.Instance)
						end
						projectile:Destroy()
						break
					elseif bounces < maxBounces then
						-- BOUNCE!
						bounces += 1
						local reflect = currentDir - (2 * currentDir:Dot(result.Normal) * result.Normal)
						currentDir = reflect
						projectile.CFrame = CFrame.lookAt(projectile.Position, projectile.Position + currentDir)
						-- Offset slightly to avoid immediate re-hit
						projectile.Position = result.Position + result.Normal * 0.5
					else
						projectile:Destroy()
						break
					end
				end
			end
			if projectile.Parent then projectile:Destroy() end
		end)
	end
	
	playProceduralAnim(character, "Fire")
	
	if hasTriple then
		spawnProjectile(-15)
		spawnProjectile(0)
		spawnProjectile(15)
	else
		spawnProjectile(0)
	end
end

-- ACTION BINDING WITH DELAY
task.spawn(function()
	task.wait(2) -- Wait for UI system
	print("CLIENT: Binding FireIce action...")
	
	ContextActionService:BindAction("FireIce", function(_, state)
		if state == Enum.UserInputState.Begin then
			fire()
		end
	end, true, Enum.KeyCode.F, Enum.UserInputType.MouseButton1)
	
	local button = ContextActionService:GetButton("FireIce")
	if button then
		print("CLIENT: Mobile button created! Configuring visuals...")
		ContextActionService:SetTitle("FireIce", "FIRE")
		ContextActionService:SetPosition("FireIce", UDim2.new(0.5, -150, 0.5, 0)) -- Center-Left
		button.Size = UDim2.new(0, 90, 0, 90)
		button.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
		
		-- Ensure a UICorner for aesthetic
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = button
	else
		print("CLIENT: Warning: ContextActionService failed to create a mobile button.")
	end
end)

-- Tap to fire support for mobile
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.Touch then
		local target = getScreenToWorld(input.Position)
		fire(target)
	end
end)

-- Client-Side Dash Trails (Motion Blur)
game:GetService("RunService").Heartbeat:Connect(function()
	local char = player.Character
	if char and char:GetAttribute("DASH") then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local ghost = Instance.new("Part")
			ghost.Size = Vector3.new(2, 5, 1)
			ghost.Color = Color3.fromRGB(255, 255, 0)
			ghost.Transparency = 0.7
			ghost.Material = Enum.Material.Neon
			ghost.Anchored = true 
			ghost.CanCollide = false
			ghost.CanTouch = false
			ghost.CFrame = root.CFrame
			ghost.Parent = workspace
			task.delay(0.15, function() ghost:Destroy() end)
		end
	end
end)

print("--- FROST BROS CLIENT: GUN READY ---")