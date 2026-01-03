local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

print("--- FROST BROS DEBUG: SERVER STARTING ---")

local FreezeService = require(script:WaitForChild("FreezeService"))
local BasicEnemy = require(script:WaitForChild("BasicEnemy"))
local MapService = require(script:WaitForChild("MapService"))
local PowerUpService = require(script:WaitForChild("PowerUpService"))

-- Setup Remotes (EARLY INITIALIZATION)
local function getOrCreateRemote(name, className)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className or "RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local remoteHit = getOrCreateRemote("IceHit")
local remoteAnim = getOrCreateRemote("PlayAnim")
local remoteNotice = getOrCreateRemote("PowerUpNotice")
local remoteFeedback = getOrCreateRemote("GameplayFeedback")

-- Player & Character Management
local function onCharacterAdded(character)
	-- Resetear transparencia de todas las partes de inmediato
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 0
			end
		elseif part:IsA("Decal") then
			part.Transparency = 0
		end
	end
	
	-- Limpiar cualquier atributo residual de partidas anteriores
	character:SetAttribute("IsFrozen", false)
	character:SetAttribute("FreezeHits", 0)
	character:SetAttribute("PowerUpActive", false)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Build Mario Arena
MapService.BuildArena()

-- Start Power-Up Loop
PowerUpService.StartLoop()

-- Remotes are now setup at the top

