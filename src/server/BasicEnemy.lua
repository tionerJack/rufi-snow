local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RollLogic = require(ServerScriptService.Server:WaitForChild("RollLogic"))
local FreezeService = require(ServerScriptService.Server:WaitForChild("FreezeService"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

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
				-- PROTECTION CHECK: Shields, Giants, and THORNS
				local isProtected = character:GetAttribute("HasShield") or 
								    character:GetAttribute("IsInvincible") or 
								    character:GetAttribute("IsGiant") or 
								    character:GetAttribute("IsTitan") or
								    character:GetAttribute("HasThorns")

				if isProtected then
					-- ... (rest of protection logic)
					if character:GetAttribute("HasThorns") then
						FreezeService.ApplyHit(self.model, player)
						local dir = (self.root.Position - character.HumanoidRootPart.Position).Unit
						self.root:ApplyImpulse(dir * 5000)
					end
					return
				end
				
				-- DAMAGE PLAYER (Instead of Instakill)
				local now = os.clock()
				local lastAtk = self.model:GetAttribute("LastAttackTime") or 0
				if now - lastAtk > 1.0 then -- 1 second cooldown
					local dmg = self.model:GetAttribute("Damage") or 20
					print(string.format("IMP ATTACK: %s dealt %d damage to %s", self.model.Name, dmg, player.Name))
					humanoid:TakeDamage(dmg)
					self.model:SetAttribute("LastAttackTime", now)
					
					-- Visual Feedback: Small knockback to player
					local knockbackDir = (character.HumanoidRootPart.Position - self.root.Position).Unit
					character.HumanoidRootPart:ApplyImpulse(knockbackDir * 2000)
				end
			end
		end
	end
	
	for _, part in ipairs(self.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end
	
local PathfindingService = game:GetService("PathfindingService")

	local function getNearestTarget(range)
		local closestTarget = nil
		local shortestDistance = range or 60

		-- 1. Check Players
		for _, player in ipairs(game.Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				-- STEALTH CHECK
				if char:GetAttribute("IsInvis") or char:GetAttribute("HasPhantom") then continue end
				
				local dist = (self.root.Position - char.HumanoidRootPart.Position).Magnitude
				if dist < shortestDistance then
					shortestDistance = dist
					closestTarget = char
				end
			end
		end
		
		-- 2. Check Decoys (Distraction)
		local CollectionService = game:GetService("CollectionService")
		for _, v in ipairs(CollectionService:GetTagged("Decoy")) do
			if v:IsA("BasePart") then
				local dist = (self.root.Position - v.Position).Magnitude
				if dist < shortestDistance then
					shortestDistance = dist
					closestTarget = v
				end
			end
		end
		
		return closestTarget
	end

	-- AI Loop: Pathfinding Pursuit
	task.spawn(function()
		local level = self.model:GetAttribute("Level") or 1
		local baseSpeed = self.model:GetAttribute("BaseSpeed") or 14
		print(string.format("AI START: %s (Lvl %d) Speed: %.1f", self.model.Name, level, baseSpeed))
		
		local path = PathfindingService:CreatePath({
			AgentRadius = 2 * (self.model:GetAttribute("Scale") or 1),
			AgentHeight = 5 * (self.model:GetAttribute("Scale") or 1),
			AgentCanJump = true,
		})
		
		while self.model.Parent do
			local isFrozen = self.model:GetAttribute("IsFrozen")
			local freezeHits = self.model:GetAttribute("FreezeHits") or 0
			
			if not isFrozen then
				-- Speed Scaling: Slower as they freeze
				local speedRatio = 1 - (freezeHits / 3) 
				self.humanoid.WalkSpeed = math.max(0, baseSpeed * speedRatio)
				
				-- Aggression Scaling: Sensing range grows with level and hits
				local level = self.model:GetAttribute("Level") or 1
				local detectionRange = 30 + (level * 30) + (freezeHits * 40) -- Lvl 1 starts at 60 (before was 140)
				local targetPlayer = getNearestTarget(detectionRange)
				
				if targetPlayer then
					-- PATHFINDING CHASE
					local targetPos = targetPlayer:IsA("Model") and targetPlayer.HumanoidRootPart.Position or targetPlayer.Position
					local success, errorMessage = pcall(function()
						path:ComputeAsync(self.root.Position, targetPos)
					end)
 
					if success and path.Status == Enum.PathStatus.Success then
						local waypoints = path:GetWaypoints()
						if #waypoints >= 2 then
							self.humanoid:MoveTo(waypoints[2].Position)
							if waypoints[2].Action == Enum.PathWaypointAction.Jump then
								self.humanoid.Jump = true
							end
						end
					else
						-- Fallback
						self.humanoid:MoveTo(targetPos)
					end
				else
					-- ACTIVE WANDER
					local spawnRadius = GameConstants.ARENA_SIZE / 2.2
					local targetPos = Vector3.new(math.random(-spawnRadius, spawnRadius), self.root.Position.Y, math.random(-spawnRadius, spawnRadius))
					self.humanoid:MoveTo(targetPos)
				end
			else
				self.humanoid.WalkSpeed = 0
			end
			
			task.wait(0.2) -- Faster updates for more aggression
		end
	end)
	
	return self
end

return BasicEnemy
