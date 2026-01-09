local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

print("--- FROST BROS DEBUG: SERVER STARTING ---")

local FreezeService = require(script:WaitForChild("FreezeService"))
local BasicEnemy = nil -- Removed monster logic
local MapService = require(script:WaitForChild("MapService"))
local PowerUpService = require(script:WaitForChild("PowerUpService"))
local AdminService = require(script:WaitForChild("AdminService"))

task.spawn(function()
	AdminService.Init()
	print("SERVER: AdminService Initialized ✅")
end)

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
	
	-- Limpiar cualquier atributo residual de partidas anteriores (Total 39 tipos)
	local powerUps = {
		"IsFrozen", "FreezeHits", "PowerUpActive", "IsGiant", "IsTitan", "IsInvincible",
		"HasTripleShot", "HasMegaBalls", "HasRapidFire", "HasExplosiveBalls", "HasShield",
		"HasFirePower", "HasBouncingBalls", "HasAntiGravity", "HasLowGravity", "HasFrostTrail",
		"HasVortexPower", "HasMirage", "IsBerserk", "HasStunBalls", "HasTeleport", "HasIceAura",
		"HasSloMo", "HasRegen", "HasMeteorRain", "HasWallPower", "IsInvis", "HasShockwave",
		"HasFreezeBeam", "HasMasterClones", "HasVenom", "HasThorns", "HasMagneticPull",
		"HasBlizzard", "HasLaser", "HasShrinkRay", "HasFlight", "HasSniper", "HasTimeRecall"
	}
	for _, attr in ipairs(powerUps) do
		character:SetAttribute(attr, nil)
	end
	
	-- Reset defaults
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

task.spawn(function()
	MapService.BuildArena("DEFAULT")
	print("SERVER: Map Built ✅")
end)

-- Maintain Center Diablito
task.spawn(function()
	local BasicEnemy = require(script:WaitForChild("BasicEnemy"))
	while true do
		local existing = workspace:FindFirstChild("Diablito_Lvl1")
		if not existing then
			print("SERVER: Spawning Central Diablito...")
			BasicEnemy.Spawn(Vector3.new(0, 5, 80), 1)
		end
		task.wait(5)
	end
end)

-- Start Power-Up Loop
PowerUpService.StartLoop()

-- KILL SYSTEM & SCOREBOARD
local playerKills = {}
local remoteLeaderboard = getOrCreateRemote("LeaderboardUpdate")

local function updateLeaderboard()
	local scores = {}
	for _, p in ipairs(Players:GetPlayers()) do
		scores[p.Name] = playerKills[p] or 0
	end
	remoteLeaderboard:FireAllClients(scores)
end

local function checkWin(player)
	local kills = playerKills[player] or 0
	if kills >= AdminService.GetKillsToWin() then
		print(string.format("GAME WINNER: %s with %d kills!", player.Name, kills))
		local remoteFeedback = ReplicatedStorage:FindFirstChild("GameplayFeedback")
		if remoteFeedback then
			remoteFeedback:FireAllClients("MultiKill", player.Name, kills)
		end
		-- Reset Scores after win
		playerKills = {}
		updateLeaderboard()
	end
end

-- Export for other modules
_G.AddKill = function(attacker)
	if not attacker or not attacker:IsA("Player") then return end
	playerKills[attacker] = (playerKills[attacker] or 0) + 1
	updateLeaderboard()
	checkWin(attacker)
