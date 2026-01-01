local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local RollLogic = {}

function RollLogic.StartRolling(enemy, direction)
	if enemy:GetAttribute("IsRolling") then return end
	enemy:SetAttribute("IsRolling", true)
	
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- Physics for rolling
	local attachment = Instance.new("Attachment", root)
	local linearVelocity = Instance.new("LinearVelocity", root)
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 100000
	linearVelocity.VectorVelocity = direction.Unit * GameConstants.ROLL_SPEED
	
	-- Damage logic
	local connection = root.Touched:Connect(function(hit)
		local otherModel = hit:FindFirstAncestorOfClass("Model")
		if otherModel and otherModel ~= enemy and otherModel:FindFirstChildOfClass("Humanoid") then
			local humanoid = otherModel:FindFirstChildOfClass("Humanoid")
			humanoid:TakeDamage(GameConstants.BALL_DAMAGE)
		end
	end)
	
	task.delay(GameConstants.ROLL_DURATION, function()
		linearVelocity:Destroy()
		attachment:Destroy()
		connection:Disconnect()
		
		-- Explosion Visual
		local explosion = Instance.new("Explosion")
		explosion.Position = root.Position
		explosion.BlastRadius = 5
		explosion.Parent = workspace
		
		enemy:Destroy()
	end)
end

return RollLogic
