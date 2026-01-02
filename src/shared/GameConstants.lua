local GameConstants = {
	FREEZE_HITS_REQUIRED = 3,
	FREEZE_DURATION = 10,
	UNFREEZE_TICK_RATE = 2, -- Hits recovered per second when not hit
	ROLL_SPEED = 60,
	ROLL_DURATION = 4,
	FIRE_RATE = 0.3,
	PROJECTILE_SPEED = 100,
	PROJECTILE_RANGE = 100, -- Increased for bigger map
	ARENA_SIZE = 250,
	BALL_DAMAGE = 100, -- Instakill basic enemies
	PUSHER_IMMUNITY_DURATION = 1.0,
	
	-- Power-Up Constants
	POWERUP_DURATION = 15,
	POWERUP_SPAWN_CHECK_INTERVAL = 10,
	
	POWERUP_TYPES = {
		GIANT = {Name = "Giant", Color = Color3.fromRGB(255, 100, 200)},     -- Pink
		SPEED = {Name = "Speed", Color = Color3.fromRGB(255, 230, 0)},       -- Yellow
		TRIPLE = {Name = "Triple", Color = Color3.fromRGB(0, 255, 100)},      -- Green
		MEGA = {Name = "MegaBall", Color = Color3.fromRGB(255, 0, 0)},       -- Red
		RAPID = {Name = "RapidFire", Color = Color3.fromRGB(255, 120, 0)},   -- Orange
		JUMP = {Name = "JumpBoost", Color = Color3.fromRGB(0, 150, 255)},    -- Blue
		SHIELD = {Name = "Shield", Color = Color3.fromRGB(0, 255, 255)},     -- Cyan
		EXPLOSIVE = {Name = "Explosive", Color = Color3.fromRGB(200, 0, 255)},-- Purple
		PHANTOM = {Name = "Phantom", Color = Color3.fromRGB(200, 200, 200)}, -- White
	}
}

return GameConstants
