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
	
	-- Connection for collisions (Push AND Kill)
	local function onTouched(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and game.Players:GetPlayerFromCharacter(character)
		if not player then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		if self.model:GetAttribute("IsFrozen") then
			-- PUSH MECHANIC
			if not self.model:GetAttribute("IsRolling") and character:FindFirstChild("HumanoidRootPart") then
				print(string.format("PUSH TRIGGERED: %s by %s", self.model.Name, player.Name))
				local playerRoot = character.HumanoidRootPart
				local pushDir = (self.root.Position - playerRoot.Position) * Vector3.new(1,0,1)
				if pushDir.Magnitude < 0.1 then 
					pushDir = playerRoot.CFrame.LookVector * Vector3.new(1,0,1)
				end
				RollLogic.StartRolling(self.model, pushDir.Unit, player)
			end
		else
			-- DEADLY TOUCH (Kill player if not frozen)
			if not self.model:GetAttribute("IsRolling") then
				print(string.format("KILLING PLAYER: %s touched by %s", player.Name, self.model.Name))
				humanoid.Health = 0
			end
		end
	end
	
	for _, part in ipairs(self.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end
	
	-- Basic movement (wander) - Improved to stay in arena
	task.spawn(function()
		while self.model.Parent do
			if not self.model:GetAttribute("IsFrozen") then
				-- Random point within arena bounds (-50, 50)
				local target = Vector3.new(math.random(-50, 50), self.root.Position.Y, math.random(-50, 50))
				self.humanoid:MoveTo(target)
				
				-- Wait until reached or 5 seconds pass (stuck safety)
				local reached = false
				local conn
				conn = self.humanoid.MoveToFinished:Connect(function() reached = true end)
				
				local start = os.clock()
				while not reached and os.clock() - start < 5 and not self.model:GetAttribute("IsFrozen") do
					task.wait(0.2)
				end
				if conn then conn:Disconnect() end
			end
			task.wait(math.random(1, 3))
		end
	end)
	
	return self
end

return BasicEnemy
