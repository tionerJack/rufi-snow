local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(Shared:WaitForChild("GameConstants"))

local AdminService = {}

-- State Variables
AdminService.KillsToWin = GameConstants.DEFAULT_KILLS_TO_WIN
AdminService.CurrentMap = "DEFAULT"
AdminService.DisabledPowerUps = {} 
AdminService.ActiveRotation = {} -- Current 4 active powers
AdminService.NextRotationTime = 0
AdminService.AutoRotation = true

function AdminService.Init()
	-- Create RemoteEvents
	local function createRemote(name, className)
		local remote = ReplicatedStorage:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className or "RemoteEvent")
			remote.Name = name
			remote.Parent = ReplicatedStorage
		end
		return remote
	end

	local adminAction = createRemote("AdminAction")
	local adminStateUpdate = createRemote("AdminStateUpdate")
	local getAdminState = createRemote("GetAdminState", "RemoteFunction")

	-- Initialize: Disable all by default
	for key, _ in pairs(GameConstants.POWERUP_TYPES) do
		AdminService.DisabledPowerUps[key] = true
	end

	local updateRotation -- Forward declaration for closure scope

	adminAction.OnServerEvent:Connect(function(player, action, data)
		if not AdminService.IsAdmin(player) then return end

		print(string.format("ADMIN: %s performed action: %s", player.Name, action))

		if action == "UpdateKills" then
			AdminService.KillsToWin = tonumber(data) or GameConstants.DEFAULT_KILLS_TO_WIN
			adminStateUpdate:FireAllClients({KillsToWin = AdminService.KillsToWin})
		elseif action == "ChangeMap" then
			AdminService.CurrentMap = data
			local MapService = require(script.Parent.MapService)
			MapService.BuildArena(AdminService.CurrentMap)
			adminStateUpdate:FireAllClients({CurrentMap = AdminService.CurrentMap})
		elseif action == "TogglePowerUp" then
			AdminService.DisabledPowerUps[data] = not AdminService.DisabledPowerUps[data]
			
			-- If in manual mode, update ActiveRotation so HUD reflects it
			if not AdminService.AutoRotation then
				AdminService.ActiveRotation[data] = not AdminService.DisabledPowerUps[data] or nil
			end
			
			adminStateUpdate:FireAllClients({
				DisabledPowerUps = AdminService.DisabledPowerUps,
				ActiveRotation = AdminService.ActiveRotation
			})
		elseif action == "ToggleAutoRotation" then
			AdminService.AutoRotation = not AdminService.AutoRotation
			print("ADMIN: AutoRotation is now " .. (AdminService.AutoRotation and "ON" or "OFF"))
			
			if AdminService.AutoRotation then
				updateRotation()
			else
				adminStateUpdate:FireAllClients({
					AutoRotation = AdminService.AutoRotation,
					NextRotationTime = 0,
					DisabledPowerUps = AdminService.DisabledPowerUps,
					ActiveRotation = AdminService.ActiveRotation
				})
			end
		elseif action == "ForceSpawn" then
			local PowerUpService = require(script.Parent.PowerUpService)
			PowerUpService.SpawnPotion(true)
		end
	end)

	getAdminState.OnServerInvoke = function(player)
		return {
			KillsToWin = AdminService.KillsToWin,
			CurrentMap = AdminService.CurrentMap,
			DisabledPowerUps = AdminService.DisabledPowerUps,
			NextRotationTime = AdminService.NextRotationTime,
			ActiveRotation = AdminService.ActiveRotation,
			AutoRotation = AdminService.AutoRotation
		}
	end

	-- 15-MINUTE SEEDED ROTATION SYSTEM
	updateRotation = function()
		if not AdminService.AutoRotation then return end -- SKIP IF MANUAL
		
		local timestamp = os.time()
		local interval = GameConstants.ROTATION_INTERVAL
		local segment = math.floor(timestamp / interval)
		AdminService.NextRotationTime = (segment + 1) * interval
		
		-- Use date + segment as seed for consistency across server restarts
		local dateStr = os.date("!%Y%m%d", timestamp)
		local seed = tonumber(dateStr) + segment
		local rng = Random.new(seed)
		
		local newRotation = {}
		local newDisabled = {}
		
		-- Disable all first
		for key, _ in pairs(GameConstants.POWERUP_TYPES) do
			newDisabled[key] = true
		end
		
		-- Select 1 from each category
		for _, catData in pairs(GameConstants.POWERUP_CATEGORIES) do
			local abs = catData.Abilities
			if #abs > 0 then
				local picked = abs[rng:NextInteger(1, #abs)]
				newRotation[picked] = true
				newDisabled[picked] = false
			end
		end
		
		AdminService.ActiveRotation = newRotation
		AdminService.DisabledPowerUps = newDisabled
		
		print("ROTATION: New abilities selected for segment " .. segment)
		adminStateUpdate:FireAllClients({
			DisabledPowerUps = AdminService.DisabledPowerUps,
			NextRotationTime = AdminService.NextRotationTime,
			ActiveRotation = AdminService.ActiveRotation,
			AutoRotation = AdminService.AutoRotation
		})
	end

	-- Initial update
	updateRotation()

	-- Check for rotation change every 10 seconds
	task.spawn(function()
		while true do
			if os.time() >= AdminService.NextRotationTime then
				updateRotation()
			end
			task.wait(10)
		end
	end)

	-- Sync state to new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(1) 
		adminStateUpdate:FireClient(player, {
			KillsToWin = AdminService.KillsToWin,
			CurrentMap = AdminService.CurrentMap,
			DisabledPowerUps = AdminService.DisabledPowerUps,
			NextRotationTime = AdminService.NextRotationTime,
			ActiveRotation = AdminService.ActiveRotation,
			AutoRotation = AdminService.AutoRotation
		})
	end)
end

function AdminService.IsAdmin(player)
	-- Whitelist Check
	for _, id in ipairs(GameConstants.ADMIN_WHITELIST) do
		if player.UserId == id then return true end
	end

	-- VIP Check
	if GameConstants.VIP_GAMEPASS_ID > 0 then
		local s, hasVip = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConstants.VIP_GAMEPASS_ID)
		end)
		if s and hasVip then return true end
	end

	-- Developer/Studio Bypass
	if RunService:IsStudio() or player.UserId <= 0 or game.CreatorId == player.UserId then
		return true
	end

	return false
end

function AdminService.GetKillsToWin()
	return AdminService.KillsToWin
end

function AdminService.IsPowerUpEnabled(powerKey)
	local isDisabled = AdminService.DisabledPowerUps[powerKey] == true
	return not isDisabled
end

return AdminService