remoteHit.OnServerEvent:Connect(function(player, hitPart)
	if not hitPart then return end
	local char = player.Character
	local targetModel = hitPart:FindFirstAncestorOfClass("Model")
	if not targetModel or not targetModel:FindFirstChildOfClass("Humanoid") then return end
	if targetModel == player.Character then return end
	
	-- SHIELD / INVINCIBLE: Target is immune
	if targetModel:GetAttribute("HasShield") or targetModel:GetAttribute("IsInvincible") then 
		print("FREEZE: Hit ignored due to INVULNERABILITY on " .. targetModel.Name)
		return 
	end

	-- ABILITY: Wall Power (Spawn wall on hit/shot)
	if char and char:GetAttribute("HasWallPower") then
		local iceWall = Instance.new("Part")
		iceWall.Name = "TemporaryIceWall"
		iceWall.Size = Vector3.new(12, 10, 2)
		iceWall.Position = hitPart.Position + Vector3.new(0, 5, 0)
		iceWall.Color = Color3.fromRGB(200, 255, 255)
		iceWall.Material = Enum.Material.Ice
		iceWall.Anchored = true
		iceWall.Parent = workspace
		task.delay(5, function() if iceWall then iceWall:Destroy() end end)
	end
	
	-- NEW ABILITIES CHECK
	local isMega = char and char:GetAttribute("HasMegaBalls")
	local isExplosive = char and char:GetAttribute("HasExplosiveBalls")
	local isFire = char and char:GetAttribute("HasFirePower")
	local isStun = char and char:GetAttribute("HasStunBalls")
	local isVortex = char and char:GetAttribute("HasVortexPower")
	local isBerserk = char and char:GetAttribute("IsBerserk")
	local isSloMo = char and char:GetAttribute("HasSloMo")
	local isVenom = char and char:GetAttribute("HasVenom")
	local isShrink = char and char:GetAttribute("HasShrinkRay")
	
	-- THORN CHECK: If target has Thorns, the ATTACKER gets hit too
	if targetModel:GetAttribute("HasThorns") then
		FreezeService.ApplyHit(char, nil) -- Attacker is NPC/Environment thorns
	end

	local function applyForceHit(model, mult)
		for i = 1, mult or 1 do
			FreezeService.ApplyHit(model, player)
		end
		
		-- Special Effects
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			if isFire then
				hum:TakeDamage(5)
				local fire = Instance.new("Fire")
				fire.Size = 5 fire.Parent = model:FindFirstChild("HumanoidRootPart")
				task.delay(3, function() fire:Destroy() end)
			end
			
			if isStun then
				local oldSpeed = hum.WalkSpeed
				hum.WalkSpeed = 0
				task.delay(3, function() if hum then hum.WalkSpeed = oldSpeed end end)
			end
			
			if isSloMo then
				local oldSpeed = hum.WalkSpeed
				hum.WalkSpeed = 4
				task.delay(4, function() if hum then hum.WalkSpeed = oldSpeed end end)
			end
			
			if isVenom then
				task.spawn(function()
					for i = 1, 5 do
						if hum then hum:TakeDamage(3) end
						task.wait(1)
					end
				end)
			end
			
			if isShrink then
				print("SHRINK: Reducing " .. model.Name)
				local factor = 0.7
				
				-- 1. R15 Player Scaling
				if hum:FindFirstChild("BodyHeightScale") then
					hum.BodyHeightScale.Value *= factor
					hum.BodyWidthScale.Value *= factor
					hum.BodyDepthScale.Value *= factor
					hum.HeadScale.Value *= factor
				else
					-- 2. Custom Model Scaling (Enemies)
					for _, p in ipairs(model:GetDescendants()) do
						if p:IsA("BasePart") then
							p.Size *= factor
						elseif p:IsA("Motor6D") then
							local c0 = p.C0
							local c1 = p.C1
							p.C0 = CFrame.new(c0.Position * factor) * (c0 - c0.Position)
							p.C1 = CFrame.new(c1.Position * factor) * (c1 - c1.Position)
						end
					end
				end
				
				-- Visual: Green Flash
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(0, 255, 0)
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 1
				highlight.Parent = model
				task.delay(0.5, function() highlight:Destroy() end)
			end
			
			if isBerserk then
				local root = model:FindFirstChild("HumanoidRootPart")
				if root and char.PrimaryPart then
					local dir = (root.Position - char.PrimaryPart.Position).Unit
					root:ApplyImpulse(dir * 5000)
				end
			end
		end
	end

	if isVortex then
		local pos = hitPart.Position
		for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 25)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m and m:FindFirstChildOfClass("Humanoid") and m ~= char then
				local root = m:FindFirstChild("HumanoidRootPart")
				if root then
					local pullDir = (pos - root.Position).Unit
					root:ApplyImpulse(pullDir * 2000)
				end
			end
		end
	end

	if isExplosive then
		local pos = hitPart.Position
		print(string.format("EXPLOSION: %s triggered blast at %s", player.Name, tostring(pos)))
		
		-- Visual Explosion
		local exp = Instance.new("Explosion")
		exp.Position = pos
		exp.BlastRadius = 0 -- We handle the impact manually
		exp.DestroyJointRadiusPercent = 0
		exp.Parent = workspace
		
		for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 15)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m and m:FindFirstChildOfClass("Humanoid") and m ~= char then
				applyForceHit(m, isMega and 3 or 1)
				-- Extra Damage for enemies
				if not Players:GetPlayerFromCharacter(m) then
					m.Humanoid:TakeDamage(10)
				end
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
local function createTestEnemy(pos, level, killerName)
	enemyCounter += 1
	level = level or 1
	
	-- Level-based Progression
	local variant = math.random(1, 5)
	local baseScales = {0.35, 0.4, 0.45, 0.5, 0.55}
	-- Stats start low (tiny and slow) and grow significantly
	local scale = baseScales[variant] + (level - 1) * 0.2
	local baseSpeed = (2 + variant) + (level * 1.2) -- Lvl 1: 4.2 to 8.2 speed (Very slow)
	local maxHealth = 60 + (level * 30)
	
	local dummy = Instance.new("Model")
	-- Dynamic Naming with Levels
	if killerName then
		dummy.Name = string.format("%s Imp [Lvl %d]", killerName, level)
	else
		dummy.Name = string.format("Fire Imp [Lvl %d]", level)
	end
	
	dummy:SetAttribute("EnemyID", enemyCounter)
	dummy:SetAttribute("Level", level)
	dummy:SetAttribute("Scale", scale)
	dummy:SetAttribute("BaseSpeed", baseSpeed)
	
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
	
	body.Parent = dummy
	
	-- FIRE PARTICLES UNDERNEATH (Using Attachment for better stability)
	local fireAttach = Instance.new("Attachment")
	fireAttach.Name = "FireAttachment"
	fireAttach.Position = Vector3.new(0, -0.6, 0) -- Bottom of the body
	fireAttach.Parent = body
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://242200897"
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0))
	particles.Size = NumberSequence.new(0.6 * scale, 1.2 * scale)
	particles.Lifetime = NumberRange.new(0.3, 0.7)
	particles.Rate = 35 -- More intense
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(15, 15)
	particles.LightEmission = 0.8 -- Make it glow
	particles.LightInfluence = 0
	particles.Parent = fireAttach
	
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
	hum.MaxHealth = maxHealth
	hum.Health = maxHealth
	hum.WalkSpeed = baseSpeed
	hum.HipHeight = 1.4 * scale
	hum.Parent = dummy
	
	-- Respawn logic with increased difficulty and name inheritance
	hum.Died:Connect(function()
		local killer = dummy:GetAttribute("KillerName")
		
		-- Bonus: If no potion active, spawn one immediately!
		if not workspace:FindFirstChild("PotionCrystal") then
			print("ENEMY DIED: Spawning reward potion survivor!")
			PowerUpService.SpawnPotion(true)
		end
		
		task.wait(3)
		-- Spawn a stronger version named after the killer!
		createTestEnemy(getRandomSpawnPos(), level + 1, killer)
		dummy:Destroy()
	end)
	
	dummy.PrimaryPart = body
	dummy.Parent = workspace
	CollectionService:AddTag(dummy, "Enemy")
	print(string.format("Spawned Red Imp Variant %d (Scale %.1f) at %s", variant, scale, tostring(pos)))
end

task.delay(1, function()
	for i = 1, 10 do
		createTestEnemy(getRandomSpawnPos(), 1)
	end
end)

print("--- FROST BROS SERVER: READY ---")
