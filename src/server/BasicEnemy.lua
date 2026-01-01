local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local RollLogic = require(ServerScriptService.Server:WaitForChild("RollLogic"))

local BasicEnemy = {}

function BasicEnemy.new(model)
	if model:GetAttribute("ControllerInitialized") then return end
	model:SetAttribute("ControllerInitialized", true)
	
	local self = setmetatable({}, {__index = BasicEnemy})
	self.model = model
	self.root = model:WaitForChild("HumanoidRootPart")
	self.humanoid = model:WaitForChild("Humanoid")
	
	-- Detect push (Any collision with player while frozen)
	local isPushing = false
	local function onTouched(hit)
		if self.model:GetAttribute("IsFrozen") and not self.model:GetAttribute("IsRolling") then
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and game.Players:GetPlayerFromCharacter(character)
			if player and character:FindFirstChild("HumanoidRootPart") then
				print(string.format("PUSH TRIGGERED: %s (ID: %s) by %s", self.model.Name, tostring(self.model:GetAttribute("EnemyID")), player.Name))
				isPushing = true
				local playerRoot = character.HumanoidRootPart
				
				-- Push direction is from player towards the enemy
				local pushDir = (self.root.Position - playerRoot.Position) * Vector3.new(1,0,1)
				if pushDir.Magnitude < 0.1 then 
					pushDir = playerRoot.CFrame.LookVector * Vector3.new(1,0,1)
				end
				
				RollLogic.StartRolling(self.model, pushDir.Unit, player)
				task.wait(0.5)
				isPushing = false
			end
		end
	end
	
	for _, part in ipairs(self.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end
	
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
