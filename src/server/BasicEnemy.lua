local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local RollLogic = require(ServerScriptService.Server:WaitForChild("RollLogic"))

local BasicEnemy = {}

function BasicEnemy.new(model)
	local self = setmetatable({}, {__index = BasicEnemy})
	self.model = model
	self.root = model:WaitForChild("HumanoidRootPart")
	self.humanoid = model:WaitForChild("Humanoid")
	
	-- Detect push
	self.root.Touched:Connect(function(hit)
		if self.model:GetAttribute("IsFrozen") and not self.model:GetAttribute("IsRolling") then
			local character = hit:FindFirstAncestorOfClass("Model")
			if character and game.Players:GetPlayerFromCharacter(character) then
				local pushDir = (self.root.Position - character.HumanoidRootPart.Position).Unit
				pushDir = Vector3.new(pushDir.X, 0, pushDir.Z) -- Only horizontal push
				RollLogic.StartRolling(self.model, pushDir)
			end
		end
	end)
	
	-- Basic movement (wander)
	task.spawn(function()
		while self.model.Parent do
			if not self.model:GetAttribute("IsFrozen") then
				local target = self.root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
				self.humanoid:MoveTo(target)
				self.humanoid.MoveToFinished:Wait()
			end
			task.wait(math.random(1, 3))
		end
	end)
	
	return self
end

return BasicEnemy
