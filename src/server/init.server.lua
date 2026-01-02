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
local MapService = require(script:WaitForChild("MapService"))
local PowerUpService = require(script:WaitForChild("PowerUpService"))

-- Build Mario Arena
MapService.BuildArena()

-- Start Power-Up Loop
PowerUpService.StartLoop()

-- Setup Remotes
local remoteHit = ReplicatedStorage:FindFirstChild("IceHit")
if not remoteHit then
	remoteHit = Instance.new("RemoteEvent")
	remoteHit.Name = "IceHit"
	remoteHit.Parent = ReplicatedStorage
end

local remoteAnim = ReplicatedStorage:FindFirstChild("PlayAnim")
if not remoteAnim then
	remoteAnim = Instance.new("RemoteEvent")
	remoteAnim.Name = "PlayAnim"
	remoteAnim.Parent = ReplicatedStorage
end

remoteHit.OnServerEvent:Connect(function(player, hitPart)
	if not hitPart then return end
	local targetModel = hitPart:FindFirstAncestorOfClass("Model")
	if not targetModel or not targetModel:FindFirstChildOfClass("Humanoid") then return end
	if targetModel == player.Character then return end
	
	-- SHIELD: Target is immune
	if targetModel:GetAttribute("HasShield") then 
		print("FREEZE: Hit ignored due to SHIELD on " .. targetModel.Name)
		return 
	end

	local char = player.Character
	local isMega = char and char:GetAttribute("HasMegaBalls")
	local isExplosive = char and char:GetAttribute("HasExplosiveBalls")
	
	local function applyForceHit(model, mult)
		for i = 1, mult or 1 do
			FreezeService.ApplyHit(model)
		end
	end

	if isExplosive then
		-- Area of Effect
		local pos = hitPart.Position
		print("FREEZE: Explosive hit at " .. tostring(pos))
		for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 12)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m and m:FindFirstChildOfClass("Humanoid") and m ~= char then
				applyForceHit(m, isMega and 3 or 1)
			end
		end
	else
		applyForceHit(targetModel, isMega and 3 or 1)
	end
end)

local function setupEnemy(enemy)
	if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then
		BasicEnemy.new(enemy)
	end
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(setupEnemy)

local function getRandomSpawnPos()
	-- Arena is 120x120 (-60 to 60). Spawn within safely.
	return Vector3.new(math.random(-50, 50), 20, math.random(-50, 50))
end

