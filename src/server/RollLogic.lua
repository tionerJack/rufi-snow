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
	local ballVisual = Instance.new("Part")
	ballVisual.Name = "RollingEffect"
	ballVisual.Shape = Enum.PartType.Ball
	ballVisual.Size = Vector3.new(4, 4, 4)
	ballVisual.Color = Color3.fromRGB(200, 240, 255)
	ballVisual.Material = Enum.Material.Ice
	ballVisual.Transparency = 0.4
	ballVisual.CanCollide = false
	ballVisual.Parent = enemy
	
	local ballWeld = Instance.new("WeldConstraint")
	ballWeld.Part0 = root
	ballWeld.Part1 = ballVisual
	ballWeld.Parent = ballVisual
	ballVisual.Position = root.Position

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
			if humanoid.Health > 0 then
				humanoid:TakeDamage(GameConstants.BALL_DAMAGE)
				
				-- MULTI-KILL TRACKING
				if humanoid.Health <= 0 and pusher then
					local now = os.clock()
					local lastKillTime = pusher:GetAttribute("LastKillTime") or 0
					local killCount = (now - lastKillTime < 4) and (pusher:GetAttribute("KillCombo") or 0) + 1 or 1
					
					pusher:SetAttribute("LastKillTime", now)
					pusher:SetAttribute("KillCombo", killCount)
					
					if killCount >= 2 then
						print("SERVER: Multi-Kill Announcement for", pusher.Name, "x", killCount)
						local remoteFeedback = ReplicatedStorage:FindFirstChild("GameplayFeedback")
						if remoteFeedback then
							remoteFeedback:FireAllClients("MultiKill", pusher.Name, killCount)
						end
					end
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
