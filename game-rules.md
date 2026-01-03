# Rufi Snow - Game Rules Documentation

## 📋 Overview
**Rufi Snow** is a multiplayer snow combat game where players freeze enemies and other players in an icy arena. The game features a unique freeze-and-roll mechanic, 39 unique power-ups, and intelligent AI enemies.

---

## 🎮 Core Gameplay Mechanics

### 1. **Freeze System**
The primary combat mechanic revolves around freezing characters (both players and enemies).

#### Freeze Hit Mechanics
- **Hits Required to Freeze**: 3 hits
- **Each hit** progressively slows the target and changes their color toward icy blue
- **Visual Feedback**: A progress bar appears above the target showing freeze progress
- **Auto-Unfreeze**: If not hit, characters recover at **2 hits per second**

#### Frozen State
When a character is fully frozen:
- Transformed into a **snowball** (size scales with character size)
- **Cannot move** (WalkSpeed = 0, JumpPower = 0, PlatformStand = true)
- Character model becomes **transparent inside snowball**
- Lasts **10 seconds** unless pushed
- Players and enemies can **push** frozen characters to activate rolling

#### Special Resistances
- **Titans**: Only take 0.25 freeze damage per hit (4x harder to freeze)
- **Giants**: Only take 0.5 freeze damage per hit (2x harder to freeze)
- **Shield/Invincible**: Completely immune to freezing

---

### 2. **Roll Mechanic**
When a frozen character is pushed (touched by another player/enemy):

#### Roll Physics
- **Speed**: 60 studs/second
- **Duration**: 4 seconds
- **Bounces off walls** using reflection physics
- **Pusher Immunity**: The pusher cannot be hit by the rolling ball for 1 second
- **Damage on Hit**: Instant kill (100 damage) to any character touched
- **Visual Effect**: Spinning snowball with ice material and particles

#### After Rolling
- Character automatically **unfreezes** after the 4-second duration
- Returns to normal state

---

### 3. **Combat System**

#### Projectile Shooting
- **Fire Rate**: 0.3 seconds (default)
- **Projectile Speed**: 100 studs/second
- **Range**: 100 studs (increased for large map)
- **Controls**: 
  - **PC**: `F` key or Left Mouse Button
  - **Mobile**: Tap screen or use on-screen button

#### Projectile Types (Modified by Power-Ups)
- **Standard**: Small ice projectile (0.6x0.6x2.5)
- **Mega Balls**: Larger projectiles (1.8x1.8x4.0), 3x freeze hits
- **Explosive**: Creates AOE explosion on hit (15 stud radius)
- **Laser**: Instant hit beam (500 stud range)
- **Shrink Ray**: Green beam that reduces target size by 30%
- **Freeze Beam**: Large beam projectile (1x1x20)

#### Triple Shot
- Fires **3 projectiles** at angles: -15°, 0°, +15°

#### Bouncing Balls
- Projectiles bounce off walls **up to 3 times** before disappearing

---

### 4. **Power-Up System**

#### Spawn Mechanics
- Power-ups spawn on **pyramid peaks** (9 spawn locations)
- **Check Interval**: Every 10 seconds
- **Spawn Cooldown**: 5 seconds after collection
- **Visual**: Crystal container with glowing liquid core (color-coded by type)
- **Duration**: All power-ups last **30 seconds**

#### Active Power-Ups HUD
- Displays current power-up name and remaining time
- Located in top-right corner
- Warns when less than 3 seconds remain (flashing red)

#### Power-Up Categories

##### **Movement Buffs**
1. **Velocidad (SPEED)** - Yellow
   - WalkSpeed: 45 (default is 16)

2. **Gran Salto (JUMP)** - Light Blue
   - JumpPower: 120 (default is 50)

3. **Súper Impulso (DASH)** - Golden
   - WalkSpeed: 80
   - Leaves golden motion blur trails

4. **Vuelo Glacial (FLY)** - Sky Blue
   - Enables flight with BodyVelocity
   - Flies forward at 40 studs/second

5. **Antigravedad (GRAVITY)** - Purple
   - JumpPower: 150
   - Slow fall effect (gently lifts when falling fast)

##### **Size Transformations**
6. **Gigante (GIANT)** - Pink
   - Body scale: **2x** all dimensions
   - JumpPower: 75
   - 50% freeze resistance

7. **Miniatura (MINI)** - Magenta
   - Body scale: **0.4x** all dimensions
   - WalkSpeed: 30
   - Harder to hit

8. **Titán Inmenso (TITAN)** - Indigo
   - Body scale: **4x** all dimensions
   - JumpPower: 100
   - 75% freeze resistance (only 0.25 hits per shot)

##### **Offensive Powers**
9. **Triple Tiro (TRIPLE)** - Green
   - Fires 3 projectiles simultaneously

