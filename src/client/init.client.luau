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

-- Helper to get world position from screen point (for touch)
local function getScreenToWorld(screenPos)
	local unitRay = workspace.CurrentCamera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)
	return rayResult and rayResult.Position or (unitRay.Origin + unitRay.Direction * 1000)
end

-- Procedural Animation Helper
local function playProceduralAnim(character, animType)
	local isR15 = character.Humanoid.RigType == Enum.HumanoidRigType.R15
	local rightShoulder = isR15 and character:FindFirstChild("RightUpperArm", true) and character.RightUpperArm:FindFirstChild("RightShoulder") 
						or character:FindFirstChild("Right Shoulder", true)
	local leftShoulder = isR15 and character:FindFirstChild("LeftUpperArm", true) and character.LeftUpperArm:FindFirstChild("LeftShoulder")
						or character:FindFirstChild("Left Shoulder", true)
	
	if not rightShoulder or not rightShoulder:IsA("Motor6D") then return end
	
	local rightOrigC0 = rightShoulder.C0
	local leftOrigC0 = leftShoulder and leftShoulder.C0
	
	if animType == "Fire" then
		-- Snappy throw (Right arm only)
		local targetC0 = rightOrigC0 * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(90), 0, 0)
		local t1 = TweenService:Create(rightShoulder, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = targetC0})
		local t2 = TweenService:Create(rightShoulder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = rightOrigC0})
		t1:Play()
		t1.Completed:Connect(function() t2:Play() end)
		
	elseif animType == "Push" then
		-- Both arms forward push
		local rTarget = rightOrigC0 * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(90), 0, 0)
		local lTarget = leftOrigC0 and (leftOrigC0 * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(90), 0, 0))
		
		local rt1 = TweenService:Create(rightShoulder, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {C0 = rTarget})
		local rt2 = TweenService:Create(rightShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = rightOrigC0})
		rt1:Play()
		rt1.Completed:Connect(function() rt2:Play() end)
		
		if leftShoulder and lTarget then
			local lt1 = TweenService:Create(leftShoulder, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {C0 = lTarget})
			local lt2 = TweenService:Create(leftShoulder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = leftOrigC0})
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
	if os.clock() - lastFire < GameConstants.FIRE_RATE then return end
	
	local character = player.Character
	if not character or character:GetAttribute("IsFrozen") then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	lastFire = os.clock()
	
	local startPos = root.Position + root.CFrame.LookVector * 2
	local targetPos = targetOverride or mouse.Hit.Position
	if not targetPos then return end -- Safety for touch
	
	local direction = (targetPos - startPos).Unit
	
	local projectile = Instance.new("Part")
	projectile.Size = Vector3.new(0.6, 0.6, 2.5)
	projectile.Color = Color3.fromRGB(180, 230, 255)
	projectile.Material = Enum.Material.Neon
	projectile.CanCollide = false
	projectile.Anchored = true
	projectile.CFrame = CFrame.lookAt(startPos, targetPos)
	projectile.Parent = workspace
	
	playProceduralAnim(character, "Fire")
	
	task.spawn(function()
		local distance = 0
		while distance < GameConstants.PROJECTILE_RANGE do
			local step = GameConstants.PROJECTILE_SPEED * task.wait()
			distance += step
			projectile.CFrame = projectile.CFrame * CFrame.new(0, 0, -step)
			
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character, projectile}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local result = workspace:Raycast(projectile.Position, projectile.CFrame.LookVector * 2, rayParams)
			if result then
				local remote = ReplicatedStorage:FindFirstChild("IceHit")
				if remote then
					remote:FireServer(result.Instance)
				end
				break
			end
		end
		projectile:Destroy()
	end)
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

print("--- FROST BROS CLIENT: GUN READY ---")