local enemyCounter = 0
local function createTestEnemy(pos)
	enemyCounter += 1
	
	-- Random Variation (1 to 5)
	local variant = math.random(1, 5)
	local scales = {0.6, 0.8, 1.0, 1.3, 1.6}
	local scale = scales[variant]
	
	local dummy = Instance.new("Model")
	dummy.Name = "CuteImp_" .. enemyCounter
	dummy:SetAttribute("EnemyID", enemyCounter)
	dummy:SetAttribute("Scale", scale)
	
	-- Colors (Random shades of red/crimson)
	local baseColor = Color3.fromRGB(200 + math.random(-20, 20), 40 + math.random(-20, 20), 40)
	local accentColor = Color3.fromRGB(150, 30, 30)
	
	-- BODY
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(1.2, 1.2, 0.8) * scale
	body.Position = pos + Vector3.new(0, (1.2 * scale)/2, 0)
	body.Color = baseColor
	body.Material = Enum.Material.Plastic
	body.Parent = dummy
	
	-- HEAD
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5) * scale
	head.Position = body.Position + Vector3.new(0, 1.35 * scale, 0)
	head.Color = baseColor
	head.Material = Enum.Material.Plastic
	head.Parent = dummy
	
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head
	
	-- HORNS (Devil style)
	local function createHorn(side)
		local horn = Instance.new("Part")
		horn.Name = "Horn"
		horn.Size = Vector3.new(0.4, 0.6, 0.4) * scale
		horn.Color = Color3.fromRGB(50, 20, 20)
		horn.Material = Enum.Material.Plastic
		horn.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = horn
		weld.Parent = horn
		-- Vary horn tilt based on variant
		local tilt = side * (10 + variant * 10)
		horn.CFrame = head.CFrame * CFrame.new(side * 0.5 * scale, 0.8 * scale, 0) * CFrame.Angles(math.rad(tilt), 0, 0)
	end
	createHorn(1)
	createHorn(-1)
	
	-- TAIL (Only for larger variants 4 and 5)
	if variant >= 4 then
		local tail = Instance.new("Part")
		tail.Name = "Tail"
		tail.Size = Vector3.new(0.3, 0.3, 1.2) * scale
		tail.Color = accentColor
		tail.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = tail
		weld.Parent = tail
		tail.CFrame = body.CFrame * CFrame.new(0, -0.2 * scale, 0.6 * scale) * CFrame.Angles(math.rad(-30), 0, 0)
		
		-- Tail Tip (Triangle/Spike)
		local tip = Instance.new("Part")
		tip.Size = Vector3.new(0.5, 0.5, 0.2) * scale
		tip.Color = Color3.fromRGB(30, 10, 10)
		tip.Shape = Enum.PartType.Block
		tip.Parent = dummy
		tip.CFrame = tail.CFrame * CFrame.new(0, 0, 0.7 * scale)
		
		local tipWeld = Instance.new("WeldConstraint")
		tipWeld.Part0 = tail
		tipWeld.Part1 = tip
		tipWeld.Parent = tip
	end
	
	-- EYES
	local function createEye(offset)
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(0.35, 0.35, 0.1) * scale
		eye.Color = Color3.new(0, 0, 0)
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = eye
		weld.Parent = eye
		eye.CFrame = head.CFrame * CFrame.new(offset.X * scale, 0.1 * scale, -0.76 * scale)
		
		-- Eye Reflection
		local glint = Instance.new("Part")
		glint.Size = Vector3.new(0.12, 0.12, 0.05) * scale
		glint.Color = Color3.new(1, 1, 1)
		glint.Material = Enum.Material.Neon
		glint.CanCollide = false
		glint.Parent = dummy
		
		local glintWeld = Instance.new("WeldConstraint")
		glintWeld.Part0 = eye
		glintWeld.Part1 = glint
		glintWeld.Parent = glint
		glint.CFrame = eye.CFrame * CFrame.new(0.08 * scale, 0.08 * scale, -0.06 * scale)
	end
	createEye(Vector2.new(0.3, 0))
	createEye(Vector2.new(-0.3, 0))
	
	-- LEGS
	local function createLeg(side)
		local leg = Instance.new("Part")
		leg.Size = Vector3.new(0.5, 0.8, 0.5) * scale
		leg.Position = body.Position + Vector3.new(side * 0.35 * scale, -1.0 * scale, 0)
		leg.Color = accentColor
		leg.Parent = dummy
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = leg
		weld.Parent = leg
	end
	createLeg(1)
	createLeg(-1)
	
	local hum = Instance.new("Humanoid")
	hum.WalkSpeed = 16 + (variant * 2) -- Matching player speed (16)
	hum.HipHeight = 1.4 * scale -- Adjust based on leg position/size
	hum.Parent = dummy
	
	-- Respawn logic
	hum.Died:Connect(function()
		task.wait(3)
		createTestEnemy(getRandomSpawnPos())
		dummy:Destroy()
	end)
	
	dummy.PrimaryPart = body
	dummy.Parent = workspace
	CollectionService:AddTag(dummy, "Enemy")
	print(string.format("Spawned Red Imp Variant %d (Scale %.1f) at %s", variant, scale, tostring(pos)))
end

task.delay(1, function()
	for i = 1, 10 do
		createTestEnemy(getRandomSpawnPos())
	end
end)

print("--- FROST BROS SERVER: READY ---")