10. **Mega Bola (MEGA)** - Red
    - Larger, slower projectiles
    - 3x freeze damage per hit

11. **Fuego Rápido (RAPID)** - Orange
    - Fire rate: **0.05 seconds** (6x faster)

12. **Explosivo (EXPLOSIVE)** - Purple/Orange
    - Projectiles explode on hit (15 stud radius)
    - AOE freeze damage
    - 10 extra damage to enemies

13. **Llama Gélida (FIRE)** - Flame Orange
    - Each hit deals 5 damage + freeze
    - Burns target for 3 seconds

14. **Aturdimiento (STUN)** - Brown
    - Target frozen in place (0 WalkSpeed) for 3 seconds

15. **Furia (BERSERK)** - Dark Red
    - WalkSpeed: 50
    - Knockback on hit (pushes targets 5000 force)

16. **Veneno Ártico (VENOM)** - Dark Green
    - Poison effect: 3 damage every second for 5 seconds (15 total)

##### **Defensive Powers**
17. **Escudo (SHIELD)** - Cyan
    - Immune to freeze and damage
    - Visual ForceField

18. **Invencible (GOD)** - White
    - Complete invulnerability
    - ForceField visual

19. **Espinas (THORN)** - Dark Green
    - **Retribution**: Enemies/players that touch you get frozen
    - Works on enemy touch attacks
    - Reflects damage back to attacker

20. **Regeneración (REGEN)** - Lime Green
    - Heals 0.2 freeze hits every 0.2 seconds
    - Slowly removes freeze progress

##### **Tactical Powers**
21. **Rebotador (BOUNCE)** - Yellow-Green
    - Projectiles bounce off walls 3 times

22. **Invisibilidad (INVIS)** - Near-White
    - All body parts become fully transparent
    - Enemies cannot detect you

23. **Fantasmagoría (PHANTOM)** - Gray
    - WalkSpeed: 26
    - 60% transparency
    - Ghost fire effect
    - Enemies ignore you

24. **Teletransporte (TELEPORT)** - Medium Purple
    - **Instant teleport** to random pyramid peak
    - **Bonus**: All frozen characters also teleport to random peaks!
    - Flash visual effects at old and new positions

25. **Cámara Lenta (SLOMO)** - Cornflower Blue
    - Slows hit targets to 4 WalkSpeed for 4 seconds

26. **Rebobinar (TIME)** - Dark Orange
    - Records position on pickup
    - **On expiration**: Teleports back to recorded position!
    - Flash visual effects

##### **Area Control Powers**
27. **Vórtice (VORTEX)** - Navy Blue
    - Projectile hits pull all enemies within 25 studs toward impact
    - 2000 impulse force

28. **Aura Gélida (AURA)** - Pale Turquoise
    - **3-layer visual**: Core vortex, blizzard particles, ground fog
    - Passive AOE freeze (30 stud radius, periodic)

29. **Rastro Gélido (FROSTBIT)** - Bright Cyan
    - Leaves ice trail behind you
    - Trail parts freeze on touch
    - Trails last 5 seconds

30. **Lluvia Gélida (METEOR)** - Steel Blue
    - Every 2 seconds: spawns ice meteor from sky
    - Meteors fall and explode (12 stud radius)
    - 2x freeze hits on impact

31. **Muro de Hielo (WALL)** - Snow White
    - Each projectile hit spawns temporary ice wall (12x10x2)
    - Walls last 5 seconds

32. **Onda de Choque (SHOCK)** - Golden
    - Every 1.8 seconds: Area pulse (30 stud radius)
    - Freezes + knockback (7000 force) + 5 damage to enemies
    - Expanding ring visual

33. **Tormenta de Nieve (BLIZZARD)** - Powder Blue
    - Every 1 second: Area damage (40 stud radius)
    - 2 damage + slow targets to 8 WalkSpeed
    - Smoke cloud visual

34. **Imán Galáctico (PULL)** - Red-Orange
    - Constantly pulls nearby enemies (30 stud radius)
    - 1000 impulse force toward player

##### **Advanced Powers**
35. **Espejismo (MIRAGE)** - Yellow
    - Spawns **3 decoy clones**
    - Decoys attract enemy AI (tagged as "Decoy")
    - Holographic pulsing effect
    - Enemies target decoys instead of player

36. **Clon Maestro (CLONE)** - Hot Pink
    - Spawns **4 orbiting ice clones**
    - Clones orbit player at 12 stud radius
    - **Clones freeze on touch!**
    - Rotate at 3 radians/second

37. **Láser Ártico (LASER)** - Deep Pink
    - Instant raycast beam (500 studs)
    - 0.2x0.2 beam visual
    - Lasts 0.1 seconds

38. **Rayo Reductor (SHRINK)** - Slate Blue
    - Shrinks target to **70% size**
    - Green highlight flash
    - Works on both R15 humanoids and custom models

