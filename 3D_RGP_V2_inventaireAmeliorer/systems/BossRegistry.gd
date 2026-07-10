## Maps depth milestones to boss scenes and lore entries.
extends Node
class_name BossRegistry

const BOSSES_BY_MILESTONE := {
	5: {
		"scene": "res://scenes/bosses/FracturedGuardian.tscn",
		"name": "Fractured Guardian",
		"lore": "A shard of your broken world given terrible will.",
	},
	12: {
		"scene": "res://scenes/bosses/RiftHerald.tscn",
		"name": "Rift Herald",
		"lore": "It calls creatures through the cracks between realms.",
	},
	20: {
		"scene": "res://scenes/bosses/VoidWarden.tscn",
		"name": "Void Warden",
		"lore": "The gatekeeper that hides the path back home.",
	},
}

const REALM_BY_DEPTH := {
	0: {"id": "fractured_wastes", "name": "Fractured Wastes", "hint": "Find the guardians. Each defeat reveals another rift."},
	5: {"id": "ember_rifts", "name": "Ember Rifts", "hint": "The land grows hostile. Your skills may be the key home."},
	12: {"id": "shattered_veil", "name": "Shattered Veil", "hint": "Realms overlap here. The Void Warden watches from afar."},
	20: {"id": "void_threshold", "name": "Void Threshold", "hint": "Beyond lies either oblivion — or the road back to your world."},
}


static func get_boss_scene(milestone: int) -> PackedScene:
	var entry: Dictionary = BOSSES_BY_MILESTONE.get(milestone, {})
	var path: String = entry.get("scene", "res://scenes/bosses/FracturedGuardian.tscn")
	if ResourceLoader.exists(path):
		return load(path)
	return load("res://scenes/bosses/FracturedGuardian.tscn")


static func get_boss_name(milestone: int) -> String:
	return BOSSES_BY_MILESTONE.get(milestone, {}).get("name", "Unknown Guardian")


## Realm index (cave_portals_cleared) -> that realm's real boss.
static func get_boss_milestone_for_realm(realm_index: int) -> int:
	if realm_index <= 0:
		return 5
	if realm_index == 1:
		return 12
	return 20


static func get_boss_scene_for_realm(realm_index: int) -> PackedScene:
	return get_boss_scene(get_boss_milestone_for_realm(realm_index))


static func get_boss_name_for_realm(realm_index: int) -> String:
	return get_boss_name(get_boss_milestone_for_realm(realm_index))


static func get_realm_for_depth(depth: int) -> Dictionary:
	var best: Dictionary = REALM_BY_DEPTH[0]
	var best_depth := -1
	for threshold in REALM_BY_DEPTH.keys():
		if depth >= threshold and threshold > best_depth:
			best_depth = threshold
			best = REALM_BY_DEPTH[threshold]
	return best