end

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

	-- NEW ABILITIES CHECK (Strictly scoped to current attacker)
	if not char then return end
	
	local attackerStats = {
		isMega = char:GetAttribute("HasMegaBalls"),
		isExplosive = char:GetAttribute("HasExplosiveBalls"),
		isFire = char:GetAttribute("HasFirePower"),
		isStun = char:GetAttribute("HasStunBalls"),
		isVortex = char:GetAttribute("HasVortexPower"),
		isBerserk = char:GetAttribute("IsBerserk"),
		isSloMo = char:GetAttribute("HasSloMo"),
		isVenom = char:GetAttribute("HasVenom"),
		isShrink = char:GetAttribute("HasShrinkRay"),
		hasWall = char:GetAttribute("HasWallPower")
	}
	
	-- ABILITY: Wall Power (Spawn wall on hit/shot)
	if attackerStats.hasWall then
		local lastWall = char:GetAttribute("LastWallTime") or 0
		if os.clock() - lastWall > 2.0 then
			char:SetAttribute("LastWallTime", os.clock())
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
	end
	
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
				if attackerStats.isFire then
					hum:TakeDamage(10) -- Increased damage
					local fire = Instance.new("Fire")
					fire.Size = 8 fire.Parent = model:FindFirstChild("HumanoidRootPart")
					task.delay(4, function() fire:Destroy() end)
					-- Special PVP: If they are near frozen, fire makes it harder to thaw? Or just more damage.
				end
			
			if attackerStats.isSloMo then
				local freezeHits = model:GetAttribute("FreezeHits") or 0
				local isFrozen = model:GetAttribute("IsFrozen")
				if freezeHits > 0 or isFrozen then
					local oldSpeed = hum.WalkSpeed
					hum.WalkSpeed = 4
					task.delay(4, function() if hum then hum.WalkSpeed = oldSpeed end end)
				end
			end
			
			if attackerStats.isVenom then
				-- Apply Venom Effect (10 seconds)
				local targetRoot = model:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					local venomSmoke = targetRoot:FindFirstChild("VenomSmoke")
					if not venomSmoke then
						venomSmoke = Instance.new("ParticleEmitter")
						venomSmoke.Name = "VenomSmoke"
						venomSmoke.Texture = "rbxassetid://1084969810" -- Toxic smoke texture
						venomSmoke.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
						venomSmoke.Size = NumberSequence.new(2, 4)
						venomSmoke.Transparency = NumberSequence.new(0.5, 1)
						venomSmoke.Lifetime = NumberRange.new(0.5, 1)
						venomSmoke.Rate = 20
						venomSmoke.Parent = targetRoot
					end
					
					task.spawn(function()
						local duration = 10
						local start = os.clock()
						while os.clock() - start < duration and model.Parent do
							local freezeHits = model:GetAttribute("FreezeHits") or 0
							local isFrozen = model:GetAttribute("IsFrozen")
							
							-- Only damage if partially or fully frozen
							if (freezeHits > 0 or isFrozen) and hum.Health > 0 then
								hum:TakeDamage(4)
								-- Green flash effect
								local h = model:FindFirstChild("VenomHighlight") or Instance.new("Highlight")
								h.Name = "VenomHighlight"
								h.FillColor = Color3.fromRGB(0, 200, 0)
								h.FillTransparency = 0.6
								h.Parent = model
								task.delay(0.2, function() if h then h:Destroy() end end)
							end
							task.wait(1)
						end
						if venomSmoke then venomSmoke:Destroy() end
					end)
				end
			end
			
			if attackerStats.isShrink then
				if not model:GetAttribute("WasShrunk") then
					model:SetAttribute("WasShrunk", true)
					print("SHRINK: Reducing " .. model.Name)
					local factor = 0.5
					hum.WalkSpeed *= 0.7
				
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
			end
			
			if attackerStats.isBerserk then
				local root = model:FindFirstChild("HumanoidRootPart")
				if root and char.PrimaryPart then
					local dir = (root.Position - char.PrimaryPart.Position).Unit + Vector3.new(0, 0.4, 0)
					root:ApplyImpulse(dir * 18000) -- Massive Berserk shove
					
					-- Visual Flash
					local remoteFeedback = ReplicatedStorage:FindFirstChild("GameplayFeedback")
					if remoteFeedback then remoteFeedback:FireClient(player, "CameraShake", 3) end
				end
			end
		end
	end

	if attackerStats.isVortex then
		local pos = hitPart.Position
		for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 25)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m and m:FindFirstChildOfClass("Humanoid") and m ~= char then
				local root = m:FindFirstChild("HumanoidRootPart")
				if root then
					local pullDir = (pos - root.Position).Unit
					root:ApplyImpulse(pullDir * 3000)
					-- VORTEX EFFECT: Freeze!
					FreezeService.ApplyHit(m, player)
					FreezeService.ApplyHit(m, player)
				end
			end
		end
	end
	
	if attackerStats.hasWall then
		local iceWall = Instance.new("Part")
		iceWall.Name = "TemporaryIceWall"
		iceWall.Size = Vector3.new(12, 10, 2)
		iceWall.Position = hitPart.Position + Vector3.new(0, 5, 0)
		iceWall.Color = Color3.fromRGB(200, 255, 255)
		iceWall.Material = Enum.Material.Ice
		iceWall.Anchored = true
		iceWall.Parent = workspace
		task.delay(10, function() if iceWall then iceWall:Destroy() end end)
	end

	if attackerStats.isExplosive then
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
				applyForceHit(m, attackerStats.isMega and 3 or 1)
			end
		end
	else
		applyForceHit(targetModel, attackerStats.isMega and 3 or 1)
	end
	
	-- GIANT IMPACT: AOE Shockwave if the attacker is big
	if char:GetAttribute("IsGiant") or char:GetAttribute("IsTitan") then
		local impactPos = hitPart.Position
		local power = char:GetAttribute("IsTitan") and 12000 or 6000
		
		for _, part in ipairs(workspace:GetPartBoundsInRadius(impactPos, 15)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m and m ~= char and m:FindFirstChild("Humanoid") then
				local tr = m:FindFirstChild("HumanoidRootPart")
				if tr then
					local dir = (tr.Position - impactPos).Unit + Vector3.new(0, 0.5, 0)
					tr:ApplyImpulse(dir * power)
				end
			end
		end
		-- Visual Feedback
		local remoteFeedback = ReplicatedStorage:FindFirstChild("GameplayFeedback")
		if remoteFeedback then remoteFeedback:FireAllClients("CameraShake", 2, impactPos) end
	end
end)

-- CollectionService Enemy setup removed

-- Initial enemy spawning removed

print("--- FROST BROS SERVER: READY ---")
