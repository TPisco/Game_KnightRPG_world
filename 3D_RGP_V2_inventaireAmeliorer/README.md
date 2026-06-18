# KnightRPG: Fractured Worlds

A modular 3D action RPG extension of **3D_RPG_V2_inventaireAmeliorer** (Godot 4.x, GDScript).

## Quick Start

1. Open this folder in **Godot 4.x** (project uses 4.6 features).
2. Press **F5** — starts at `scenes/ui/MainMenu.tscn`.
3. **Start Run** → story intro (first time) → procedural fractured world.
4. **Original Hub World** loads the handcrafted `world.tscn` from the base project.

## Controls

| Action | Key |
|--------|-----|
| Move | WASD |
| Look | Mouse |
| Attack | Left Click |
| Skill | Right Click or **Q** |
| Skills / Build / Stats | **K** |
| Inventory | **I** |
| Pickup (hub) | **E** |
| Jump | Space |
| Menu | Escape |

## Core Features

| Feature | Implementation |
|---------|----------------|
| Infinite world | `WorldGenerator.gd` streams `WorldChunk` tiles; depth scales enemies & loot |
| Knight | `scenes/objects/player.tscn` (alias: `knight.tscn`) |
| Skills | `SkillSystem.gd` — Power Slash, Arcane Bolt, Iron Wall, Life Drain |
| Bosses | Fractured Guardian (5), Rift Herald (12), Void Warden (20) |
| Inventory | `InventoryManager.gd` extends grid UI; artifacts + weapon stats |
| Progression | `ProgressionTracker.gd` — XP, levels, passives, save/load |
| Story | `RunStoryHUD` + `StoryIntro` — fractured multiverse lore |

## Project Structure

```
systems/           # Core modules (required by spec)
  ProgressionTracker.gd
  WorldGenerator.gd
  WorldChunk.gd
  SkillSystem.gd
  InventoryManager.gd
  BossController.gd
  BossRegistry.gd
  RiftHerald.gd
  VoidWarden.gd

scenes/
  ui/              MainMenu, StoryIntro, SkillSelectionUI, RunStoryHUD
  world/           FracturedRun, WorldChunk
  bosses/          FracturedGuardian, RiftHerald, VoidWarden
  objects/         player.tscn, knight.tscn, chunk_enemy.tscn
  Inventory/       Existing grid system + ItemData stats
  projectiles/     ArcaneBolt
  Items/           fractured_shard loot

scripts/           Extended player, enemy, global + chunk_enemy
```

## Autoloads

- `Global` — player reference, run flags, realm id
- `ProgressionTracker` — persistent progression (`user://progression.save`)
- `StoryManager` — dialogue beats (intro, world change, boss events)
- `SkillSystemGlobal` — skill database bridge (activation stays on player node)

## Knight Controller

- `scripts/KnightController.gd` — `class_name KnightController` (movement, stamina, combat VFX)
- `scripts/player.gd` — extends `KnightController` for scene compatibility
- Stamina regenerates over time; skills cost stamina + have cooldowns
- Floating damage numbers + screen shake on combat hits

## World Streaming

- `LOAD_RANGE = 3` (7×7 chunks), `UNLOAD_RANGE = 5`
- `difficulty_multiplier` scales enemy stats per depth

## Boss UI

- `BossUI.tscn` on `FracturedRun` — health bar, phase label during boss fights

## Full Implementation Guide

See **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** for complete system architecture, integration notes, and testing checklists.

## Skills & Builds

| Skill | Build | Unlock |
|-------|-------|--------|
| Power Slash | Strength | Level 1 |
| Arcane Bolt | Magic | Level 3 |
| Iron Wall | Defense | Level 3 |
| Life Drain | Hybrid | Level 5 + STR/MAG ≥ 2 |

Press **K** to pick build path, active skill, and spend stat points (+STR / +MAG / +DEF).

## Passives (auto-unlock)

| Passive | Level | Effect |
|---------|-------|--------|
| veteran_armor | 2 | +15 max HP |
| arcane_flow | 4 | −5% skill cooldown |
| iron_resolve | 6 | Stronger guard |

## Bosses

| Depth | Boss | Mechanic |
|-------|------|----------|
| 5 | Fractured Guardian | Multi-phase slams |
| 12 | Rift Herald | Summons minions |
| 20 | Void Warden | Void pulse AoE |

## Integration

See **[INTEGRATION.md](INTEGRATION.md)** for the full merge plan, reusable components, and extension points.

## Asset Replacement

| Placeholder | File | Replace with |
|-------------|------|--------------|
| Knight capsule | `player.tscn` MeshInstance3D | Knight rig |
| Chunk enemies | `chunk_enemy.tscn` | Your enemy models |
| Bosses | `scenes/bosses/*.tscn` | Boss rigs + animations |
| Terrain material | `WorldChunk.gd` | Textured terrain shader |
| Props | `WorldChunk.gd` `_load_prop_scenes()` | Biome asset lists |
| Arcane bolt | `ArcaneBolt.tscn` | VFX projectile |
| Fractured shard | `fractured_shard.tscn` | Artifact model |

## Settings

Main Menu → **Settings** → mouse sensitivity slider (saved to progression file).

## Troubleshooting

- **Empty world / freeze**: Chunks load one per frame; wait a moment on first spawn.
- **Fall through terrain**: Trimesh terrain collision + perimeter `WorldBarrier` walls.
- **Hub world**: Use **Original Hub World** from main menu; portals still work.
- **Mouse hidden in menu**: Fixed — Escape and menu screens force visible cursor.

## Original Project Preserved

`world.tscn`, `world_2.tscn`, portals, respawners, gobelin enemies, and inventory pickup in the hub are unchanged and accessible from the main menu.
