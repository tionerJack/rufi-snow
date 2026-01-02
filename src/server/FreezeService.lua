local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

-- Lazy load RollLogic to avoid circular dependency
local RollLogic

local FreezeService = {}

local function createIndicator(char)
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
	
	billboard.Parent = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	return billboard
end

function FreezeService.ApplyHit(char)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local isPlayer = Players:GetPlayerFromCharacter(char)
	print(string.format("FREEZE: Hit %s (%s)", char.Name, isPlayer and "Player" or "Enemy"))
	
	local currentHits = char:GetAttribute("FreezeHits") or 0
	currentHits = math.min(currentHits + 1, GameConstants.FREEZE_HITS_REQUIRED)
	char:SetAttribute("FreezeHits", currentHits)
	
	if currentHits >= GameConstants.FREEZE_HITS_REQUIRED then
		FreezeService.FreezeCharacter(char)
	else
		char:SetAttribute("LastHitTime", os.clock())
		FreezeService.UpdateVisualState(char, currentHits)
	end
	
	-- Update Indicator
	local root = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if root then
		local billboard = root:FindFirstChild("FreezeIndicator") or createIndicator(char)
		local bar = billboard:FindFirstChild("Frame"):FindFirstChild("ProgressBar")
		local ratio = (char:GetAttribute("FreezeHits") or 0) / GameConstants.FREEZE_HITS_REQUIRED
		bar:TweenSize(UDim2.new(ratio, 0, 1, 0), "Out", "Quad", 0.2, true)
		billboard.Enabled = (char:GetAttribute("FreezeHits") or 0) > 0
	end
end

function FreezeService.FreezeCharacter(char)
	if char:GetAttribute("IsFrozen") then return end
	if not RollLogic then RollLogic = require(game.ServerScriptService.Server.RollLogic) end
	
	char:SetAttribute("IsFrozen", true)
	char:SetAttribute("FreezeStartTime", os.clock())
	
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0 -- PvP restriction
	end
	
	-- Visual Ice
	for _, part in ipairs(char:GetDescendants()) do
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
	
	-- Push Detection for Players (Enemies handle this in BasicEnemy.lua)
	local isPlayer = Players:GetPlayerFromCharacter(char)
	local pushConn
	if isPlayer then
		pushConn = char.HumanoidRootPart.Touched:Connect(function(hit)
			if not char:GetAttribute("IsFrozen") or char:GetAttribute("IsRolling") then return end
			local pusherModel = hit:FindFirstAncestorOfClass("Model")
			local pusher = pusherModel and Players:GetPlayerFromCharacter(pusherModel)
			if pusher and pusher.Character and pusher.Character ~= char then
				print(string.format("PLAYER PUSHED: %s by %s", char.Name, pusher.Name))
				local pushDir = (char.HumanoidRootPart.Position - pusher.Character.HumanoidRootPart.Position) * Vector3.new(1,0,1)
				RollLogic.StartRolling(char, pushDir.Unit, pusher)
			end
		end)
	end

	-- Melting Task
	task.spawn(function()
		local duration = GameConstants.FREEZE_DURATION
		local start = os.clock()
		
		while char.Parent and char:GetAttribute("IsFrozen") and not char:GetAttribute("IsRolling") do
			local elapsed = os.clock() - start
			local remainingRatio = 1 - (elapsed / duration)
			
			if remainingRatio <= 0 then
				FreezeService.UnfreezeCharacter(char)
				break
			end
			
			local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			if head then
				local billboard = head:FindFirstChild("FreezeIndicator")
				if billboard then
					local bar = billboard:FindFirstChild("Frame"):FindFirstChild("ProgressBar")
					bar.Size = UDim2.new(remainingRatio, 0, 1, 0)
				end
			end
			task.wait(0.1)
		end
		if pushConn then pushConn:Disconnect() end
	end)
end

function FreezeService.UnfreezeCharacter(char)
	char:SetAttribute("IsFrozen", false)
	char:SetAttribute("FreezeHits", 0)
	char:SetAttribute("IsRolling", false)
	
	local isPlayer = Players:GetPlayerFromCharacter(char)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = isPlayer and 16 or 14 -- Restored speeds
		humanoid.JumpPower = 50 -- Standard
	end
	
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalColor = part:GetAttribute("OriginalColor")
			if originalColor then part.Color = originalColor end
			local originalMat = part:GetAttribute("OriginalMaterial")
			if originalMat then part.Material = Enum.Material:FromValue(originalMat) end
		end
	end
	
	local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if head then
		local billboard = head:FindFirstChild("FreezeIndicator")
		if billboard then
			billboard.Enabled = false
			local bar = billboard:FindFirstChild("Frame"):FindFirstChild("ProgressBar")
			bar.Size = UDim2.new(0, 0, 1, 0)
		end
	end
end

function FreezeService.UpdateVisualState(char, hits)
	local ratio = hits / GameConstants.FREEZE_HITS_REQUIRED
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if not part:GetAttribute("OriginalColor") then
				part:SetAttribute("OriginalColor", part.Color)
			end
			local originalColor = part:GetAttribute("OriginalColor")
			part.Color = originalColor:Lerp(Color3.fromRGB(150, 200, 255), ratio)
		end
	end
end

return FreezeService
