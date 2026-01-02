local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local PowerUpService = {}
local nextSpawnTime = 0

function PowerUpService.SpawnPotion(bypassTimer)
	if bypassTimer then
		nextSpawnTime = 0
	end
	
	if os.clock() < nextSpawnTime then return end
	
	local typeKeys = {}
	for k, _ in pairs(GameConstants.POWERUP_TYPES) do table.insert(typeKeys, k) end
	local chosenKey = typeKeys[math.random(1, #typeKeys)]
	local chosenData = GameConstants.POWERUP_TYPES[chosenKey]
	
	print("POWERUP: Spawning Potion of " .. chosenData.Name)
	
	local potion = Instance.new("Part")
	potion.Name = "GiantPotion"
	potion.Size = Vector3.new(2, 3.5, 2)
	potion.Color = chosenData.Color
	potion.Material = Enum.Material.Neon
	potion.Anchored = true
	potion.CanCollide = false
	potion:SetAttribute("PowerType", chosenKey)
	
	local CollectionService = game:GetService("CollectionService")
	local peaks = CollectionService:GetTagged("PyramidPeak")
	
	if #peaks == 0 then
		print("POWERUP: Error - No PyramidPeaks found in workspace!")
		return
	end
	
	local targetPeak = peaks[math.random(1, #peaks)]
	potion.Position = targetPeak.Position + Vector3.new(0, 6, 0)
	potion.Parent = workspace
	
	-- Notification of Spawn
	local remoteNotice = ReplicatedStorage:FindFirstChild("PowerUpNotice")
	if remoteNotice then
		remoteNotice:FireAllClients("SERVER", chosenKey, "SPAWN")
	end
	
	-- Visual Floating
	local startPos = potion.Position
	local floatTween = TweenService:Create(potion, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = startPos + Vector3.new(0, 1.5, 0)})
	floatTween:Play()
	
	-- Interaction
	local connection
	connection = potion.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player and not character:GetAttribute("PowerUpActive") then
			connection:Disconnect()
			potion:Destroy()
			nextSpawnTime = os.clock() + 5
			PowerUpService.ApplyBuff(character, chosenKey)
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
			local decoy = Instance.new("Part")
			decoy.Name = "MirageDecoy"
			decoy.Size = Vector3.new(2, 5, 2)
			decoy.Transparency = 0.4
			decoy.Color = data.Color
			decoy.Material = Enum.Material.Neon
			decoy.CFrame = character.PrimaryPart.CFrame * CFrame.new(math.random(-15, 15), 0, math.random(-15, 15))
			decoy.Anchored = true
			decoy.CanCollide = false
			decoy.CanTouch = false
			decoy.Parent = workspace
			CollectionService:AddTag(decoy, "Decoy")
			
			-- Add ghostly particle
			local p = Instance.new("ParticleEmitter")
			p.Color = ColorSequence.new(data.Color)
			p.Size = NumberSequence.new(1, 0)
			p.Transparency = NumberSequence.new(0.5, 1)
			p.Lifetime = NumberRange.new(1)
			p.Rate = 20
			p.Texture = "rbxassetid://6071575923"
			p.Parent = decoy
			
			-- Pulsing Animation
			local tInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local pulse = TweenService:Create(decoy, tInfo, {Transparency = 0.8, Size = decoy.Size * 1.2})
			pulse:Play()
			
			task.delay(GameConstants.POWERUP_DURATION, function() if decoy then decoy:Destroy() end end)
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
			local target = peaks[math.random(1, #peaks)]
			character:SetPrimaryPartCFrame(target.CFrame * CFrame.new(0, 10, 0))
		end
	elseif powerKey == "AURA" then
		character:SetAttribute("HasIceAura", true)
		local p = Instance.new("ParticleEmitter")
		p.Name = "IceAuraEffect"
		p.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
		p.Size = NumberSequence.new(3, 0)
		p.Transparency = NumberSequence.new(0.5, 1)
		p.Lifetime = NumberRange.new(1.5)
		p.Rate = 10
		p.Speed = NumberRange.new(0)
		p.LockedToPart = true
		p.Texture = "rbxassetid://6071575923"
		p.Parent = character:FindFirstChild("HumanoidRootPart")
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
		for i = 1, 4 do
			local decoy = Instance.new("Part")
			decoy.Name = "MasterClone"
			decoy.Size = Vector3.new(2, 5, 2)
			decoy.Color = data.Color
			decoy.Material = Enum.Material.Ice
			decoy.CFrame = character.PrimaryPart.CFrame * CFrame.new(math.random(-20, 20), 0, math.random(-20, 20))
			decoy.Anchored = false
			decoy.CanCollide = false
			decoy.CanTouch = false
			decoy.Parent = workspace
			CollectionService:AddTag(decoy, "Decoy")
			
			local bp = Instance.new("BodyPosition")
			bp.MaxForce = Vector3.new(1, 0, 1) * 20000
			bp.Position = decoy.Position
			bp.Parent = decoy
			
			-- Particle for clone
			local p = Instance.new("ParticleEmitter")
			p.Color = ColorSequence.new(data.Color)
			p.Texture = "rbxassetid://6071575923"
			p.Parent = decoy
			
			task.delay(GameConstants.POWERUP_DURATION, function() if decoy then decoy:Destroy() end end)
		end
	elseif powerKey == "VENOM" then
		character:SetAttribute("HasVenom", true)
	elseif powerKey == "THORN" then
		character:SetAttribute("HasThorns", true)
	elseif powerKey == "TITAN" then
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			humanoid.BodyHeightScale.Value = 4
			humanoid.BodyWidthScale.Value = 4
			humanoid.BodyDepthScale.Value = 4
			humanoid.HeadScale.Value = 4
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
		humanoid.PlatformStand = true
		local bv = Instance.new("BodyVelocity")
		bv.Name = "FlightVelocity"
		bv.Velocity = Vector3.zero
		bv.MaxForce = Vector3.new(1, 1, 1) * 100000
		bv.Parent = character.PrimaryPart
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
				local potionExists = workspace:FindFirstChild("GiantPotion")
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
								fs.ApplyHit(m)
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
										fs.ApplyHit(m, 2) -- Explosive impact
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
					
					-- 5. Shockwave
					if char:GetAttribute("HasShockwave") then
						local lastShock = char:GetAttribute("LastShockTime") or 0
						if now - lastShock > 1.5 then
							char:SetAttribute("LastShockTime", now)
							for _, p in ipairs(workspace:GetPartBoundsInRadius(root.Position, 25)) do
								local m = p:FindFirstAncestorOfClass("Model")
								if m and m:FindFirstChild("Humanoid") and m ~= char then
									local targetRoot = m:FindFirstChild("HumanoidRootPart")
									if targetRoot then
										local dir = (targetRoot.Position - root.Position).Unit
										targetRoot:ApplyImpulse(dir * 4000)
									end
								end
							end
						end
					end
					
					-- 6. Flight
					if char:GetAttribute("HasFlight") then
						local bv = root:FindFirstChild("FlightVelocity")
						if bv then
							bv.Velocity = root.CFrame.LookVector * 40 + Vector3.new(0, 2, 0)
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
