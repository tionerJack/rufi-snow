local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local FreezeService = {}

local function createIndicator(enemy)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FreezeIndicator"
	billboard.Size = UDim2.new(0, 100, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = billboard
	
	local bar = Instance.new("Frame")
	bar.Name = "ProgressBar"
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	bar.BorderSizePixel = 0
	bar.Parent = frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame
	local corner2 = corner:Clone()
	corner2.Parent = bar
	
	billboard.Parent = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
	return billboard
end

function FreezeService.ApplyHit(enemy)
	print(string.format("FREEZE: Hit %s (ID: %s)", enemy.Name, tostring(enemy:GetAttribute("EnemyID"))))
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local currentHits = enemy:GetAttribute("FreezeHits") or 0
	currentHits = math.min(currentHits + 1, GameConstants.FREEZE_HITS_REQUIRED)
	enemy:SetAttribute("FreezeHits", currentHits)
	
	if currentHits >= GameConstants.FREEZE_HITS_REQUIRED then
		FreezeService.FreezeEnemy(enemy)
	else
		-- Visual feedback for partial freeze
		enemy:SetAttribute("LastHitTime", os.clock())
		FreezeService.UpdateVisualState(enemy, currentHits)
	end
	
	-- Update Indicator
	local head = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
	if head then
		local billboard = head:FindFirstChild("FreezeIndicator") or createIndicator(enemy)
		local bar = billboard:FindFirstChild("Frame"):FindFirstChild("ProgressBar")
		local ratio = (enemy:GetAttribute("FreezeHits") or 0) / GameConstants.FREEZE_HITS_REQUIRED
		bar:TweenSize(UDim2.new(ratio, 0, 1, 0), "Out", "Quad", 0.2, true)
		
		billboard.Enabled = (enemy:GetAttribute("FreezeHits") or 0) > 0
	end
end

function FreezeService.FreezeEnemy(enemy)
	if enemy:GetAttribute("IsFrozen") then return end
	
	enemy:SetAttribute("IsFrozen", true)
	enemy:SetAttribute("FreezeStartTime", os.clock())
	
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid.WalkSpeed = 0
	end
	
	-- Change color to ice blue
	for _, part in ipairs(enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			if not part:GetAttribute("OriginalColor") then
				part:SetAttribute("OriginalColor", part.Color)
			end
			if not part:GetAttribute("OriginalMaterial") then
				part:SetAttribute("OriginalMaterial", part.Material.Value)
			end
			part.Color = Color3.fromRGB(150, 200, 255)
			part.Material = Enum.Material.Ice
		end
	end
	
	-- Start Melting Task
	task.spawn(function()
		local duration = GameConstants.FREEZE_DURATION
		local start = os.clock()
		
		while enemy.Parent and enemy:GetAttribute("IsFrozen") and not enemy:GetAttribute("IsRolling") do
			local elapsed = os.clock() - start
			local remainingRatio = 1 - (elapsed / duration)
			
			if remainingRatio <= 0 then
				FreezeService.UnfreezeEnemy(enemy)
				break
			end
			
			-- Update Indicator during melting
			local head = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
			if head then
				local billboard = head:FindFirstChild("FreezeIndicator")
				if billboard then
					local bar = billboard:FindFirstChild("Frame"):FindFirstChild("ProgressBar")
					bar.Size = UDim2.new(remainingRatio, 0, 1, 0)
				end
			end
			
			task.wait(0.1)
		end
	end)
	
	print(enemy.Name .. " is fully frozen and melting...")
end

function FreezeService.UnfreezeEnemy(enemy)
	enemy:SetAttribute("IsFrozen", false)
	enemy:SetAttribute("FreezeHits", 0)
	enemy:SetAttribute("IsRolling", false)
	
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = 14 -- Default for goblins
	end
	
	for _, part in ipairs(enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalColor = part:GetAttribute("OriginalColor")
			if originalColor then
				part.Color = originalColor
			end
			
			local originalMaterial = part:GetAttribute("OriginalMaterial")
			if originalMaterial then
				part.Material = Enum.Material:FromValue(originalMaterial)
			else
				part.Material = Enum.Material.Plastic
			end
		end
	end
	
	-- Reset Indicator
	local head = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
	if head then
		local billboard = head:FindFirstChild("FreezeIndicator")
		if billboard then
			billboard.Enabled = false
			local bar = billboard:FindFirstChild("Frame"):FindFirstChild("ProgressBar")
			bar.Size = UDim2.new(0, 0, 1, 0)
		end
	end
end

function FreezeService.UpdateVisualState(enemy, hits)
	local ratio = hits / GameConstants.FREEZE_HITS_REQUIRED
	for _, part in ipairs(enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			if not part:GetAttribute("OriginalColor") then
				part:SetAttribute("OriginalColor", part.Color)
			end
			if not part:GetAttribute("OriginalMaterial") then
				part:SetAttribute("OriginalMaterial", part.Material.Value)
			end
			
			local originalColor = part:GetAttribute("OriginalColor")
			part.Color = originalColor:Lerp(Color3.fromRGB(150, 200, 255), ratio)
		end
	end
end

return FreezeService
