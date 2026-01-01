local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

print("--- FROST BROS DEBUG: SERVER STARTING ---")

-- Visual indicator that sync works
local marker = Instance.new("Part")
marker.Name = "RojoSyncMarker"
marker.Size = Vector3.new(4, 1, 4)
marker.Color = Color3.fromRGB(0, 255, 0)
marker.Anchored = true
marker.Position = Vector3.new(0, 5, 0)
marker.Material = Enum.Material.Neon
marker.Parent = workspace

local FreezeService = require(script:WaitForChild("FreezeService"))
local BasicEnemy = require(script:WaitForChild("BasicEnemy"))

-- Setup Remotes
local remoteHit = ReplicatedStorage:FindFirstChild("IceHit")
if not remoteHit then
	remoteHit = Instance.new("RemoteEvent")
	remoteHit.Name = "IceHit"
	remoteHit.Parent = ReplicatedStorage
end

remoteHit.OnServerEvent:Connect(function(player, hitPart)
	if not hitPart then return end
	local model = hitPart:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") and model ~= player.Character then
		FreezeService.ApplyHit(model)
	end
end)

local function setupEnemy(enemy)
	if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then
		BasicEnemy.new(enemy)
	end
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(setupEnemy)

local function createTestEnemy(pos)
	local dummy = Instance.new("Model")
	dummy.Name = "CuteGoblin"
	
	-- BODY (Small and blocky)
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(1.2, 1.2, 0.8)
	body.Position = pos
	body.Color = Color3.fromRGB(100, 150, 50) -- Greenish
	body.Material = Enum.Material.Plastic
	body.Parent = dummy
	
	-- HEAD (Big and cute)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Position = pos + Vector3.new(0, 1.35, 0)
	head.Color = Color3.fromRGB(120, 180, 60)
	head.Material = Enum.Material.Plastic
	head.Parent = dummy
	
	-- EARS (Pointy and blocky)
	local function createEar(side)
		local ear = Instance.new("Part")
		ear.Name = "Ear"
		ear.Size = Vector3.new(0.8, 0.4, 0.2)
		ear.Color = head.Color
		ear.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = ear
		weld.Parent = ear
		ear.CFrame = head.CFrame * CFrame.new(side * 0.9, 0, 0) * CFrame.Angles(0, 0, side * math.rad(20))
	end
	createEar(1)
	createEar(-1)
	
	-- EYES (Cute big black eyes with reflections)
	local function createEye(offset)
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(0.35, 0.35, 0.1)
		eye.Color = Color3.new(0, 0, 0)
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = eye
		weld.Parent = eye
		eye.CFrame = head.CFrame * CFrame.new(offset.X, 0.1, -0.76)
		
		-- Eye Reflection (Glint)
		local glint = Instance.new("Part")
		glint.Size = Vector3.new(0.12, 0.12, 0.05)
		glint.Color = Color3.new(1, 1, 1)
		glint.Material = Enum.Material.Neon
		glint.CanCollide = false
		glint.Parent = dummy
		
		local glintWeld = Instance.new("WeldConstraint")
		glintWeld.Part0 = eye
		glintWeld.Part1 = glint
		glintWeld.Parent = glint
		glint.CFrame = eye.CFrame * CFrame.new(0.08, 0.08, -0.06)
	end
	createEye(Vector2.new(0.3, 0))
	createEye(Vector2.new(-0.3, 0))
	
	-- LEGS (Tiny blocky legs)
	local function createLeg(side)
		local leg = Instance.new("Part")
		leg.Size = Vector3.new(0.5, 0.8, 0.5)
		leg.Position = pos + Vector3.new(side * 0.35, -1, 0)
		leg.Color = Color3.fromRGB(80, 120, 40)
		leg.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = leg
		weld.Parent = leg
	end
	createLeg(1)
	createLeg(-1)
	
	local hum = Instance.new("Humanoid")
	hum.WalkSpeed = 14
	hum.Parent = dummy
	
	dummy.Parent = workspace
	CollectionService:AddTag(dummy, "Enemy")
	print("Spawned Cute Goblin at:", pos)
end

task.delay(1, function()
	createTestEnemy(Vector3.new(15, 4, 15))
	createTestEnemy(Vector3.new(-15, 4, -15))
	createTestEnemy(Vector3.new(0, 4, 25))
end)

print("--- FROST BROS SERVER: READY ---")
