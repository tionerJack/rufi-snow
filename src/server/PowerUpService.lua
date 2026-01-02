local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local PowerUpService = {}

local function spawnPotion()
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
	
	-- Random pos
	potion.Position = Vector3.new(math.random(-50, 50), 3, math.random(-50, 50))
	potion.Parent = workspace
	
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
		remoteNotice:FireAllClients(playerName, powerKey)
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
		for _, v in ipairs(character:GetDescendants()) do
			if v:IsA("BasePart") then v.Transparency = 0.6 end
		end
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
	
	-- Reset all possible attributes
	character:SetAttribute("HasTripleShot", nil)
	character:SetAttribute("HasMegaBalls", nil)
	character:SetAttribute("HasRapidFire", nil)
	character:SetAttribute("HasExplosiveBalls", nil)
	character:SetAttribute("HasShield", nil)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
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
		while true do
			local potionExists = workspace:FindFirstChild("GiantPotion")
			local powerUpActive = isAnyPlayerPoweredUp()
			
			if not potionExists and not powerUpActive then
				spawnPotion()
			end
			
			task.wait(10) -- Check availability every 10 seconds
		end
	end)
end

return PowerUpService
