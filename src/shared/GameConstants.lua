local GameConstants = {
	FREEZE_HITS_REQUIRED = 3,
	FREEZE_DURATION = 10,
	UNFREEZE_TICK_RATE = 2, -- Hits recovered per second when not hit
	ROLL_SPEED = 60,
	ROLL_DURATION = 4,
	FIRE_RATE = 0.3,
	PROJECTILE_SPEED = 100,
	PROJECTILE_RANGE = 30, -- Even shorter for true close combat
	ARENA_SIZE = 250,
	BALL_DAMAGE = 100, -- Instakill when hit by a rolling snowball
	PUSHER_IMMUNITY_DURATION = 1.0,
	
	-- Power-Up Constants
	POWERUP_DURATION = 30,
	POWERUP_SPAWN_CHECK_INTERVAL = 10,
	
	POWERUP_TYPES = {
		-- ATTACK (Estrategia Ofensiva)
		TRIPLE = {Name = "Tiro Triple", Color = Color3.fromRGB(255, 100, 100), Emoji = "🔱"},
		MEGA = {Name = "Mega Bola", Color = Color3.fromRGB(240, 248, 255), Emoji = "☄️"},
		RAPID = {Name = "Fuego Rápido", Color = Color3.fromRGB(255, 150, 50), Emoji = "🔫"},
		EXPLOSIVE = {Name = "Explosivo", Color = Color3.fromRGB(255, 50, 0), Emoji = "💥"},
		FIRE = {Name = "Furia Ártica", Color = Color3.fromRGB(255, 80, 0), Emoji = "👹"},
		BEAM = {Name = "Rayo Gélido", Color = Color3.fromRGB(0, 191, 255), Emoji = "🛰️"},
		LASER = {Name = "Láser", Color = Color3.fromRGB(255, 0, 255), Emoji = "⚡"},
		VENOM = {Name = "Veneno", Color = Color3.fromRGB(50, 255, 50), Emoji = "🧪"},
		SNIPER = {Name = "Súper Alcance", Color = Color3.fromRGB(100, 149, 237), Emoji = "🎯"},
		BERSERK = {Name = "Berserk", Color = Color3.fromRGB(200, 0, 0), Emoji = "💢"},
		
		-- DEFENSE (Protección y Aguante)
		SHIELD = {Name = "Escudo", Color = Color3.fromRGB(100, 200, 255), Emoji = "🛡️"},
		GOD = {Name = "Invencible", Color = Color3.fromRGB(255, 215, 0), Emoji = "✨"},
		REGEN = {Name = "Regeneración", Color = Color3.fromRGB(50, 255, 150), Emoji = "💖"},
		WALL = {Name = "Muro Hielo", Color = Color3.fromRGB(200, 255, 255), Emoji = "🏔️"},
		INVIS = {Name = "Invisibilidad", Color = Color3.fromRGB(200, 200, 200), Emoji = "🌫️"},
		THORN = {Name = "Espinas", Color = Color3.fromRGB(0, 255, 100), Emoji = "🥀"},
		AURA = {Name = "Aura Gélida", Color = Color3.fromRGB(0, 255, 255), Emoji = "💠"},
		PHANTOM = {Name = "Fantasma", Color = Color3.fromRGB(150, 150, 255), Emoji = "👻"},
		
		-- MOVEMENT (Agilidad y Posición)
		SPEED = {Name = "Súper Velocidad", Color = Color3.fromRGB(255, 255, 0), Emoji = "👟"},
		JUMP = {Name = "Súper Salto", Color = Color3.fromRGB(0, 255, 0), Emoji = "🚀"},
		GRAVITY = {Name = "Sin Gravedad", Color = Color3.fromRGB(200, 100, 255), Emoji = "🪐"},
		DASH = {Name = "Impulso", Color = Color3.fromRGB(255, 230, 0), Emoji = "💨"},
		FLY = {Name = "Vuelo", Color = Color3.fromRGB(100, 200, 250), Emoji = "👐"},
		TELEPORT = {Name = "Teletransporte", Color = Color3.fromRGB(180, 0, 255), Emoji = "🌌"},
		SLOMO = {Name = "Cámara Lenta", Color = Color3.fromRGB(150, 200, 255), Emoji = "⏱️"},
		FROSTBIT = {Name = "Rastro Gélido", Color = Color3.fromRGB(0, 200, 255), Emoji = "👣"},
		
		-- CHAOS (Efectos Especiales)
		GIANT = {Name = "Gigante", Color = Color3.fromRGB(50, 100, 255), Emoji = "🐘"},
		MINI = {Name = "Miniatura", Color = Color3.fromRGB(255, 100, 255), Emoji = "🐭"},
		VORTEX = {Name = "Vórtice", Color = Color3.fromRGB(100, 0, 255), Emoji = "🌪️"},
		MIRAGE = {Name = "Espejismo", Color = Color3.fromRGB(255, 255, 255), Emoji = "🎭"},
		METEOR = {Name = "Lluvia Meteoros", Color = Color3.fromRGB(255, 69, 0), Emoji = "🌠"},
		SHOCK = {Name = "Onda Gélida", Color = Color3.fromRGB(0, 255, 255), Emoji = "🌊"},
		CLONE = {Name = "Clon Maestro", Color = Color3.fromRGB(200, 200, 200), Emoji = "👯"},
		TITAN = {Name = "Titán", Color = Color3.fromRGB(0, 0, 150), Emoji = "🌋"},
		PULL = {Name = "Atracción", Color = Color3.fromRGB(255, 50, 255), Emoji = "🧲"},
		BLIZZARD = {Name = "Ventisca", Color = Color3.fromRGB(200, 240, 255), Emoji = "🌨️"},
		BOUNCE = {Name = "Rebotador", Color = Color3.fromRGB(240, 230, 140), Emoji = "🏀"},
		SHRINK = {Name = "Rayo Encogedor", Color = Color3.fromRGB(0, 255, 0), Emoji = "🤏"},
	},

	ROTATION_INTERVAL = 900, -- 15 minutes in seconds
	
	POWERUP_CATEGORIES = {
		ATTACK = {
			Name = "ATAQUE",
			Emoji = "⚔️",
			Color = Color3.fromRGB(255, 50, 50),
			Abilities = {"TRIPLE", "MEGA", "RAPID", "EXPLOSIVE", "FIRE", "BEAM", "LASER", "VENOM", "SNIPER", "BERSERK"}
		},
		DEFENSE = {
			Name = "DEFENSA",
			Emoji = "🛡️",
			Color = Color3.fromRGB(50, 150, 255),
			Abilities = {"SHIELD", "GOD", "REGEN", "WALL", "INVIS", "THORN", "AURA", "PHANTOM"}
		},
		MOVEMENT = {
			Name = "MOVIMIENTO",
			Emoji = "👟",
			Color = Color3.fromRGB(255, 230, 0),
			Abilities = {"SPEED", "JUMP", "GRAVITY", "DASH", "FLY", "TELEPORT", "SLOMO", "FROSTBIT"}
		},
		CHAOS = {
			Name = "CAOS",
			Emoji = "🌀",
			Color = Color3.fromRGB(200, 50, 255),
			Abilities = {"GIANT", "MINI", "VORTEX", "MIRAGE", "METEOR", "SHOCK", "CLONE", "TITAN", "PULL", "BLIZZARD", "BOUNCE", "SHRINK"}
		}
	},
	
	-- VIP & Admin Settings
	VIP_GAMEPASS_ID = 0, -- Replace with actual GamePass ID
	ADMIN_WHITELIST = {0, 1, 106362334}, -- Add User IDs here (0 and 1 for local Studio tests)
	DEFAULT_KILLS_TO_WIN = 10,
	
	MAP_OPTIONS = {
		{Name = "Castillo Ártico", ID = "DEFAULT"},
		{Name = "Valle de Cristal", ID = "CRYSTAL"},
		{Name = "Arena de Fuego", ID = "FIRE_ARENA"},
		{Name = "Espacio Exterior", ID = "SPACE"}
	}
}

return GameConstants
