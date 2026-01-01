local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("--- FROST BROS DEBUG: CLIENT STARTING ---")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local lastFire = 0

local function fire()
	if os.clock() - lastFire < GameConstants.FIRE_RATE then return end
	lastFire = os.clock()
	
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local startPos = root.Position + root.CFrame.LookVector * 2
	local targetPos = mouse.Hit.Position
	local direction = (targetPos - startPos).Unit
	
	local projectile = Instance.new("Part")
	projectile.Size = Vector3.new(0.6, 0.6, 2.5)
	projectile.Color = Color3.fromRGB(180, 230, 255)
	projectile.Material = Enum.Material.Neon
	projectile.CanCollide = false
	projectile.Anchored = true
	projectile.CFrame = CFrame.lookAt(startPos, targetPos)
	projectile.Parent = workspace
	
	task.spawn(function()
		local distance = 0
		while distance < GameConstants.PROJECTILE_RANGE do
			local step = GameConstants.PROJECTILE_SPEED * task.wait()
			distance += step
			projectile.CFrame = projectile.CFrame * CFrame.new(0, 0, -step)
			
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {character, projectile}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local result = workspace:Raycast(projectile.Position, projectile.CFrame.LookVector * 2, rayParams)
			if result then
				local remote = ReplicatedStorage:FindFirstChild("IceHit")
				if remote then
					remote:FireServer(result.Instance)
				end
				break
			end
		end
		projectile:Destroy()
	end)
end

ContextActionService:BindAction("FireIce", function(_, state)
	if state == Enum.UserInputState.Begin then
		fire()
	end
end, false, Enum.UserInputType.MouseButton1)

print("--- FROST BROS CLIENT: GUN READY ---")