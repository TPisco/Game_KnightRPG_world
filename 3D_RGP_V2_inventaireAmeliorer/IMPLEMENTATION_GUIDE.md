# KnightRPG: Fractured Worlds — Implementation Guide

Godot 4.x · GDScript · Production architecture for all seven core systems.

---

## Project Structure

```
systems/
  WorldGenerator.gd      class_name WorldGenerator — chunk streaming
  WorldChunk.gd          class_name WorldChunk — terrain, loot, enemies
  KnightController.gd    (scripts/) — player movement, combat, stamina
  SkillSystem.gd         class_name SkillSystem — per-player skill node
  SkillSystemGlobal.gd   autoload — skill database bridge
  InventoryManager.gd    class_name InventoryManager — per-player grid
  ProgressionTracker.gd  autoload + class_name — XP, save/load
  StoryManager.gd        autoload + class_name — narrative beats
  BossController.gd      class_name BossController — multi-phase bosses
  BossRegistry.gd        class_name BossRegistry — boss/lore lookup
  LootTable.gd           class_name LootTable — procedural loot
  CombatFeedback.gd      class_name CombatFeedback — damage numbers

scenes/
  ui/         MainMenu, StoryIntro, DialogueUI, RunStoryHUD, BossUI, SkillSelectionUI
  world/      FracturedRun.tscn, WorldChunk.tscn
  bosses/     FracturedGuardian, RiftHerald, VoidWarden
  objects/    player.tscn (KnightController), knight.tscn, chunk_enemy.tscn
```

### Autoloads (`project.godot`)

| Autoload | Script | Role |
|----------|--------|------|
| `Global` | `scripts/global.gd` | Player ref, run flags |
| `ProgressionTracker` | `systems/ProgressionTracker.gd` | Persistent progression |
| `StoryManager` | `systems/StoryManager.gd` | Dialogue & story beats |
| `SkillSystemGlobal` | `systems/SkillSystemGlobal.gd` | Skill database bridge |

### Scene Flow

```
MainMenu → StoryIntro (first run, StoryManager intro) → FracturedRun
         → Continue → FracturedRun (same seed)
         → Original Hub World → world.tscn
```

**FracturedRun child order (critical):**
`SkillSelectionUI` → `RunStoryHUD` → `BossUI` → `WorldGenerator`

---

## 1. Infinite World Generation

### Requirements
- Procedural 3D terrain per run (seeded)
- Chunk streaming with load/unload hysteresis
- Escalating danger via `difficulty_multiplier`
- Enemies, loot, bosses scale with depth

### Architecture
- `WorldGenerator` on `FracturedRun/WorldGenerator`
- `WorldChunk.setup(coord, seed, depth, difficulty_multiplier)`
- Signals: `chunk_spawned`, `chunk_unloaded`

### Key constants
```gdscript
const CHUNK_SIZE := 32
const LOAD_RANGE := 3      # chunks to load around player
const UNLOAD_RANGE := 5    # chunks beyond this are freed
difficulty_multiplier = 1.0 + depth * 0.12
```

### Terrain
- `FastNoiseLite` height: `noise.get_noise_2d(world_x, world_z) * 3.0`
- Trimesh collision aligned to visual mesh + edge overlap
- Perimeter `WorldBarrier` walls + safety floor

### Testing
- [ ] Start Run → 7×7 chunk area loads (LOAD_RANGE=3)
- [ ] Walking away unloads distant chunks (UNLOAD_RANGE=5)
- [ ] Continue uses same `run_seed`
- [ ] Depth and difficulty increase from origin
- [ ] Starter loot at chunk (0,0)

---

## 2. Lone Knight Protagonist

### Requirements
- WASD, LMB attack, Q/RMB skill, I inventory, Space jump
- Health, stamina, STR/MAG/DEF from `ProgressionTracker`
- Damage numbers + screen shake

### Scene: `scenes/objects/player.tscn`
```
CharacterBody3D  → scripts/KnightController.gd (via player.gd alias)
├── SkillSystem
├── InventoryUI (InventoryManager)
├── HUD: HpBar, StaminaBar, LevelLabel
├── AttackZone (Area3D)
└── deathScreen
```

### Key APIs (`KnightController.gd`)
```gdscript
func refresh_stats() -> void          # merge ProgressionTracker + equipment
func spend_stamina(cost: float) -> bool
func take_damage(amount: int) -> void # defense + guard + VFX
func deal_Damage() -> void            # melee hit from animation keyframe
```

### Stamina
- Regenerates at 10/sec up to `max_stamina`
- Skills cost 15–30 stamina (see `SkillSystem.SKILL_STAMINA_COSTS`)

### Testing
- [ ] Movement, jump, mouse look
- [ ] Stamina bar drains on skills, refills over time
- [ ] Floating damage numbers on hit
- [ ] Screen shake on damage dealt/taken
- [ ] Death screen + respawn

---

## 3. Powers & Skills System

### Requirements
- Unlock by level + build path
- Stamina + cooldown gated activation
- Build paths: strength / magic / defense / hybrid