39. **Rayo Gélido (BEAM)** - Deep Sky Blue
    - Large beam projectile (1x1x20)

---

## 🤖 Enemy AI System

### Enemy Types: "Cute Imps"
Enemies spawn as devilish imp characters in 5 size variants:

#### Variants (by scale)
1. **Tiny**: 0.6x scale
2. **Small**: 0.8x scale
3. **Medium**: 1.0x scale
4. **Large**: 1.3x scale (has tail)
5. **Huge**: 1.6x scale (has tail)

#### Visual Features
- **Body**: Red/crimson colored plastic
- **Head**: Round with black neon eyes (white reflections)
- **Horns**: Two devil horns (angle varies by variant)
- **Tail**: Variants 4-5 have pointed tails
- **Legs**: Two thick legs

### AI Behavior

#### Aggression System
- **Base Detection Range**: 80 studs
- **Desperate Mode**: Detection range increases by 40 studs per freeze hit
  - 1 hit: 120 studs
  - 2 hits: 160 studs
  - 3 hits: 200 studs (very aggressive!)

#### Movement
- **Base Speed**: 16 + (variant × 2)
- **Speed Degradation**: Slows down as they accumulate freeze hits
  - Speed = BaseSpeed × (1 - freezeHits/3)
  - Example: 2/3 frozen = 33% speed

#### Pathfinding
- Uses Roblox PathfindingService
- Can jump over obstacles
- Falls back to direct movement if pathfinding fails
- **Wander Mode**: Randomly wanders arena when no target detected

#### Target Priority
1. **Players** (unless invisible/phantom)
2. **Decoys** (from Mirage/Clone powers)
3. **Random wander** if no targets

#### Combat Abilities
- **Touch = Instant Kill** (when not frozen)
  - **Exception**: Protected players (Shield, Invincible, Giant, Titan, Thorns)
- **Thorn Retaliation**: If touching protected player with Thorns, enemy gets frozen instead
- **Push Frozen Enemies**: Can push frozen enemies into rolling snowballs

### Spawn System
- **Initial Spawn**: 10 enemies when game starts
- **Respawn**: When killed, spawns a new enemy after 3 seconds
- **Drop Reward**: Killing an enemy spawns a power-up immediately (bypasses timer)
- **Spawn Area**: Random positions within arena (-50 to 50 studs, Y=20)

---

## 🏰 Map Design

### Arena Structure
- **Size**: 250×250 studs
- **Style**: Snow castle theme with pyramids

### Components

#### 1. **Floor**
- **Material**: Snow
- **Size**: 310×2×310 (includes outer area)
- **Color**: Pure white

#### 2. **Castle Walls** (4 sides)
- **Material**: Ice
- **Height**: 20 studs
- **Thickness**: 4 studs
- **Color**: Light blue (200, 240, 255)
- **Crenellations**: Medieval-style merlons on top

#### 3. **Pyramids** (13 total)
- **Structure**: 7-layer stepped pyramids
- **Material**: Ice with snow caps
- **Base Size**: 30 studs (shrinks by 12% per layer)
- **Layer Height**: 3.5 studs each
- **Total Height**: ~24.5 studs

**Locations**:
- **4 Corner Pyramids**: Cannot spawn power-ups
- **1 Central Master Pyramid**: Power-up spawn point
- **8 Intermediate Pyramids**: Power-up spawn points
  - At 75 studs from center in 8 directions

#### 4. **Bridges**
- **Material**: Ice with snow caps
- **Size**: 6×1.2 wide
- Connect central pyramid to 8 intermediate pyramids
- **Height**: 14 studs above ground

#### 5. **Decorations** (50 scattered)
- **Ice Spikes**: Random height (6-15 studs), tilted
- **Snow Mounds**: Ball-shaped, half-buried
- **Ice Pillars**: 10-20 studs tall with neon blue bands

#### 6. **Invisible Containment**
- **Purpose**: Prevents players/projectiles from escaping
- **Height**: 150 studs
- **Walls**: 10 stud thick invisible barriers on all sides
- **Ceiling**: Invisible roof at 150 studs

### Lighting
- **Ambient**: Cool blue tones (150, 180, 200)
- **OutdoorAmbient**: Darker blue (100, 120, 150)
- **Brightness**: 2

---

## 🎯 Game Constants

### Combat
- `FREEZE_HITS_REQUIRED`: 3
- `FREEZE_DURATION`: 10 seconds
- `UNFREEZE_TICK_RATE`: 2 hits/second recovery
- `FIRE_RATE`: 0.3 seconds
- `PROJECTILE_SPEED`: 100 studs/second
- `PROJECTILE_RANGE`: 100 studs
- `BALL_DAMAGE`: 100 (instant kill)

