local MapService = {}

function MapService.BuildArena()
	local folder = workspace:FindFirstChild("Arena") or Instance.new("Folder")
	folder.Name = "Arena"
	folder.Parent = workspace
	folder:ClearAllChildren()
	
	local CollectionService = game:GetService("CollectionService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local GameConstants = require(Shared:WaitForChild("GameConstants"))
	
	local size = GameConstants.ARENA_SIZE
	local wallHeight = 20
	local wallThickness = 4
	local ICE_COLOR = Color3.fromRGB(200, 240, 255)
	local SNOW_COLOR = Color3.fromRGB(255, 255, 255)
	
	-- FIX FLICKERING: Find and remove default Baseplate
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then baseplate:Destroy() end
	
	-- 1. FROSTY FLOOR
	local floor = Instance.new("Part")
	floor.Name = "SnowFloor"
	floor.Size = Vector3.new(size + 60, 2, size + 60)
	floor.Position = Vector3.new(0, -0.95, 0) -- Top surface is now at 0.05
	floor.Color = SNOW_COLOR
	floor.Material = Enum.Material.Snow
	floor.Anchored = true
	floor.Parent = folder
	
	-- 2. CASTLE WALLS & CRENELLATIONS
	local function createCastleWall(name, pos, wSize)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = wSize
		wall.Position = pos
		wall.Color = ICE_COLOR
		wall.Material = Enum.Material.Ice
		wall.Anchored = true
		wall.Parent = folder
		
		-- Merlons (Crenellations)
		local merlonSize = 4
		local numMerlons = math.floor(wSize.Magnitude / (merlonSize * 2))
		
		for i = 0, numMerlons do
			local merlon = Instance.new("Part")
			if wSize.X > wSize.Z then
				merlon.Position = pos + Vector3.new(-wSize.X/2 + i * merlonSize * 2 + merlonSize/2, wallHeight/2 + 1.5, 0)
				merlon.Size = Vector3.new(merlonSize, 3, wSize.Z)
			else
				merlon.Position = pos + Vector3.new(0, wallHeight/2 + 1.5, -wSize.Z/2 + i * merlonSize * 2 + merlonSize/2)
				merlon.Size = Vector3.new(wSize.X, 3, merlonSize)
			end
			merlon.Color = ICE_COLOR
			merlon.Material = Enum.Material.Ice
			merlon.Anchored = true
			merlon.Parent = folder
		end
	end
	
	createCastleWall("WallN", Vector3.new(0, wallHeight/2, size/2), Vector3.new(size, wallHeight, wallThickness))
	createCastleWall("WallS", Vector3.new(0, wallHeight/2, -size/2), Vector3.new(size, wallHeight, wallThickness))
	createCastleWall("WallE", Vector3.new(size/2, wallHeight/2, 0), Vector3.new(wallThickness, wallHeight, size))
	createCastleWall("WallW", Vector3.new(-size/2, wallHeight/2, 0), Vector3.new(wallThickness, wallHeight, size))
	
	-- 3. TOWERS (Uniform Stepped Pyramids)
	local function createTower(pos, canSpawn)
		local numLayers = 7
		local baseSize = 30
		local layerHeight = 3.5
		
		for i = 1, numLayers do
			local currentScale = 1 - (i-1) * 0.12
			local lSize = baseSize * currentScale
			
			local layer = Instance.new("Part")
			layer.Name = "PyramidLayer"
			layer.Size = Vector3.new(lSize, layerHeight, lSize)
			layer.Position = pos + Vector3.new(0, (i-1) * layerHeight + layerHeight/2 - 1, 0)
			layer.Color = Color3.fromRGB(200, 240, 255)
			layer.Material = Enum.Material.Ice
			layer.Anchored = true
			layer.Parent = folder
			
			if i == numLayers and canSpawn then
				CollectionService:AddTag(layer, "PyramidPeak")
			end
			
			local cap = Instance.new("Part")
			cap.Size = Vector3.new(lSize, 0.4, lSize)
			cap.Position = layer.Position + Vector3.new(0, layerHeight/2 + 0.2, 0)
			cap.Color = SNOW_COLOR
			cap.Material = Enum.Material.Snow
			cap.Anchored = true
			cap.Parent = folder
		end
	end
	
	-- 4. BRIDGES
	local function createBridge(posA, posB, height)
		local distance = (Vector3.new(posA.X, 0, posA.Z) - Vector3.new(posB.X, 0, posB.Z)).Magnitude
		local bridge = Instance.new("Part")
		bridge.Name = "IceBridge"
		bridge.Size = Vector3.new(6, 1.2, distance - 20) -- Leave gap for pyramid bases
		bridge.CFrame = CFrame.lookAt(posA + Vector3.new(0, height, 0), posB + Vector3.new(0, height, 0)) * CFrame.new(0, 0, -distance/2)
		bridge.Color = Color3.fromRGB(200, 240, 255)
		bridge.Material = Enum.Material.Ice
		bridge.Anchored = true
		bridge.Parent = folder
		
		local cap = Instance.new("Part")
		cap.Size = Vector3.new(6, 0.3, bridge.Size.Z)
		cap.CFrame = bridge.CFrame * CFrame.new(0, 0.7, 0)
		cap.Color = SNOW_COLOR
		cap.Material = Enum.Material.Snow
		cap.Anchored = true
		cap.Parent = folder
	end

	-- 5. DECORATIONS
	local function createDecoration(pos)
		local choice = math.random(1, 3)
		if choice == 1 then
			local spike = Instance.new("Part")
			spike.Size = Vector3.new(2, math.random(6, 15), 2)
			spike.Position = pos + Vector3.new(0, spike.Size.Y/2 - 1, 0)
			spike.Color = Color3.fromRGB(160, 220, 255)
			spike.Material = Enum.Material.Ice
			spike.Orientation = Vector3.new(math.random(-20, 20), math.random(0, 360), math.random(-20, 20))
			spike.Anchored = true
			spike.Parent = folder
		elseif choice == 2 then
			local mound = Instance.new("Part")
			mound.Shape = Enum.PartType.Ball
			local s = math.random(5, 12)
			mound.Size = Vector3.new(s, s, s)
			mound.Position = pos + Vector3.new(0, -s/3, 0)
			mound.Color = SNOW_COLOR
			mound.Material = Enum.Material.Snow
			mound.Anchored = true
			mound.Parent = folder
		else
			local pillar = Instance.new("Part")
			pillar.Size = Vector3.new(4, math.random(10, 20), 4)
			pillar.Position = pos + Vector3.new(0, pillar.Size.Y/2 - 1, 0)
			pillar.Color = Color3.fromRGB(180, 240, 255)
			pillar.Material = Enum.Material.Ice
			pillar.Anchored = true
			pillar.Parent = folder
			local band = Instance.new("Part")
			band.Size = Vector3.new(4.2, 1, 4.2)
			band.Position = pillar.Position + Vector3.new(0, math.random(-3, 3), 0)
			band.Color = Color3.fromRGB(0, 200, 255)
			band.Material = Enum.Material.Neon
			band.Anchored = true
			band.Parent = folder
		end
	end

	local offset = size/2
	-- Corner Pyramids
	createTower(Vector3.new(offset, 0, offset), false)
	createTower(Vector3.new(-offset, 0, offset), false)
	createTower(Vector3.new(offset, 0, -offset), false)
	createTower(Vector3.new(-offset, 0, -offset), false)
	
	-- CENTRAL MASTER PYRAMID
	local centerPos = Vector3.new(0, 0, 0)
	createTower(centerPos, true)
	
	-- 5.5 SPAWN LOCATION (Safe place: Top of the central pyramid)
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "ArenaSpawn"
	spawnLoc.Size = Vector3.new(12, 1, 12)
	spawnLoc.Position = Vector3.new(0, 25, 0) -- Peak of the central tower
	spawnLoc.Transparency = 1
	spawnLoc.CanCollide = false
	spawnLoc.Anchored = true -- CRITICAL: Make sure it doesn't fall!
	spawnLoc.Enabled = true
	spawnLoc.Parent = folder
	
	-- INTERMEDIATE PYRAMIDS
	local mid = size * 0.3
	local intermediatePositions = {
		Vector3.new(mid, 0, 0), Vector3.new(-mid, 0, 0),
		Vector3.new(0, 0, mid), Vector3.new(0, 0, -mid),
		Vector3.new(mid, 0, mid), Vector3.new(-mid, 0, -mid),
		Vector3.new(mid, 0, -mid), Vector3.new(-mid, 0, mid),
	}
	
	for _, pos in ipairs(intermediatePositions) do
		createTower(pos, true)
		createBridge(centerPos, pos, 14) -- Connect central to intermediate
	end
	
	-- Add Decorations in empty spots
	for i = 1, 50 do
		local x = math.random(-size/2, size/2)
		local z = math.random(-size/2, size/2)
		local pos = Vector3.new(x, 0, z)
		
		-- Check distance to pyramids to avoid overlap
		local tooClose = false
		if pos.Magnitude < 25 then tooClose = true end
		for _, pyraPos in ipairs(intermediatePositions) do
			if (pos - pyraPos).Magnitude < 25 then tooClose = true break end
		end
		
		if not tooClose then
			createDecoration(pos)
		end
	end
	-- 6. INVISIBLE CONTAINMENT (Hollow Dome/Box)
	local function createBarrier(name, pos, bSize)
		local barrier = Instance.new("Part")
		barrier.Name = name
		barrier.Size = bSize
		barrier.Position = pos
		barrier.Transparency = 1
		barrier.CanCollide = true
		barrier.CastShadow = false
		barrier.Anchored = true
		barrier.Locked = true
		barrier.Parent = folder
	end

	local barrierHeight = 150
	local barrierThickness = 10
	
	-- Vertical Walls
	createBarrier("BarrierN", Vector3.new(0, barrierHeight/2, size/2 + barrierThickness/2), Vector3.new(size + 20, barrierHeight, barrierThickness))
	createBarrier("BarrierS", Vector3.new(0, barrierHeight/2, -size/2 - barrierThickness/2), Vector3.new(size + 20, barrierHeight, barrierThickness))
	createBarrier("BarrierE", Vector3.new(size/2 + barrierThickness/2, barrierHeight/2, 0), Vector3.new(barrierThickness, barrierHeight, size + 20))
	createBarrier("BarrierW", Vector3.new(-size/2 - barrierThickness/2, barrierHeight/2, 0), Vector3.new(barrierThickness, barrierHeight, size + 20))
	
	-- Ceiling
	createBarrier("BarrierCeiling", Vector3.new(0, barrierHeight, 0), Vector3.new(size + 20, barrierThickness, size + 20))

	-- 7. LIGHTING (Restored)
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(150, 180, 200)
	lighting.OutdoorAmbient = Color3.fromRGB(100, 120, 150)
	lighting.Brightness = 2
	
	print("DECORATED SNOW CASTLE WITH HOLLOW CONTAINMENT BUILT!")
end

return MapService
