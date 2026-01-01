local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local FreezeService = {}
FreezeService.FrozenEnemies = {}

function FreezeService.ApplyHit(enemy)
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
			part:SetAttribute("OriginalColor", part.Color)
			part.Color = Color3.fromRGB(150, 200, 255)
			part.Material = Enum.Material.Ice
		end
	end
	
	print(enemy.Name .. " is fully frozen!")
end

function FreezeService.UpdateVisualState(enemy, hits)
	local ratio = hits / GameConstants.FREEZE_HITS_REQUIRED
	for _, part in ipairs(enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			local original = part:GetAttribute("OriginalColor") or part.Color
			if not part:GetAttribute("OriginalColor") then
				part:SetAttribute("OriginalColor", original)
			end
			part.Color = original:Lerp(Color3.fromRGB(150, 200, 255), ratio)
		end
	end
end

return FreezeService
