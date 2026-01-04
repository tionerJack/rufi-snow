local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))
local FreezeService = require(script.Parent.FreezeService)

local PowerUpService = {}
local nextSpawnTime = 0

function PowerUpService.SpawnPotion(bypassTimer)
	-- Ensure only one exists unless bypassed
	if not bypassTimer and workspace:FindFirstChild("PotionCrystal") then return end
	
	local categoryKeys = {}
	for k, _ in pairs(GameConstants.POWERUP_CATEGORIES) do table.insert(categoryKeys, k) end
	local chosenCategoryKey = categoryKeys[math.random(1, #categoryKeys)]
	local chosenCategory = GameConstants.POWERUP_CATEGORIES[chosenCategoryKey]
	
	print("POWERUP: Spawning Category Crystal: " .. chosenCategory.Name)
	
	-- 1. Outer Crystal Container
	local container = Instance.new("Part")
	container.Name = "PotionCrystal"
	container.Size = Vector3.new(2.4, 3.8, 2.4)
	container.Color = Color3.fromRGB(200, 240, 255)
	container.Material = Enum.Material.Glass
	container.Transparency = 0.7
	container.Reflectance = 0.2
	container.Anchored = true
	container.CanCollide = false
	container:SetAttribute("CategoryType", chosenCategoryKey)
	
	-- 2. Internal Magic Core
	local core = Instance.new("Part")
	core.Name = "LiquidCore"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(1.4, 1.8, 1.4)
	core.Color = chosenCategory.Color
	core.Material = Enum.Material.Neon
	core.Anchored = true
	core.CanCollide = false
	core.Parent = container
	
	-- 3. Point Light for Glow
	local light = Instance.new("PointLight")
	light.Color = chosenCategory.Color
	light.Range = 10
	light.Brightness = 3
	light.Parent = core
	
	-- 4. Internal Magical Bubbles
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(chosenCategory.Color)
	p.Size = NumberSequence.new(0.3, 0)
	p.Transparency = NumberSequence.new(0.5, 1)
	p.Lifetime = NumberRange.new(1, 2)
	p.Rate = 6
	p.Speed = NumberRange.new(1, 4)
	p.VelocitySpread = 360
	p.Texture = "rbxassetid://6071575923"
	p.Parent = core

	local CollectionService = game:GetService("CollectionService")
	local peaks = CollectionService:GetTagged("PyramidPeak")
	
	if #peaks == 0 then
		print("POWERUP: Error - No PyramidPeaks found in workspace!")
		container:Destroy()
		return
	end
	
	local targetPeak = peaks[math.random(1, #peaks)]
	container.Position = targetPeak.Position + Vector3.new(0, 8, 0)
	core.Position = container.Position
	container.Parent = workspace
	
	-- (Spawn notification disabled to reduce spam)
	
	-- Pulsing Core Animation
	task.spawn(function()
		while container.Parent do
			local t = os.clock()
			local pulse = 1.2 + math.sin(t * 3) * 0.4
			core.Size = Vector3.new(1.4, 1.8, 1.4) * pulse
			light.Brightness = 2 + math.sin(t * 5) * 1.5
			task.wait(0.05)
		end
	end)
	
	-- Visual Floating
	local startPos = container.Position
	local floatTween = TweenService:Create(container, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = startPos + Vector3.new(0, 2, 0)})
	floatTween:Play()
	
	-- Also tween core to follow manually or use weld logic
	-- Since they are both anchored, I'll update core position in the pulse loop
	task.spawn(function()
		while container.Parent do
			core.Position = container.Position
			container.CFrame = container.CFrame * CFrame.Angles(0, math.rad(1), 0)
			task.wait(0.01)
		end
	end)
	
	-- Interaction
	local connection
	connection = container.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player and not character:GetAttribute("PowerUpActive") then
			connection:Disconnect()
			container:Destroy()
			
			-- Choose random ability from category
			local categoryData = GameConstants.POWERUP_CATEGORIES[chosenCategoryKey]
			local abilities = categoryData.Abilities
			local chosenAbility = abilities[math.random(1, #abilities)]
			
			PowerUpService.ApplyBuff(character, chosenAbility)
			
			-- Respawn immediately
			task.delay(1, function()
				PowerUpService.SpawnPotion()
			end)
		end
	end)
end

function PowerUpService.ApplyBuff(character, powerKey)
	local data = GameConstants.POWERUP_TYPES[powerKey]
	character:SetAttribute("PowerUpActive", true)
	character:SetAttribute("ActivePowerType", powerKey)
	
	-- Notify Server/Players
	local player = Players:GetPlayerFromCharacter(character)
	local playerName = player and player.Name or character.Name
	print(string.format("--- POWERUP: %s used %s Potion! ---", playerName, data.Name))
	
	local remoteNotice = ReplicatedStorage:FindFirstChild("PowerUpNotice")
	if remoteNotice then
		remoteNotice:FireAllClients(playerName, powerKey, "COLLECT")
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- APPLY EFFECTS BASED ON TYPE
	if powerKey == "GIANT" then
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			humanoid.BodyHeightScale.Value *= 2
			humanoid.BodyWidthScale.Value *= 2
			humanoid.BodyDepthScale.Value *= 2
			humanoid.HeadScale.Value *= 2
			task.defer(function() humanoid:BuildRigFromAttachments() end)
		end
		character:SetAttribute("IsGiant", true)
		humanoid.JumpPower = 75 -- Scale jump with size
	elseif powerKey == "SPEED" then
		humanoid.WalkSpeed = 45
	elseif powerKey == "TRIPLE" then
		character:SetAttribute("HasTripleShot", true)
	elseif powerKey == "MEGA" then
		character:SetAttribute("HasMegaBalls", true)
	elseif powerKey == "RAPID" then
		character:SetAttribute("HasRapidFire", true)
	elseif powerKey == "JUMP" then
		humanoid.JumpPower = 120
	elseif powerKey == "SHIELD" then
		character:SetAttribute("HasShield", true)
		-- Visual Shield
		local s = Instance.new("ForceField")
		s.Name = "PowerShield"
		s.Visible = true
		s.Parent = character
	elseif powerKey == "EXPLOSIVE" then
		character:SetAttribute("HasExplosiveBalls", true)
	elseif powerKey == "PHANTOM" then
		humanoid.WalkSpeed = 26
		local fire = Instance.new("Fire")
		fire.Name = "GhostFire"
		fire.Color = Color3.fromRGB(0, 200, 255)
		fire.SecondaryColor = Color3.fromRGB(0, 0, 255)
		fire.Parent = character:FindFirstChild("HumanoidRootPart")
		for _, v in ipairs(character:GetDescendants()) do
			if v:IsA("BasePart") then v.Transparency = 0.6 end
		end
	elseif powerKey == "MINI" then
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			humanoid.BodyHeightScale.Value = 0.4
			humanoid.BodyWidthScale.Value = 0.4
			humanoid.BodyDepthScale.Value = 0.4
			humanoid.HeadScale.Value = 0.4
			task.defer(function() humanoid:BuildRigFromAttachments() end)
		end
		humanoid.WalkSpeed = 30
	elseif powerKey == "FIRE" then
		character:SetAttribute("HasFirePower", true)
	elseif powerKey == "BOUNCE" then
		character:SetAttribute("HasBouncingBalls", true)
	elseif powerKey == "GRAVITY" then
		humanoid.JumpPower = 150
		character:SetAttribute("HasAntiGravity", true)
		character:SetAttribute("HasLowGravity", true)
	elseif powerKey == "FROSTBIT" then
		character:SetAttribute("HasFrostTrail", true)
	elseif powerKey == "VORTEX" then
		character:SetAttribute("HasVortexPower", true)
	elseif powerKey == "MIRAGE" then
		character:SetAttribute("HasMirage", true)
		local CollectionService = game:GetService("CollectionService")
		for i = 1, 3 do
			local decoyModel = Instance.new("Model")
			decoyModel.Name = "MirageDecoy"
			
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(2, 3, 1)
			torso.Color = data.Color
			torso.Material = Enum.Material.Neon
			torso.Transparency = 0.6
			torso.Anchored = true
			torso.CanCollide = false
			torso.CFrame = character.PrimaryPart.CFrame * CFrame.new(math.random(-20, 20), 0, math.random(-20, 20))
			torso.Parent = decoyModel
			
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(1.2, 1.2, 1.2)
			head.Color = data.Color
			head.Material = Enum.Material.Neon
			head.Transparency = 0.5
			head.Anchored = true
			head.CanCollide = false
			head.CFrame = torso.CFrame * CFrame.new(0, 2.2, 0)
			head.Parent = decoyModel
			
			decoyModel.Parent = workspace
			CollectionService:AddTag(torso, "Decoy")
			
			-- Aggro Particle (Radial Pulse)
			local p = Instance.new("ParticleEmitter")
			p.Color = ColorSequence.new(data.Color)
			p.Size = NumberSequence.new(0.5, 2)
			p.Transparency = NumberSequence.new(0, 1)
			p.Lifetime = NumberRange.new(2)
			p.Rate = 15
			p.Speed = NumberRange.new(5, 10)
			p.Texture = "rbxassetid://6071575923"
			p.Parent = torso
			
			-- Holographic Pulse Animation
			task.spawn(function()
				while decoyModel.Parent do
					local t = os.clock()
					local pulse = 0.5 + math.sin(t * 10) * 0.2
					torso.Transparency = pulse
					head.Transparency = pulse
					task.wait(0.05)
				end
			end)
			
			task.delay(GameConstants.POWERUP_DURATION, function() if decoyModel then decoyModel:Destroy() end end)
		end
	elseif powerKey == "GOD" then
		character:SetAttribute("IsInvincible", true)
		local ff = Instance.new("ForceField")
		ff.Name = "GodFF"
		ff.Parent = character
	elseif powerKey == "BERSERK" then
		humanoid.WalkSpeed = 50
		character:SetAttribute("IsBerserk", true)
	elseif powerKey == "STUN" then
		character:SetAttribute("HasStunBalls", true)
	
	-- 20 NEW TYPES
	elseif powerKey == "TELEPORT" then
		local CollectionService = game:GetService("CollectionService")
		local peaks = CollectionService:GetTagged("PyramidPeak")
		if #peaks > 0 then
			-- 1. Teleport the Player
			local target = peaks[math.random(1, #peaks)]
			character:SetPrimaryPartCFrame(target.CFrame * CFrame.new(0, 10, 0))
			
			-- Visual Flash
			local function createFlash(pos)
				local flash = Instance.new("Part")
				flash.Size = Vector3.new(6, 6, 6)
				flash.Shape = Enum.PartType.Ball
				flash.Color = Color3.fromRGB(255, 255, 255)
				flash.Material = Enum.Material.Neon
				flash.Anchored = true flash.CanCollide = false
				flash.Position = pos flash.Parent = workspace
				TweenService:Create(flash, TweenInfo.new(0.4), {Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
				task.delay(0.4, function() flash:Destroy() end)
			end
			createFlash(character.PrimaryPart.Position)

			-- 2. FROST DISPATCH: Teleport all frozen entities
			print("TELEPORT: Dispatching frozen souls...")
			for _, m in ipairs(workspace:GetDescendants()) do
				if m:IsA("Model") and m:GetAttribute("IsFrozen") then
					local randPeak = peaks[math.random(1, #peaks)]
					local root = m:FindFirstChild("HumanoidRootPart")
					if root then
						createFlash(root.Position) -- Flash at old pos
						m:SetPrimaryPartCFrame(randPeak.CFrame * CFrame.new(0, 10, 0))
						createFlash(root.Position) -- Flash at new pos
					end
				end
			end
		end
	elseif powerKey == "AURA" then
		character:SetAttribute("HasIceAura", true)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			-- 1. Core Vortex (Rotating Frost)
			local p1 = Instance.new("ParticleEmitter")
			p1.Name = "IceAura_Core"
			p1.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
			p1.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 4), NumberSequenceKeypoint.new(1, 0)})
			p1.Transparency = NumberSequence.new(0.5, 1)
			p1.Lifetime = NumberRange.new(1)
			p1.Rate = 40
			p1.Rotation = NumberRange.new(0, 360)
			p1.RotSpeed = NumberRange.new(200, 400)
			p1.Speed = NumberRange.new(0)
			p1.LockedToPart = true
			p1.Texture = "rbxassetid://6071575923"
			p1.Parent = root
			
			-- 2. Outer Blizzard (Snowflakes falling/swirling)
			local p2 = Instance.new("ParticleEmitter")
			p2.Name = "IceAura_Blizzard"
			p2.Color = ColorSequence.new(Color3.fromRGB(200, 255, 255))
			p2.Size = NumberSequence.new(0.5, 0)
			p2.Transparency = NumberSequence.new(0.2, 1)
			p2.Lifetime = NumberRange.new(1.5, 2.5)
			p2.Rate = 60
			p2.Speed = NumberRange.new(5, 15)
			p2.VelocitySpread = 180
			p2.Acceleration = Vector3.new(0, -10, 0)
			p2.Texture = "rbxassetid://6071575923"
			p2.Parent = root
			
			-- 3. Ground Frost Fog
			local smoke = Instance.new("Smoke")
			smoke.Name = "IceAura_Fog"
			smoke.Color = Color3.fromRGB(150, 230, 255)
			smoke.Size = 15
			smoke.Opacity = 0.3
			smoke.Rise = 2
			smoke.Parent = root
		end
	elseif powerKey == "SLOMO" then
		character:SetAttribute("HasSloMo", true)
	elseif powerKey == "REGEN" then
		character:SetAttribute("HasRegen", true)
	elseif powerKey == "METEOR" then
		character:SetAttribute("HasMeteorRain", true)
	elseif powerKey == "WALL" then
		character:SetAttribute("HasWallPower", true)
	elseif powerKey == "INVIS" then
		character:SetAttribute("IsInvis", true)
		for _, v in ipairs(character:GetDescendants()) do
			if v:IsA("BasePart") then v.Transparency = 1 end
		end
	elseif powerKey == "SHOCK" then
		character:SetAttribute("HasShockwave", true)
	elseif powerKey == "BEAM" then
		character:SetAttribute("HasFreezeBeam", true)
	elseif powerKey == "DASH" then
		humanoid.WalkSpeed = 80
	elseif powerKey == "CLONE" then
		character:SetAttribute("HasMasterClones", true)
		local CollectionService = game:GetService("CollectionService")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		local clones = {}
		for i = 1, 4 do
			local decoyModel = Instance.new("Model")
			decoyModel.Name = "MasterClone"
			
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(2, 3, 1)
			torso.Color = data.Color
			torso.Material = Enum.Material.Ice
			torso.Transparency = 0.3
			torso.Anchored = true -- Improved: use manual anchor movement for smooth orbit
			torso.CanCollide = false
			torso.Parent = decoyModel
			
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(1.2, 1.2, 1.2)
			head.Color = data.Color
			head.Material = Enum.Material.Ice
			head.Transparency = 0.2
			head.Anchored = true
			head.CanCollide = false
			head.Parent = decoyModel
			
			decoyModel.Parent = workspace
			CollectionService:AddTag(torso, "Decoy")
			
			-- Frost Flow Particle
			local p = Instance.new("ParticleEmitter")
			p.Color = ColorSequence.new(data.Color)
			p.Size = NumberSequence.new(0.4, 0)
			p.Transparency = NumberSequence.new(0, 1)
			p.Lifetime = NumberRange.new(1)
			p.Rate = 20
			p.Speed = NumberRange.new(2, 5)
			p.Texture = "rbxassetid://6071575923"
			p.Parent = torso
			
			-- Retribution: FREEZE ON TOUCH
			torso.Touched:Connect(function(hit)
				local m = hit:FindFirstAncestorOfClass("Model")
				if m and m:FindFirstChild("Humanoid") and m ~= character then
					local fs = require(script.Parent.FreezeService)
					local owner = Players:GetPlayerFromCharacter(character)
					fs.ApplyHit(m, owner)
				end
			end)
			
			table.insert(clones, {model = decoyModel, torso = torso, head = head, offset = (i-1) * (math.pi*2/4)})
			task.delay(GameConstants.POWERUP_DURATION, function() if decoyModel then decoyModel:Destroy() end end)
		end
		
		-- Orbital Task
		task.spawn(function()
			local startTime = os.clock()
			while character.Parent and character:GetAttribute("HasMasterClones") and #clones > 0 do
				local now = os.clock()
				local angleBase = now * 3 -- Rotation speed
				
				for _, c in ipairs(clones) do
					if c.model.Parent then
						local angle = angleBase + c.offset
						local targetPos = root.Position + Vector3.new(math.cos(angle) * 12, 1.5, math.sin(angle) * 12)
						c.torso.CFrame = CFrame.new(targetPos, root.Position)
						c.head.CFrame = c.torso.CFrame * CFrame.new(0, 2.2, 0)
					end
				end
				task.wait(0.01)
			end
		end)
	elseif powerKey == "VENOM" then
		character:SetAttribute("HasVenom", true)
	elseif powerKey == "THORN" then
		character:SetAttribute("HasThorns", true)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local p = Instance.new("ParticleEmitter")
			p.Name = "ThornEffect"
			p.Color = ColorSequence.new(data.Color)
			p.Size = NumberSequence.new(2, 0)
			p.Transparency = NumberSequence.new(0.5, 1)
			p.Lifetime = NumberRange.new(0.8)
			p.Rate = 12
			p.Speed = NumberRange.new(5)
			p.VelocitySpread = 360
			-- Shape like a triangular spike (using a built-in star or similar)
			p.Texture = "rbxassetid://6071575923"
			p.Parent = root
		end
	elseif powerKey == "TITAN" then
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			humanoid.BodyHeightScale.Value = 4
			humanoid.BodyWidthScale.Value = 4
			humanoid.BodyDepthScale.Value = 4
			humanoid.HeadScale.Value = 4
			task.defer(function() humanoid:BuildRigFromAttachments() end)
		end
		character:SetAttribute("IsTitan", true)
		humanoid.JumpPower = 100
	elseif powerKey == "PULL" then
		character:SetAttribute("HasMagneticPull", true)
	elseif powerKey == "BLIZZARD" then
		character:SetAttribute("HasBlizzard", true)
	elseif powerKey == "LASER" then
		character:SetAttribute("HasLaser", true)
	elseif powerKey == "SHRINK" then
		character:SetAttribute("HasShrinkRay", true)
	elseif powerKey == "FLY" then
		character:SetAttribute("HasFlight", true)
		local bv = Instance.new("BodyVelocity")
		bv.Name = "FlightVelocity"
		bv.Velocity = Vector3.new(0, 25, 0) -- Vertical lift
		bv.MaxForce = Vector3.new(0, 100000, 0) -- Only Y axis!
		bv.Parent = character.PrimaryPart
		humanoid.JumpPower = 0 -- Disable jumping while flying
	elseif powerKey == "TIME" then
		character:SetAttribute("HasTimeRecall", true)
		character:SetAttribute("RecallPos", character.PrimaryPart.Position)
	end
	
	-- Premium Visual: Power Aura (Color-Coded)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local p = Instance.new("ParticleEmitter")
		p.Name = "PowerAura"
		p.Color = ColorSequence.new(data.Color)
		p.LightEmission = 0.8
		p.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
		p.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
		p.Speed = NumberRange.new(2, 5)
		p.Lifetime = NumberRange.new(0.5, 1.2)
		p.Acceleration = Vector3.new(0, 5, 0)
		p.Texture = "rbxassetid://6071575923" -- Sparkly Snow/Spark
		p.Parent = root
	end
	
	-- Global Cleanup logic
	task.delay(GameConstants.POWERUP_DURATION, function()
		if character and character.Parent then
			PowerUpService.RemoveBuff(character)
		end
	end)
end

function PowerUpService.RemoveBuff(character)
	if not character:GetAttribute("PowerUpActive") then return end
	
	local powerKey = character:GetAttribute("ActivePowerType")
	character:SetAttribute("PowerUpActive", false)
	character:SetAttribute("ActivePowerType", nil)
	
	-- ABILITY: Time Recall (Teleport back on expiration)
	if character:GetAttribute("HasTimeRecall") then
		local oldPos = character:GetAttribute("RecallPos")
		if oldPos and character.PrimaryPart then
			-- Visual Flash at old position
			local flash = Instance.new("Part")
			flash.Size = Vector3.new(5, 5, 5)
			flash.Shape = Enum.PartType.Ball
			flash.Color = Color3.fromRGB(0, 255, 255)
			flash.Material = Enum.Material.Neon
			flash.Transparency = 0.5
			flash.Anchored = true flash.CanCollide = false
			flash.CFrame = character.PrimaryPart.CFrame
			flash.Parent = workspace
			
			character:SetPrimaryPartCFrame(CFrame.new(oldPos))
			
			-- Visual Flash at new position
			local flash2 = flash:Clone()
			flash2.CFrame = character.PrimaryPart.CFrame
			flash2.Parent = workspace
			
			local TweenService = game:GetService("TweenService") -- Assuming TweenService is not globally defined, get it here.
			TweenService:Create(flash, TweenInfo.new(0.5), {Size = Vector3.new(0, 0, 0), Transparency = 1}):Play()
			TweenService:Create(flash2, TweenInfo.new(0.5), {Size = Vector3.new(10, 10, 10), Transparency = 1}):Play()
			task.delay(0.5, function() if flash then flash:Destroy() end if flash2 then flash2:Destroy() end end)
		end
	end
	
	-- Reset all possible attributes (Total 39 Potions)
	character:SetAttribute("HasTripleShot", nil)
	character:SetAttribute("HasMegaBalls", nil)
	character:SetAttribute("HasRapidFire", nil)
	character:SetAttribute("HasExplosiveBalls", nil)
	character:SetAttribute("HasShield", nil)
	character:SetAttribute("HasFirePower", nil)
	character:SetAttribute("HasBouncingBalls", nil)
	character:SetAttribute("HasAntiGravity", nil)
	character:SetAttribute("HasFrostTrail", nil)
	character:SetAttribute("HasVortexPower", nil)
	character:SetAttribute("HasMirage", nil)
	character:SetAttribute("IsBerserk", nil)
	character:SetAttribute("HasStunBalls", nil)
	character:SetAttribute("HasTeleport", nil)
	character:SetAttribute("HasIceAura", nil)
	character:SetAttribute("HasSloMo", nil)
	character:SetAttribute("HasRegen", nil)
	character:SetAttribute("HasMeteorRain", nil)
	character:SetAttribute("HasWallPower", nil)
	character:SetAttribute("IsInvis", nil)
	character:SetAttribute("HasShockwave", nil)
	character:SetAttribute("HasFreezeBeam", nil)
	character:SetAttribute("HasMasterClones", nil)
	character:SetAttribute("HasVenom", nil)
	character:SetAttribute("HasThorns", nil)
	character:SetAttribute("HasMagneticPull", nil)
	character:SetAttribute("HasBlizzard", nil)
	character:SetAttribute("HasLaser", nil)
	character:SetAttribute("HasShrinkRay", nil)
	character:SetAttribute("HasFlight", nil)
	character:SetAttribute("HasTimeRecall", nil)
	character:SetAttribute("RecallPos", nil)
	character:SetAttribute("IsInvincible", nil)
	character:SetAttribute("IsGiant", nil)
	character:SetAttribute("IsTitan", nil)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.PlatformStand = false
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			humanoid.BodyHeightScale.Value = 1
			humanoid.BodyWidthScale.Value = 1
			humanoid.BodyDepthScale.Value = 1
			humanoid.HeadScale.Value = 1
			task.defer(function() humanoid:BuildRigFromAttachments() end)
		end
	end
	
	-- Visual Cleanups
	local s = character:FindFirstChild("PowerShield")
	if s then s:Destroy() end
	local ff = character:FindFirstChild("GodFF")
	if ff then ff:Destroy() end
	local bv = character.PrimaryPart and character.PrimaryPart:FindFirstChild("FlightVelocity")
	if bv then bv:Destroy() end
	local gf = character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart:FindFirstChild("GhostFire")
	if gf then gf:Destroy() end
	local pa = character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart:FindFirstChild("PowerAura")
	if pa then pa:Destroy() end
	local iae = character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart:FindFirstChild("IceAuraEffect")
	if iae then iae:Destroy() end
	
	for _, v in ipairs(character:GetChildren()) do
		if v.Name == "MirageDecoy" or v.Name == "MasterClone" then v:Destroy() end
	end
	
	for _, v in ipairs(character:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
	end
	
	print(string.format("POWERUP: Buff expired for %s", character.Name))
end

local function isAnyPlayerPoweredUp()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:GetAttribute("PowerUpActive") then
			return true
		end
	end
	return false
end

function PowerUpService.StartLoop()
	task.spawn(function()
		print("POWERUP: Starting Spawn Loop...")
		while true do
			local success, err = pcall(function()
				local potionExists = workspace:FindFirstChild("PotionCrystal")
				if not potionExists then
					local now = os.clock()
					if now >= nextSpawnTime then
						PowerUpService.SpawnPotion()
					end
				end
			end)
			
			if not success then
				warn("POWERUP: Loop Error: " .. tostring(err))
			end
			
			-- PERIODIC POWER-UP LOGIC
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char and char:GetAttribute("PowerUpActive") then
					local root = char:FindFirstChild("HumanoidRootPart")
					local hum = char:FindFirstChildOfClass("Humanoid")
					if not root or not hum then continue end
					
					-- 1. Frost Trail (Functional: Freezes on touch)
					if char:GetAttribute("HasFrostTrail") then
						local trail = Instance.new("Part")
						trail.Name = "FrostTrailPart"
						trail.Size = Vector3.new(4, 0.4, 4)
						trail.Position = root.Position - Vector3.new(0, 3, 0)
						trail.Color = Color3.fromRGB(150, 230, 255) trail.Material = Enum.Material.Ice
						trail.Anchored = true trail.CanCollide = false trail.Parent = workspace
						trail.Touched:Connect(function(hit)
							local m = hit.Parent:IsA("Model") and hit.Parent
							if m and m:FindFirstChild("Humanoid") and m ~= char then
								local fs = require(ServerScriptService:WaitForChild("FreezeService"))
								fs.ApplyHit(m, player)
							end
						end)
						task.delay(5, function() if trail then trail:Destroy() end end)
					end
					
					-- 2. Ice Aura (Auto-Freeze) (Already functional)
					
					-- 3. Meteor Rain (Functional: AOE Explosion)
					if char:GetAttribute("HasMeteorRain") then
						local lastMeteor = char:GetAttribute("LastMeteorTime") or 0
						if now - lastMeteor > 2.0 then
							char:SetAttribute("LastMeteorTime", now)
							local mpos = root.Position + Vector3.new(math.random(-20, 20), 50, math.random(-20, 20))
							local met = Instance.new("Part")
							met.Shape = Enum.PartType.Ball met.Size = Vector3.new(4, 4, 4)
							met.Position = mpos met.Color = Color3.fromRGB(0, 200, 255)
							met.Material = Enum.Material.Neon met.Parent = workspace
							met.Touched:Connect(function(hit)
								local pos = met.Position
								local fs = require(ServerScriptService:WaitForChild("FreezeService"))
								for _, p in ipairs(workspace:GetPartBoundsInRadius(pos, 12)) do
									local m = p:FindFirstAncestorOfClass("Model")
									if m and m:FindFirstChild("Humanoid") and m ~= char then
										fs.ApplyHit(m, player) -- Explosive impact (mult is handled inside ApplyHit if passed differently, but here 2nd arg is attacker)
									end
								end
								
								-- Explosion Visual
								local exp = Instance.new("Explosion")
								exp.BlastRadius = 0 exp.Position = pos exp.Parent = workspace
								met:Destroy()
							end)
							task.delay(5, function() if met then met:Destroy() end end)
						end
					end
					
					-- 4. Magnetic Pull (Pull Enemies)
					if char:GetAttribute("HasMagneticPull") then
						for _, p in ipairs(workspace:GetPartBoundsInRadius(root.Position, 30)) do
							local m = p:FindFirstAncestorOfClass("Model")
							if m and m:FindFirstChild("Humanoid") and m ~= char then
								local targetRoot = m:FindFirstChild("HumanoidRootPart")
								if targetRoot then
									local dir = (root.Position - targetRoot.Position).Unit
									targetRoot:ApplyImpulse(dir * 1000)
								end
							end
						end
					end
					
					-- 5. Shockwave (Onda Gélida)
					if char:GetAttribute("HasShockwave") then
						local lastShock = char:GetAttribute("LastShockTime") or 0
						if now - lastShock > 1.8 then
							char:SetAttribute("LastShockTime", now)
							
							-- Visual: Expanding Blast Ring
							local ring = Instance.new("Part")
							ring.Shape = Enum.PartType.Ball
							ring.Color = Color3.fromRGB(0, 255, 255)
							ring.Material = Enum.Material.Neon
							ring.Transparency = 0.5
							ring.Anchored = true
							ring.CanCollide = false
							ring.Position = root.Position
							ring.Parent = workspace
							
							TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(60, 60, 60), Transparency = 1}):Play()
							task.delay(0.6, function() if ring then ring:Destroy() end end)
							
							print(string.format("SHOCKWAVE: %s triggered blast!", player.Name))
							
							for _, p in ipairs(workspace:GetPartBoundsInRadius(root.Position, 30)) do
								local m = p:FindFirstAncestorOfClass("Model")
								if m and m:FindFirstChild("Humanoid") and m ~= char then
									local targetRoot = m:FindFirstChild("HumanoidRootPart")
									local thum = m.Humanoid
									if targetRoot then
										local dir = (targetRoot.Position - root.Position).Unit
										targetRoot:ApplyImpulse(dir * 7000)
										
										-- Tactics: Apply FREEZE
										FreezeService.ApplyHit(m, player)
										
										-- Damage for enemies
										if not Players:GetPlayerFromCharacter(m) then
											thum:TakeDamage(5)
										end
									end
								end
							end
						end
					end
					
					-- 6. Flight (Directional control using MoveDirection)
					if char:GetAttribute("HasFlight") then
						local bv = root:FindFirstChild("FlightVelocity")
						local hum = char:FindFirstChildOfClass("Humanoid")
						if bv and hum then
							-- Vertical lift + Horizontal control based on player input
							local horizontalVel = hum.MoveDirection * 40
							bv.Velocity = horizontalVel + Vector3.new(0, 25 + math.sin(os.clock()*2)*2, 0)
							bv.MaxForce = Vector3.new(40000, 100000, 40000) -- Allow horizontal force
						end
					end
					
					-- 7. Regen (Health)
					if char:GetAttribute("HasRegen") then
						local hits = char:GetAttribute("HitsTaken") or 0
						if hits > 0 then
							char:SetAttribute("HitsTaken", hits - 0.2) -- Slow heal
						end
					end
					
					-- 9. Low Gravity (Slow Fall)
					if char:GetAttribute("HasLowGravity") then
						if root.AssemblyLinearVelocity.Y < -5 then
							root:ApplyImpulse(Vector3.new(0, 200, 0)) -- Gentle lift
						end
					end
					
					-- 8. Blizzard (Area control)
					if char:GetAttribute("HasBlizzard") then
						local lastBliz = char:GetAttribute("LastBlizTime") or 0
						if now - lastBliz > 1.0 then
							char:SetAttribute("LastBlizTime", now)
							local cloud = Instance.new("Smoke")
							cloud.Color = Color3.fromRGB(200, 240, 255)
							cloud.Size = 20 cloud.Opacity = 0.5 cloud.Parent = root
							task.delay(1.5, function() cloud:Destroy() end)
							
							for _, p in ipairs(workspace:GetPartBoundsInRadius(root.Position, 40)) do
								local m = p:FindFirstAncestorOfClass("Model")
								if m and m:FindFirstChild("Humanoid") and m ~= char then
									local thum = m.Humanoid
									thum:TakeDamage(2)
									local oldSpeed = thum.WalkSpeed
									thum.WalkSpeed = 8
									task.delay(1, function() if thum then thum.WalkSpeed = oldSpeed end end)
								end
							end
						end
					end
				end
			end
			
			task.wait(0.2)
		end
	end)
end

return PowerUpService
