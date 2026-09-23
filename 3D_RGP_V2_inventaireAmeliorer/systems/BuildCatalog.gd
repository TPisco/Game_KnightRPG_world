## Furnishing catalog for the hub/tavern housing system.
## Entries: id, name, model, radius (footprint), solid (blocks movement),
## fn (functional behaviour), unlock (bosses required, 0 = always available).
extends Node
class_name BuildCatalog

const PACK := "res://assets/model/FantasyPack/"


static func categories() -> Array:
	return [
		{
			"name": "Outdoor Decor",
			"items": [
				_e("fence", "Wooden Fence", "props/fence_wood.glb", 1.4, true),
				_e("stone_wall", "Stone Wall", "props/stone_wall.glb", 1.6, true),
				_e("sign_post", "Sign Post", "props/sign_post.glb", 0.5),
				_e("lamp_post", "Lamp Post", "props/lamp_post.glb", 0.6),
				_e("well", "Village Well", "props/well.glb", 1.6, true),
				_e("gravestone", "Gravestone", "props/gravestone.glb", 0.6),
				_e("ruin_arch", "Ruined Arch", "props/ruin_arch.glb", 2.0),
				_e("ruin_wall", "Ruined Wall", "props/ruin_wall.glb", 1.6, true),
				_e("pillar_ruined", "Broken Pillar", "props/pillar_ruined.glb", 0.8, true),
			],
		},
		{
			"name": "Furniture",
			"items": [
				_e("table", "Tavern Table", "shop/shop_table.glb", 1.0, true),
				_e("stool", "Stool", "shop/shop_stool.glb", 0.4),
				_e("counter", "Bar Counter", "shop/shop_counter.glb", 1.6, true),
				_e("shelf", "Shelf", "shop/shop_shelf.glb", 1.0, true),
				_e("chest", "Chest", "dungeon/chest.glb", 0.7),
				_e("barrel", "Barrel", "shop/barrel.glb", 0.5),
				_e("crate", "Crate", "shop/crate.glb", 0.5),
				_e("sack", "Sack", "shop/sack.glb", 0.4),
			],
		},
		{
			"name": "Lighting",
			"items": [
				_e("brazier", "Brazier", "dungeon/brazier.glb", 0.6, false, "", 0, 1.6, Color(1, 0.6, 0.3)),
				_e("torch_sconce", "Torch Sconce", "dungeon/torch_sconce.glb", 0.3, false, "", 0, 1.2, Color(1, 0.65, 0.35)),
				_e("torch_wall", "Wall Torch", "cave/torch_wall.glb", 0.3, false, "", 0, 1.2, Color(1, 0.65, 0.35)),
				_e("crystal_blue", "Blue Crystals", "cave/crystal_cluster_blue.glb", 0.6, false, "", 0, 1.0, Color(0.4, 0.7, 1)),
				_e("crystal_purple", "Purple Crystals", "cave/crystal_cluster_purple.glb", 0.6, false, "", 0, 1.0, Color(0.7, 0.4, 1)),
			],
		},
		{
			"name": "Nature",
			"items": [
				_e("tree_oak", "Oak Tree", "props/tree_oak.glb", 1.2, true),
				_e("tree_pine", "Pine Tree", "props/tree_pine.glb", 1.0, true),
				_e("bush", "Bush", "props/bush.glb", 0.7),
				_e("rock_small", "Small Rock", "cave/rock_small.glb", 0.5),
				_e("rock_medium", "Medium Rock", "cave/rock_medium.glb", 0.8),
				_e("rock_large", "Large Rock", "cave/rock_large.glb", 1.2, true),
			],
		},
		{
			"name": "Tavern Decor",
			"items": [
				_e("rug", "Rug", "shop/rug.glb", 1.2),
				_e("potion_red", "Red Bottles", "shop/potion_red.glb", 0.25),
				_e("potion_blue", "Blue Bottles", "shop/potion_blue.glb", 0.25),
				_e("potion_green", "Green Bottles", "shop/potion_green.glb", 0.25),
				_e("coin_pile", "Coin Pile", "shop/coin_pile.glb", 0.35),
				_e("shop_sign", "Hanging Sign", "shop/shop_sign.glb", 0.7),
				_e("chain", "Hanging Chain", "dungeon/chain_hanging.glb", 0.3),
				_e("bone_pile", "Bone Pile", "cave/bone_pile.glb", 0.6),
			],
		},
		{
			"name": "Structures",
			"items": [
				_e("dungeon_pillar", "Stone Pillar", "dungeon/dungeon_pillar.glb", 0.7, true),
				_e("dungeon_wall", "Dungeon Wall", "dungeon/dungeon_wall.glb", 1.6, true),
				_e("dungeon_corner", "Wall Corner", "dungeon/dungeon_wall_corner.glb", 1.6, true),
				_e("dungeon_gate", "Iron Gate", "dungeon/dungeon_gate.glb", 1.4, true),
				_e("dungeon_door", "Heavy Door", "dungeon/dungeon_door.glb", 1.2, true),
				_e("cave_wall", "Rock Wall", "cave/cave_wall.glb", 1.6, true),
			],
		},
		{
			"name": "Functional",
			"items": [
				_e("training_dummy", "Training Dummy", "mobs/mob_goblin_brute.glb", 0.8, false, "dummy"),
				_e("restoration_font", "Restoration Font", "props/well.glb", 1.6, false, "font", 0, 1.4, Color(0.5, 1, 0.8)),
				_e("merchant_stand", "Merchant Statue", "characters/merchant.glb", 0.6),
			],
		},
		{
			"name": "Trophies",
			"items": [
				_e("knight_statue", "Knight Statue", "characters/player_knight.glb", 0.6),
				_e("trophy_sword", "Mounted Greatsword", "weapons/greatsword.glb", 0.4),
				_e("trophy_shield", "Mounted Shield", "weapons/shield_kite.glb", 0.4),
				_e("trophy_staff", "Displayed Staff", "weapons/staff_arcane.glb", 0.4),
				_e("trophy_guardian", "Cave Guardian Trophy", "minibosses/miniboss_cave_guardian.glb", 1.0, false, "", 1),
				_e("trophy_golem", "Crystal Golem Trophy", "minibosses/miniboss_crystal_golem.glb", 1.0, false, "", 2),
				_e("trophy_warden", "Void Warden Trophy", "bosses/boss_void_warden.glb", 1.5, false, "", 3),
			],
		},
	]


static func _e(id: String, display: String, model: String, radius: float,
		solid: bool = false, fn: String = "", unlock: int = 0,
		light_energy: float = 0.0, light_color: Color = Color.WHITE) -> Dictionary:
	return {
		"id": id,
		"name": display,
		"path": PACK + model,
		"radius": radius,
		"solid": solid,
		"fn": fn,
		"unlock": unlock,
		"light_energy": light_energy,
		"light_color": light_color,
	}


static func get_entry(id: String) -> Dictionary:
	for category in categories():
		for raw in category["items"]:
			var entry: Dictionary = raw
			if str(entry["id"]) == id:
				return entry
	return {}


static func is_unlocked(entry: Dictionary, bosses_defeated: int) -> bool:
	return int(entry.get("unlock", 0)) <= bosses_defeated
