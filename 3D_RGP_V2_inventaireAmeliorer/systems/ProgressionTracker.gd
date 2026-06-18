## Persistent progression: XP, stats, skill unlocks, save/load.
extends Node

const SAVE_PATH := "user://progression.save"

signal level_up(new_level: int)
signal xp_gained(amount: int)
signal skill_unlocked(skill_id: String)

# --- Persistent (saved between runs) ---
var level: int = 1
var xp: int = 0
var xp_to_next: int = 100
var strength: int = 1
var magic: int = 1
var defense: int = 1
var stat_points: int = 0
var unlocked_skills: Array[String] = ["power_slash"]
var build_path: String = "strength"
var total_runs: int = 0
var bosses_defeated: int = 0
var story_seen: bool = false
var mouse_sensitivity: float = 0.003
var unlocked_passives: Array[String] = []

# --- Per-run (reset when a new run starts) ---
var run_depth: int = 0
var run_seed: int = 0
var temp_buffs: Dictionary = {}

const SKILL_DEFS := {
	"power_slash": {"level": 1, "path": "strength"},
	"arcane_bolt": {"level": 3, "path": "magic"},
	"iron_wall": {"level": 3, "path": "defense"},
	"life_drain": {"level": 5, "path": "hybrid"},
}

const PASSIVE_DEFS := {
	"veteran_armor": {"level": 2, "bonus": {"max_hp": 15}},
	"arcane_flow": {"level": 4, "bonus": {"skill_cooldown_mult": -0.05}},
	"iron_resolve": {"level": 6, "bonus": {"max_hp": 10}},
}

const BASE_STATS := {
	"max_hp": 100,
	"damage": 10,
	"speed": 5.0,
	"max_stamina": 50.0,
	"skill_cooldown_mult": 1.0,
}


func _ready() -> void:
	load_game()


func start_new_run(use_existing_seed: bool = false) -> void:
	if not use_existing_seed or run_seed == 0:
		run_seed = randi()
	run_depth = 0
	temp_buffs.clear()
	total_runs += 1
	_check_skill_unlocks()
	_check_passive_unlocks()
	save_game()


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	xp_gained.emit(amount)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		stat_points += 2
		xp_to_next = int(xp_to_next * 1.35)
		level_up.emit(level)
		_check_skill_unlocks()
		_check_passive_unlocks()
	save_game()


func register_boss_defeat() -> void:
	bosses_defeated += 1
	add_xp(150)
	save_game()


func set_build_path(path: String) -> void:
	if path in ["strength", "magic", "defense", "hybrid"]:
		build_path = path
		_check_skill_unlocks()
		save_game()


func allocate_stat(stat_name: String) -> bool:
	if stat_points <= 0:
		return false
	match stat_name:
		"strength":
			strength += 1
		"magic":
			magic += 1
		"defense":
			defense += 1
		_:
			return false
	stat_points -= 1
	save_game()
	return true


func is_skill_unlocked(skill_id: String) -> bool:
	return skill_id in unlocked_skills


func refresh_skill_unlocks() -> void:
	_check_skill_unlocks()


func get_player_stats(equipment_bonuses: Dictionary = {}) -> Dictionary:
	var stats := BASE_STATS.duplicate()
	stats["max_hp"] += strength * 8 + defense * 4
	stats["damage"] += strength * 3 + magic * 2
	stats["speed"] += strength * 0.15
	stats["max_stamina"] += strength * 2.0 + magic * 1.5
	stats["skill_cooldown_mult"] = maxf(0.4, 1.0 - magic * 0.04)
	_apply_passive_bonuses(stats)
	for key in equipment_bonuses:
		if key in stats:
			if typeof(stats[key]) == TYPE_FLOAT:
				stats[key] += float(equipment_bonuses[key])
			else:
				stats[key] += int(equipment_bonuses[key])
	return stats


func get_guard_damage_multiplier() -> float:
	var mult := 0.1
	if build_path == "defense":
		mult = 0.05
	if "iron_resolve" in unlocked_passives:
		mult *= 0.5
	return mult


func get_passive_list() -> Array[String]:
	return unlocked_passives.duplicate()


func update_run_depth(depth: int) -> void:
	if depth > run_depth:
		run_depth = depth


func save_game() -> void:
	var data := {
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next,
		"strength": strength,
		"magic": magic,
		"defense": defense,
		"stat_points": stat_points,
		"unlocked_skills": unlocked_skills,
		"build_path": build_path,
		"total_runs": total_runs,
		"bosses_defeated": bosses_defeated,
		"story_seen": story_seen,
		"run_seed": run_seed,
		"run_depth": run_depth,
		"mouse_sensitivity": mouse_sensitivity,
		"unlocked_passives": unlocked_passives,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	level = parsed.get("level", 1)
	xp = parsed.get("xp", 0)
	xp_to_next = parsed.get("xp_to_next", 100)
	strength = parsed.get("strength", 1)
	magic = parsed.get("magic", 1)
	defense = parsed.get("defense", 1)
	stat_points = parsed.get("stat_points", 0)
	unlocked_skills.clear()
	var saved_skills = parsed.get("unlocked_skills", ["power_slash"])
	if saved_skills is Array:
		for skill_id in saved_skills:
			unlocked_skills.append(str(skill_id))
	build_path = parsed.get("build_path", "strength")
	total_runs = parsed.get("total_runs", 0)
	bosses_defeated = parsed.get("bosses_defeated", 0)
	story_seen = parsed.get("story_seen", false)
	run_seed = parsed.get("run_seed", 0)
	run_depth = parsed.get("run_depth", 0)
	mouse_sensitivity = parsed.get("mouse_sensitivity", 0.003)
	unlocked_passives.clear()
	var saved_passives = parsed.get("unlocked_passives", [])
	if saved_passives is Array:
		for passive_id in saved_passives:
			unlocked_passives.append(str(passive_id))
	_check_skill_unlocks()
	_check_passive_unlocks()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) and run_seed != 0


func _check_skill_unlocks() -> void:
	for skill_id in SKILL_DEFS:
		var def: Dictionary = SKILL_DEFS[skill_id]
		if level < def["level"]:
			continue
		if skill_id == "life_drain" and (strength < 2 or magic < 2):
			continue
		if def["path"] != build_path and skill_id != "power_slash":
			if skill_id == "life_drain" and build_path != "hybrid":
				continue
			if skill_id != "life_drain":
				continue
		if skill_id not in unlocked_skills:
			unlocked_skills.append(skill_id)
			skill_unlocked.emit(skill_id)


func _check_passive_unlocks() -> void:
	for passive_id in PASSIVE_DEFS:
		var def: Dictionary = PASSIVE_DEFS[passive_id]
		if level >= def["level"] and passive_id not in unlocked_passives:
			unlocked_passives.append(passive_id)


func _apply_passive_bonuses(stats: Dictionary) -> void:
	for passive_id in unlocked_passives:
		var def: Dictionary = PASSIVE_DEFS.get(passive_id, {})
		var bonus: Dictionary = def.get("bonus", {})
		for key in bonus:
			if key in stats:
				if typeof(stats[key]) == TYPE_FLOAT:
					stats[key] += float(bonus[key])
				else:
					stats[key] += int(bonus[key])
