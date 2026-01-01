local MapService = {}

function MapService.BuildArena()
	local folder = workspace:FindFirstChild("Arena") or Instance.new("Folder")
	folder.Name = "Arena"
	folder.Parent = workspace
	
	-- CLEAR PREVIOUS (If any)
	folder:ClearAllChildren()
	
	local size = 120
	local wallHeight = 25
	
	-- FLOOR
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(size, 2, size)
	floor.Position = Vector3.new(0, 0, 0)
	floor.Color = Color3.fromRGB(50, 150, 50) -- Grass Green
	floor.Material = Enum.Material.Grass
	floor.Anchored = true
	floor.Parent = folder
	
	-- WALLS (Enclosure)
	local function createWall(name, pos, wallSize)
		local wall = Instance.new("Part")
		wall.Name = name
		wall.Size = wallSize
		wall.Position = pos
		wall.Color = Color3.fromRGB(80, 80, 80)
		wall.Material = Enum.Material.SmoothPlastic
		wall.Anchored = true
		wall.Parent = folder
		
		-- Wall Trim (Mario style)
		local trim = Instance.new("Part")
		trim.Size = Vector3.new(wallSize.X + 0.5, 2, wallSize.Z + 0.5)
		trim.Position = pos + Vector3.new(0, wallHeight/2, 0)
		trim.Color = Color3.fromRGB(200, 160, 50)
		trim.Anchored = true
		trim.Parent = folder
	end
	
	createWall("WallNorth", Vector3.new(0, wallHeight/2, size/2), Vector3.new(size, wallHeight, 2))
	createWall("WallSouth", Vector3.new(0, wallHeight/2, -size/2), Vector3.new(size, wallHeight, 2))
	createWall("WallEast", Vector3.new(size/2, wallHeight/2, 0), Vector3.new(2, wallHeight, size))
	createWall("WallWest", Vector3.new(-size/2, wallHeight/2, 0), Vector3.new(2, wallHeight, size))
	
	-- PLATFORMS (Mario Style)
	local function createPlatform(pos, pSize, color)
		local plat = Instance.new("Part")
		plat.Size = pSize
		plat.Position = pos
		plat.Color = color
		plat.Material = Enum.Material.SmoothPlastic
		plat.Anchored = true
		plat.Parent = folder
		
		-- Bevel/Top color
		local top = Instance.new("Part")
		top.Size = Vector3.new(pSize.X, 0.5, pSize.Z)
		top.Position = pos + Vector3.new(0, pSize.Y/2 + 0.25, 0)
		top.Color = color:Lerp(Color3.new(1,1,1), 0.2)
		top.Anchored = true
		top.Parent = folder
	end
	
	-- Random platforms
	local platColors = {
		Color3.fromRGB(200, 50, 50), -- Red
		Color3.fromRGB(50, 200, 50), -- Green
		Color3.fromRGB(50, 50, 200), -- Blue
		Color3.fromRGB(200, 180, 0), -- Yellow
	}
	
	for i = 1, 12 do
		local x = math.random(-size/3, size/3)
		local z = math.random(-size/3, size/3)
		local y = math.random(6, 15)
		local pWidth = math.random(10, 20)
		local pDepth = math.random(10, 20)
		createPlatform(Vector3.new(x, y, z), Vector3.new(pWidth, 2, pDepth), platColors[math.random(1, #platColors)])
	end
	
	-- Add some large central platforms
	createPlatform(Vector3.new(0, 8, 0), Vector3.new(30, 2, 30), Color3.fromRGB(150, 75, 0)) -- Brown center
	
	print("MARIO ARENA BUILT!")
end

return MapService
