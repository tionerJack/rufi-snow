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
	POWERUP_DURATION = 30,
	POWERUP_SPAWN_CHECK_INTERVAL = 10,
	
	POWERUP_TYPES = {
		GIANT = {Name = "Gigante", Color = Color3.fromRGB(255, 100, 200)},     
		SPEED = {Name = "Velocidad", Color = Color3.fromRGB(255, 230, 0)},       
		TRIPLE = {Name = "Triple Tiro", Color = Color3.fromRGB(0, 255, 100)},      
		MEGA = {Name = "Mega Bola", Color = Color3.fromRGB(255, 0, 0)},       
		RAPID = {Name = "Fuego Rápido", Color = Color3.fromRGB(255, 120, 0)},   
		JUMP = {Name = "Gran Salto", Color = Color3.fromRGB(0, 150, 255)},    
		SHIELD = {Name = "Escudo", Color = Color3.fromRGB(0, 255, 255)},     
		EXPLOSIVE = {Name = "Explosivo", Color = Color3.fromRGB(200, 0, 255)},
		PHANTOM = {Name = "Fantasmagoría", Color = Color3.fromRGB(200, 200, 200)}, 
		
		-- 10 NEW TYPES
		MINI = {Name = "Miniatura", Color = Color3.fromRGB(255, 0, 255)},
		FIRE = {Name = "Llama Gélida", Color = Color3.fromRGB(255, 69, 0)},
		BOUNCE = {Name = "Rebotador", Color = Color3.fromRGB(173, 255, 47)},
		GRAVITY = {Name = "Antigravedad", Color = Color3.fromRGB(138, 43, 226)},
		FROSTBIT = {Name = "Rastro Gélido", Color = Color3.fromRGB(100, 255, 255)},
		VORTEX = {Name = "Vórtice", Color = Color3.fromRGB(0, 0, 128)},
		MIRAGE = {Name = "Espejismo", Color = Color3.fromRGB(255, 255, 0)},
		GOD = {Name = "Invencible", Color = Color3.fromRGB(255, 255, 255)},
		BERSERK = {Name = "Furia", Color = Color3.fromRGB(139, 0, 0)},
		STUN = {Name = "Aturdimiento", Color = Color3.fromRGB(210, 105, 30)},
		
		-- 20 NEW TYPES (Total 39)
		TELEPORT = {Name = "Teletransporte", Color = Color3.fromRGB(123, 104, 238)},
		AURA = {Name = "Aura Gélida", Color = Color3.fromRGB(175, 238, 238)},
		SLOMO = {Name = "Cámara Lenta", Color = Color3.fromRGB(100, 149, 237)},
		REGEN = {Name = "Regeneración", Color = Color3.fromRGB(50, 205, 50)},
		METEOR = {Name = "Lluvia Gélida", Color = Color3.fromRGB(70, 130, 180)},
		WALL = {Name = "Muro de Hielo", Color = Color3.fromRGB(240, 248, 255)},
		INVIS = {Name = "Invisibilidad", Color = Color3.fromRGB(245, 245, 245)},
		SHOCK = {Name = "Onda de Choque", Color = Color3.fromRGB(218, 165, 32)},
		BEAM = {Name = "Rayo Gélido", Color = Color3.fromRGB(0, 191, 255)},
		DASH = {Name = "Súper Impulso", Color = Color3.fromRGB(255, 215, 0)},
		CLONE = {Name = "Clon Maestro", Color = Color3.fromRGB(255, 105, 180)},
		VENOM = {Name = "Veneno Ártico", Color = Color3.fromRGB(34, 139, 34)},
		THORN = {Name = "Espinas", Color = Color3.fromRGB(0, 100, 0)},
		TITAN = {Name = "Titán Inmenso", Color = Color3.fromRGB(75, 0, 130)},
		PULL = {Name = "Imán Galáctico", Color = Color3.fromRGB(255, 69, 0)},
		BLIZZARD = {Name = "Tormeta de Nieve", Color = Color3.fromRGB(176, 224, 230)},
		LASER = {Name = "Láser Ártico", Color = Color3.fromRGB(255, 20, 147)},
		SHRINK = {Name = "Rayo Reductor", Color = Color3.fromRGB(106, 90, 205)},
		FLY = {Name = "Vuelo Glacial", Color = Color3.fromRGB(135, 206, 250)},
		TIME = {Name = "Rebobinar", Color = Color3.fromRGB(255, 140, 0)},
	},

	POWERUP_CATEGORIES = {
		ATTACK = {
			Name = "PODER DE ATAQUE",
			Emoji = "⚡",
			Color = Color3.fromRGB(255, 50, 50),
			Abilities = {"TRIPLE", "MEGA", "RAPID", "EXPLOSIVE", "FIRE", "BOUNCE", "BERSERK", "STUN", "BEAM", "LASER", "SHRINK", "VENOM"}
		},
		DEFENSE = {
			Name = "PODER DEFENSIVO",
			Emoji = "🛡",
			Color = Color3.fromRGB(50, 150, 255),
			Abilities = {"SHIELD", "GOD", "REGEN", "WALL", "INVIS", "THORN", "AURA", "PHANTOM"}
		},
		SPECIAL = {
			Name = "PODER ESPECIAL",
			Emoji = "🌀",
			Color = Color3.fromRGB(200, 50, 255),
			Abilities = {"GIANT", "SPEED", "JUMP", "MINI", "GRAVITY", "FROSTBIT", "VORTEX", "MIRAGE", "TELEPORT", "SLOMO", "METEOR", "SHOCK", "DASH", "CLONE", "TITAN", "PULL", "BLIZZARD", "FLY", "TIME"}
		}
	}
}

return GameConstants
