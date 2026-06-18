## Global skill database and unlock helpers (autoload bridge).
extends Node

signal skill_unlocked(skill_data: Dictionary)

const SKILL_DATABASE: Array = SkillSystem.SKILL_DATABASE


func check_skill_unlocks(knight_stats: Dictionary) -> void:
	ProgressionTracker.refresh_skill_unlocks()
	for skill in SKILL_DATABASE:
		if typeof(skill) != TYPE_DICTIONARY:
			continue
		var skill_id: String = skill.get("id", "")
		if skill_id != "" and ProgressionTracker.is_skill_unlocked(skill_id):
			skill_unlocked.emit(skill)


func get_skill_by_id(skill_id: String) -> Dictionary:
	for skill in SKILL_DATABASE:
		if skill.get("id", "") == skill_id:
			return skill
	return {}


func get_stamina_cost(skill_id: String) -> float:
	return SkillSystem.SKILL_STAMINA_COSTS.get(skill_id, 20.0)
