local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local FreezeService = require(script.Parent:WaitForChild("FreezeService"))

local RollLogic = {}

function RollLogic.StartRolling(enemy, direction, pusher)
	if enemy:GetAttribute("IsRolling") then return end
	enemy:SetAttribute("IsRolling", true)
	enemy:SetAttribute("PusherStartTime", os.clock())
	if pusher then
		enemy:SetAttribute("KillerName", pusher.Name)
	end
	
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- Notify pusher to play animation and camera shake
	local remoteAnim = ReplicatedStorage:FindFirstChild("PlayAnim")
	local remoteFeedback = ReplicatedStorage:FindFirstChild("GameplayFeedback")
	if pusher then
		print("SERVER: Firing CameraShake for", pusher.Name)
		if remoteAnim then remoteAnim:FireClient(pusher, "Push") end
		if remoteFeedback then remoteFeedback:FireClient(pusher, "CameraShake", 1.5) end
	end
	
	-- Physics for rolling
	local attachment = Instance.new("Attachment", root)
	local linearVelocity = Instance.new("LinearVelocity", root)
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 200000
	linearVelocity.VectorVelocity = direction.Unit * GameConstants.ROLL_SPEED
	
	-- Angular velocity for visual roll effect
	local angularVelocity = Instance.new("AngularVelocity", root)
	angularVelocity.Attachment0 = attachment
	angularVelocity.MaxTorque = 100000
	angularVelocity.AngularVelocity = Vector3.new(0, 0, 0) -- Updated in loop
	
	-- Visual Snowball Effect
	local scaleAttr = enemy:GetAttribute("Scale") or 1
	local ballVisual = Instance.new("Part")
	ballVisual.Name = "RollingEffect"
	ballVisual.Shape = Enum.PartType.Ball
	ballVisual.Size = Vector3.new(4, 4, 4) * scaleAttr
	ballVisual.Color = Color3.fromRGB(200, 240, 255)
	ballVisual.Material = Enum.Material.Ice
	ballVisual.Transparency = 0.4
	ballVisual.CanCollide = false -- Still false to avoid physics glitches with the root
	ballVisual.Parent = enemy
	
	local ballWeld = Instance.new("WeldConstraint")
	ballWeld.Part0 = root
	ballWeld.Part1 = ballVisual
	ballWeld.Parent = ballVisual
	ballVisual.Position = root.Position
	
	-- Enable collision for easier pushing, but IGNORE own root to avoid physics issues
	ballVisual.CanCollide = true
	local noCollide = Instance.new("NoCollisionConstraint")
	noCollide.Part0 = root
	noCollide.Part1 = ballVisual
	noCollide.Parent = ballVisual

	-- Update loop for angular velocity
	task.spawn(function()
		while enemy.Parent and enemy:GetAttribute("IsRolling") do
			local currentVel = linearVelocity.VectorVelocity
			-- Calculate axis of rotation (perpendicular to movement and Up)
			local axis = currentVel.Unit:Cross(Vector3.new(0, 1, 0))
			angularVelocity.AngularVelocity = axis * (GameConstants.ROLL_SPEED / 2)
			task.wait(0.1)
		end
	end)

	-- Damage logic (Hits other enemies AND other players, with pusher protection)
	local connection
	connection = root.Touched:Connect(function(hit)
		local otherModel = hit:FindFirstAncestorOfClass("Model")
		
		-- Wall Bounce Logic
		if not otherModel and hit.CanCollide then
			local ray = Ray.new(root.Position, linearVelocity.VectorVelocity.Unit * 3)
			local _, pos, normal = workspace:FindPartOnRayWithIgnoreList(ray, {enemy})
			if normal then
				local reflect = linearVelocity.VectorVelocity - 2 * linearVelocity.VectorVelocity:Dot(normal) * normal
				linearVelocity.VectorVelocity = Vector3.new(reflect.X, 0, reflect.Z).Unit * GameConstants.ROLL_SPEED
			end
			return
		end

		if otherModel and otherModel ~= enemy and otherModel:FindFirstChildOfClass("Humanoid") then
			local otherPlayer = game.Players:GetPlayerFromCharacter(otherModel)
			
			-- Pusher Immunity for 1 second
			if otherPlayer and otherPlayer == pusher then
				if os.clock() - enemy:GetAttribute("PusherStartTime") < GameConstants.PUSHER_IMMUNITY_DURATION then
					return 
				end
			end
			
			local humanoid = otherModel:FindFirstChildOfClass("Humanoid")
			local targetRoot = otherModel:FindFirstChild("HumanoidRootPart")
			
			if humanoid.Health > 0 then
				-- Apply Damage
				humanoid:TakeDamage(GameConstants.BALL_DAMAGE)
				
				-- PVP IMPACT: Send them flying if they survive or as a corpse!
				if targetRoot then
					local pushDir = (targetRoot.Position - root.Position).Unit + Vector3.new(0, 0.5, 0)
					targetRoot:ApplyImpulse(pushDir * 15000) -- Massive punch
				end

				-- Visual Impact
				local spark = Instance.new("Part")
				spark.Size = Vector3.new(4, 4, 4)
				spark.Transparency = 1 spark.Anchored = true spark.CanCollide = false
				spark.Position = targetRoot.Position spark.Parent = workspace
				local p = Instance.new("ParticleEmitter")
				p.Texture = "rbxassetid://6071575923"
				p.Size = NumberSequence.new(2, 0)
				p.Speed = NumberRange.new(20, 40)
				p.Parent = spark
				p:Emit(30)
				task.delay(1, function() spark:Destroy() end)
				
				-- Global Kill Tracking
				if humanoid.Health <= 0 and pusher then
					if _G.AddKill then _G.AddKill(pusher) end
				end
			end
		end
	end)
	
	task.delay(GameConstants.ROLL_DURATION, function()
		if linearVelocity then linearVelocity:Destroy() end
		if angularVelocity then angularVelocity:Destroy() end
		if attachment then attachment:Destroy() end
		if ballVisual then ballVisual:Destroy() end
		if connection then connection:Disconnect() end
		
		-- FATALITY: Die after roll ends
		local hum = enemy:FindFirstChildOfClass("Humanoid")
		if hum then
			print(string.format("ROLL FATALITY: %s died after rolling.", enemy.Name))
			hum.Health = 0
		end
		
		-- Cleanup visuals if still frozen
		FreezeService.UnfreezeCharacter(enemy)
	end)
end

return RollLogic
