# KnightRPG: Fractured Worlds — Integration Plan

This document describes how **KnightRPG: Fractured Worlds** extends the existing `3D_RPG_V2_inventaireAmeliorer` project without replacing it.

## Existing Project Analysis

### Reused as-is
| Component | Path | Role |
|-----------|------|------|
| Player movement & combat | `scripts/player.gd`, `scenes/objects/player.tscn` | WASD, jump, sword swing, guard |
| Grid inventory | `InventoryHandler.gd`, `InventorySlot.gd` | Drag-drop slots, equip |
| Item pickup | `InteractebleItem.gd`, `playerInteractionHandler.gd` | E key proximity pickup |
| Hub worlds | `scenes/world.tscn`, `scenes/world_2.tscn` | Handcrafted maps + portals |
| Enemy AI (hub) | `scripts/enemy.gd`, `scenes/objects/enemy.tscn` | Gobelin FSM |
| Portals / respawn | `portal.gd`, `respawner.gd` | Scene travel, enemy respawn |

### Extended
| File | Extension |
|------|-----------|
| `scripts/global.gd` | Run flags, realm id, save bridge |
| `scripts/player.gd` | Progression stats, skills, death flow |
| `scripts/enemy.gd` | XP rewards, nav fallback |
| `scenes/Inventory/ItemData.gd` | `stat_bonuses`, `item_type` |
| `scenes/objects/player.tscn` | `SkillSystem`, `InventoryManager`, HUD |
| `project.godot` | Autoloads, inputs, main scene |

### New modules (`res://systems/`)
| Module | Hook point |
|--------|------------|
| `ProgressionTracker.gd` | Autoload — all XP, saves, passives |
| `WorldGenerator.gd` | Root of `FracturedRun.tscn` |
| `WorldChunk.gd` | Spawned per grid coordinate |
| `SkillSystem.gd` | Child node on player |
| `InventoryManager.gd` | Replaces inventory script on player |
| `BossController.gd` | Base boss AI |
| `RiftHerald.gd`, `VoidWarden.gd` | Unique boss mechanics |
| `BossRegistry.gd` | Milestone → boss scene + lore |

## Scene Flow

```
MainMenu.tscn
 ├── Start Run → StoryIntro.tscn (first time) → FracturedRun.tscn
 ├── Continue  → FracturedRun.tscn
 ├── Hub       → world.tscn (original project)
 └── Settings / Credits

FracturedRun.tscn
 ├── SkillSelectionUI (K key)
 ├── RunStoryHUD (realm lore)
 └── WorldGenerator
      ├── WorldChunk × N (procedural)
      ├── WorldBarrier (perimeter physics)
      └── player.tscn (spawned at runtime)
```

## Merge Guide (other branches / copies)

1. Copy `systems/`, `scenes/ui/`, `scenes/world/`, `scenes/bosses/`, `scenes/projectiles/`, `scenes/Items/fractured_shard.tscn`, `scripts/chunk_enemy.gd`, `scenes/objects/chunk_enemy.tscn`, `scenes/objects/knight.tscn`.
2. Merge `project.godot` autoloads: add `ProgressionTracker`, set `run/main_scene` to MainMenu UID.
3. Add input actions: `skill`, `skill_menu`.
4. Replace `player.tscn` InventoryUI script path with `InventoryManager.gd`; add `SkillSystem` node.
5. Keep original `world.tscn` as optional hub via Main Menu.

## Asset Replacement

All placeholder meshes use Godot primitives or your existing GLB paths in `WorldChunk.gd`. Swap scene files or update `_load_prop_scenes()` paths — no code rewrite required.

## Success Checklist

- [x] Modular GDScript systems in `systems/`
- [x] Procedural infinite chunks with escalating depth
- [x] Knight controls (WASD, LMB, RMB/Q, I, Space)
- [x] 4 skills + build paths + passives
- [x] 3 unique bosses at depths 5 / 12 / 20
- [x] Inventory drag-drop + stat bonuses + tooltips
- [x] Save/load via `user://progression.save`
- [x] Main menu, story intro, skill UI
- [x] README + integration plan
