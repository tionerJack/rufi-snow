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
AdminService.DisabledPowerUps = {} -- Initialized in Init to disable all by default

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

	-- Initialize: Disable all by default
	for key, _ in pairs(GameConstants.POWERUP_TYPES) do
		AdminService.DisabledPowerUps[key] = true
	end

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
			print(string.format("ADMIN: Power-Up %s is now %s", data, AdminService.DisabledPowerUps[data] and "DISABLED" or "ENABLED"))
			adminStateUpdate:FireAllClients({DisabledPowerUps = AdminService.DisabledPowerUps})
		elseif action == "ResetGame" then
			-- Logic for game reset if needed
		end
	end)

	-- Sync state to new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(1) -- Wait for client UI to be ready
		adminStateUpdate:FireClient(player, {
			KillsToWin = AdminService.KillsToWin,
			CurrentMap = AdminService.CurrentMap,
			DisabledPowerUps = AdminService.DisabledPowerUps
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
