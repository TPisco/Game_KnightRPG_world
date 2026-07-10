# KnightRPG: Fractured Worlds — FantasyPack

Unified low-poly fantasy asset set, generated procedurally in one shared style
(one palette, flat shading, matching modeling density). All files are GLB
(glTF binary), ready for Godot 4.x: drop-in, no import settings needed.

## Conventions
- Scale: 1 unit = 1 meter. Player knight ≈ 1.75 m, mobs 0.8–1.7 m,
  mini-bosses ≈ 2.2–2.6 m, bosses ≈ 3.2–3.8 m.
- Orientation: characters/buildings face **-Z** (Godot forward).
  Weapons: grip at origin, blade up **+Y**; guns barrel toward **-Z**.
  `stalactite` and `chain_hanging` have their origin at the TOP (hang from ceilings).
  `torch_wall` / `torch_sconce` mount against a wall at +Z behind them.
- Materials: shared `P_*` palette (base color + metallic/roughness).
  Crystals, flames, potions and glowing eyes use emissive materials —
  enable Glow in a WorldEnvironment for the full effect.
- Poly counts: ~24–700 tris per asset. Safe to spawn in large numbers.

## Folders
- characters/  player_knight, merchant
- weapons/     3 swords, greatsword, axe, dagger, 2 staffs, 2 guns, 2 shields
- mobs/        goblin, goblin_brute, skeleton, skeleton_armored, slime,
               mushroom, void_wisp, orc
- minibosses/  cave_guardian (red), crystal_golem, orc_warlord
- bosses/      fractured_guardian, rift_herald, void_warden
- shop/        building, counter, shelf, table, stool, barrel, crate, sack,
               3 potions, sign, coin_pile, rug
- cave/        entrance, 3 rocks, stalagmite/stalactite, 2 crystal clusters,
               bone_pile, torch_wall, cave_wall, cave_floor
- dungeon/     wall, wall_corner, floor, pillar, pillar_broken, door, gate,
               torch_sconce, brazier, chest, chain_hanging
- props/       stone_wall, fence, ruin_arch, ruin_wall, pillar_ruined,
               sign_post, lamp_post, tree_pine, tree_oak, bush, well, gravestone

## Regenerating / tweaking
Generator scripts (Python + trimesh) are in `asset_src/` at the project root.
Edit palette or shapes in `lowpoly.py` / `build_*.py` and re-run to rebuild.
