local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local BasicEnemy = {}

function BasicEnemy.Spawn(position, level)
	level = level or 1
	
	-- 1. Create Model
	local model = Instance.new("Model")
	model.Name = "Diablito_Lvl" .. level
	
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3, 3, 3)
	root.Position = position + Vector3.new(0, 5, 0)
	root.Color = Color3.fromRGB(200, 50, 0) -- Fire Imp color
	root.Material = Enum.Material.Neon
	root.Parent = model
	
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(4, 4, 4)
	body.Position = root.Position
	body.Color = Color3.fromRGB(255, 100, 0)
	body.Material = Enum.Material.Neon
	body.Parent = model
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = body
	
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 10 + (level * 2)
	humanoid.Parent = model
	
	model.PrimaryPart = root
	model:SetAttribute("Level", level)
	model:SetAttribute("IsEnemy", true)
	model:SetAttribute("FreezeHits", 0)
	model:SetAttribute("IsFrozen", false)
	
	-- 2. Add Fire Effects (Visual)
	local fire = Instance.new("Fire")
	fire.Name = "FireParticles"
	fire.Color = Color3.fromRGB(255, 150, 0)
	fire.SecondaryColor = Color3.fromRGB(255, 0, 0)
	fire.Size = 8
	fire.Parent = body
	
	local light = Instance.new("PointLight")
	light.Name = "FireLight"
	light.Color = Color3.fromRGB(255, 100, 0)
	light.Range = 15
	light.Brightness = 2
	light.Parent = body

	humanoid.Died:Connect(function()
		task.delay(1, function()
			if model then model:Destroy() end
		end)
	end)

	model.Parent = workspace
	
	-- 3. AI Behavior Loop
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			if not model:GetAttribute("IsFrozen") and not model:GetAttribute("IsRolling") then
				-- Simple AI: Find nearest player
				local target = nil
				local minDist = 100
				
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						local dist = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
						if dist < minDist then
							minDist = dist
							target = player.Character
						end
					end
				end
				
				if target and level > 1 then
					humanoid:MoveTo(target.HumanoidRootPart.Position)
				end
			else
				-- If frozen/rolling, stop moving
				humanoid:MoveTo(root.Position)
			end
			task.wait(1)
		end
	end)
	
	-- 4. Push Detection for Frozen Enemies
	root.Touched:Connect(function(hit)
		if not model:GetAttribute("IsFrozen") or model:GetAttribute("IsRolling") then return end
		
		local pusherModel = hit:FindFirstAncestorOfClass("Model")
		local pusher = pusherModel and Players:GetPlayerFromCharacter(pusherModel)
		
		if pusher and pusher.Character and pusher.Character ~= model then
			local RollLogic = require(script.Parent.RollLogic)
			local pushDir = (root.Position - pusher.Character.HumanoidRootPart.Position) * Vector3.new(1,0,1)
			RollLogic.StartRolling(model, pushDir.Unit, pusher)
		end
	end)

	return model
end

return BasicEnemy
