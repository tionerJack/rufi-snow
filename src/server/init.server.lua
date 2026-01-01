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
	dummy.Name = "EnemyDummy"
	
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = pos
	root.Parent = dummy
	
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = pos + Vector3.new(0, 1.6, 0)
	head.Color = Color3.fromRGB(200, 50, 50)
	head.Parent = dummy
	
	local hum = Instance.new("Humanoid")
	hum.Parent = dummy
	
	dummy.Parent = workspace
	CollectionService:AddTag(dummy, "Enemy")
	print("Spawned enemy at:", pos)
end

task.delay(1, function()
	createTestEnemy(Vector3.new(15, 5, 15))
	createTestEnemy(Vector3.new(-15, 5, -15))
	createTestEnemy(Vector3.new(0, 5, 25))
end)

print("--- FROST BROS SERVER: READY ---")