### Architecture (hybrid)
| Layer | Location |
|-------|----------|
| Database | `SkillSystem.SKILL_DATABASE` + `SkillSystemGlobal` autoload |
| Unlocks | `ProgressionTracker.SKILL_DEFS` |
| Activation | `SkillSystem` child on player |
| UI | `SkillSelectionUI` (K key) |

### Skills
| ID | Name | Stamina | Unlock |
|----|------|---------|--------|
| power_slash | Power Slash | 15 | Lv1, strength |
| arcane_bolt | Arcane Bolt | 20 | Lv3, magic |
| iron_wall | Iron Wall | 25 | Lv3, defense |
| life_drain | Life Drain | 30 | Lv5, hybrid, STR≥2 MAG≥2 |

### Testing
- [ ] K opens build/skill/stats menu
- [ ] Skills fail without enough stamina
- [ ] Cooldowns prevent spam
- [ ] Arcane Bolt spawns projectile

---

## 4. Epic Boss Battles

### Requirements
- Unique bosses at depths 5, 12, 20
- Multi-phase AI, boss health UI
- Story beat on defeat

### Scenes
- `FracturedGuardian.tscn` → `BossController.gd`
- `RiftHerald.tscn` → minion summons
- `VoidWarden.tscn` → void pulse

### UI
- `BossUI.tscn` on `FracturedRun` — name, health bar, phase label
- Registered via `WorldGenerator._spawn_boss()`

### Testing
- [ ] Boss warning at depth milestones
- [ ] BossUI tracks HP and phases
- [ ] Iron Wall reduces slam damage
- [ ] Defeat grants XP, loot, story dialogue

---

## 5. Enhanced Inventory System

### Requirements
- Grid drag-and-drop (base `InventoryHandler`)
- Weapons, armor, artifacts, consumables
- Stat bonuses sync to knight

### Architecture
- `InventoryManager` extends `InventoryHandler` on player
- `ItemData` — `item_type`, `stat_bonuses`
- `LootTable` + `WorldLootPickup` for procedural drops

### Item behavior
| Type | Effect |
|------|--------|
| weapon | Equip (double-click) → damage bonus + sword mesh |
| armor | Passive max_hp while in inventory |
| artifact | Passive mixed stats |
| consumable | Walk-over heal |

### Testing
- [ ] Walk-over loot pickup
- [ ] Double-click equip weapon
- [ ] Armor increases max HP
- [ ] Hub E-pickup still works

---

## 6. Player Progression

### Requirements
- XP, levels, stat points, passives
- Save/load `user://progression.save`

### Key APIs
```gdscript
ProgressionTracker.add_xp(amount)
ProgressionTracker.allocate_stat("strength")
ProgressionTracker.get_player_stats(equipment_bonuses)
ProgressionTracker.save_game() / load_game()
```

### Stat formula
```
max_hp     = 100 + STR*8 + DEF*4 + passives + equipment
damage     = 10 + STR*3 + MAG*2 + equipment
max_stamina = 50 + STR*2 + MAG*1.5
```

### Testing
- [ ] XP on enemy kill
- [ ] Level-up grants 2 stat points
- [ ] Save persists across runs
- [ ] Passives at levels 2, 4, 6

---

## 7. Story Layer

### Requirements
- Intro, world transitions, boss warnings/defeats
- Unified `StoryManager` autoload + `DialogueUI`

### Story beats
- `intro` — first run (StoryIntro scene)
- `world_change` — new realm at depth threshold
- `boss_warning` — guardian approaches
- `boss_defeat` — post-boss narration
- `ending` — path home mystery

### Trigger points
| Event | Caller |
|-------|--------|
| Intro | `StoryIntro._ready()` |
| World change | `WorldGenerator._check_realm_change()` |
| Boss warning | `WorldGenerator._spawn_boss()` |
| Boss defeat | `BossController._on_boss_death()` |

### Testing
- [ ] First run plays intro dialogue
- [ ] Realm change triggers narration
- [ ] Boss defeat shows story line

---

## Integration Checklist

| Script | Attach to | Scene |
|--------|-----------|-------|
| `WorldGenerator.gd` | WorldGenerator node | FracturedRun |
| `KnightController.gd` | player root | player.tscn |
| `SkillSystem.gd` | SkillSystem child | player.tscn |
| `InventoryManager.gd` | InventoryUI child | player.tscn |
| `BossController.gd` | Boss root | scenes/bosses/* |
| `BossUI.gd` | BossUI node | FracturedRun |
| `RunStoryHUD.gd` | RunStoryHUD | FracturedRun |

---

## Master Test Plan

### Run flow
1. F5 → MainMenu
2. Start Run → StoryManager intro → FracturedRun
3. Continue → same world seed
4. Escape → menu with mouse visible

### Combat
1. Pick up starter sword, equip, attack enemies
2. Use skills (watch stamina + cooldowns)
3. Level up via K, allocate stats
4. Reach depth 5, fight boss with BossUI

### World
1. Chunks stream in 7×7 area
2. Floor collision matches visuals
3. Perimeter walls block escape

### Persistence
1. `user://progression.save` exists after play
2. Level, stats, `story_seen`, seed persist