### Rolling
- `ROLL_SPEED`: 60 studs/second
- `ROLL_DURATION`: 4 seconds
- `PUSHER_IMMUNITY_DURATION`: 1 second

### Power-Ups
- `POWERUP_DURATION`: 30 seconds
- `POWERUP_SPAWN_CHECK_INTERVAL`: 10 seconds

### Map
- `ARENA_SIZE`: 250 studs

---

## 🎨 Visual Effects

### Freeze Effects
- **Progress**: Body parts lerp from original color to icy blue (150, 200, 255)
- **Frozen Snowball**: Large sphere with ice material, sparkle particles
- **Progress Bar**: Cyan bar above head showing freeze/melt progress

### Power-Up Visuals
- **Crystal Core**: Glowing neon liquid ball inside glass container
- **Floating Animation**: Bobs up and down 2 studs
- **Pulsing Light**: PointLight with varying brightness
- **Colored Aura**: Particle effects matching power type
- **HUD Display**: Top-right corner with border matching power color

### Combat Effects
- **Projectiles**: Neon colored, shape varies by type
- **Explosions**: Visual Explosion instance with particle effects
- **Ice Walls**: Temporary 12×10×2 ice barriers
- **Lasers**: Instant beam with 0.1s duration
- **Meteor Rain**: Falling ice spheres with explosions

### Animations
- **Fire Animation**: Arm throws forward 90° (0.2s total)
- **Push Animation**: Both arms push forward (0.3s total)
- **Scale-Aware**: Animations adjust to character size changes

---

## 🏆 Special Mechanics

### Power Interaction
- **Shield/Invincible** blocks: Freeze, damage, enemy touch
- **Thorns** reflects: Freeze hits back to attacker
- **Giants/Titans** resist: Partial freeze damage
- **Invisibility/Phantom**: Enemies cannot detect player

### Enemy Interactions
- Enemies **cannot** damage each other
- Enemies **can** push frozen enemies
- Enemies **target** decoys created by Mirage/Clone
- Enemies **avoid** invisible/phantom players

### Projectile Collisions
- Projectiles **ignore** the firing player
- Projectiles **can** hit other players
- Projectiles **can** hit enemies
- Bouncing projectiles **reflect** off walls up to 3 times

---

## 📱 Platform Support

### PC Controls
- **Fire**: `F` key or Left Mouse Button
- **Move**: WASD or Arrow Keys
- **Jump**: Spacebar
- **Camera**: Mouse

### Mobile Controls
- **Fire**: Tap anywhere on screen OR dedicated fire button (center-left)
- **Move**: Virtual joystick (auto-generated by Roblox)
- **Jump**: Jump button (auto-generated)
- **Camera**: Touch drag

### Touch Optimizations
- Large fire button (90×90 pixels)
- Tap-to-target system (fires toward tap location)
- Visual feedback on button press

---

## 🔄 Game Loop

1. **Match Start**: 
   - Arena builds
   - 10 enemies spawn
   - Power-up system activates

2. **Continuous**:
   - Enemies pathfind and hunt players
   - Power-ups spawn on peaks every 10 seconds (if none active)
   - Players shoot to freeze targets
   - Frozen characters get pushed and roll
   - Enemies respawn after death

3. **No End Condition**: 
   - Endless survival gameplay
   - Players respawn on death
   - Enemies continuously respawn

---

## 💡 Strategy Tips

### For Players
1. **Freeze enemies before they touch you** (instant death)
2. **Use Giant/Titan for survivability** (freeze resistance)
3. **Combine powers**: Triple + Rapid + Mega = devastating
4. **Tactical retreat**: Use Teleport/Invisibility when overwhelmed
5. **Zone control**: Blizzard + Meteor + Ice Aura for area denial
6. **Decoys work!**: Mirage/Clone distracts enemies effectively

### Power-Up Combos
- **Assault Build**: Rapid + Triple + Mega = high DPS
- **Tank Build**: Giant/Titan + Shield/Invincible = survival
- **Hit & Run**: Speed + Dash + Invisibility = escape artist
- **Area Denial**: Blizzard + Meteor + Frost Trail = zone control
- **Support**: Slow-Mo + Stun + Vortex = crowd control

---

## 🐛 Known Behaviors

### Intentional Design
- Pusher has 1-second immunity to their own rolling snowball
- Enemies get more aggressive as they get frozen (increases detection range)
- Killing enemies immediately spawns power-ups (reward mechanic)
- Frozen characters can be pushed by anyone (including enemies)
- Time Recall power teleports you back on expiration (not on command)
- Teleport power also teleports ALL frozen characters (chaos mechanic!)

---

**Game Version**: Based on source code analysis (January 2026)
**Platform**: Roblox
**Genre**: Multiplayer Arena Combat with Freeze Mechanics
