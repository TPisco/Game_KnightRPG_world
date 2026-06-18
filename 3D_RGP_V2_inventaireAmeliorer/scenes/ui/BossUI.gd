## Boss health bar shown during epic encounters.
extends CanvasLayer

@onready var boss_name_label: Label = $Panel/BossNameLabel
@onready var health_bar: ProgressBar = $Panel/HealthBar
@onready var phase_label: Label = $Panel/PhaseLabel

var _tracked_boss: Node = null


func _ready() -> void:
	visible = false


func register_boss(boss: Node) -> void:
	if not is_instance_valid(boss):
		return
	_tracked_boss = boss
	visible = true
	if "boss_name" in boss:
		boss_name_label.text = boss.boss_name
	elif boss.has_method("get_boss_name"):
		boss_name_label.text = boss.get_boss_name()
	if "max_hp" in boss:
		health_bar.max_value = boss.max_hp
	if "hp" in boss:
		health_bar.value = boss.hp
	if boss.has_signal("phase_changed"):
		if not boss.phase_changed.is_connected(_on_phase_changed):
			boss.phase_changed.connect(_on_phase_changed)
	if boss.has_signal("boss_defeated"):
		if not boss.boss_defeated.is_connected(_on_boss_defeated):
			boss.boss_defeated.connect(_on_boss_defeated)


func _process(_delta: float) -> void:
	if not is_instance_valid(_tracked_boss):
		visible = false
		return
	if "hp" in _tracked_boss:
		health_bar.value = _tracked_boss.hp
		if _tracked_boss.hp <= 0:
			_on_boss_defeated()


func _on_phase_changed(phase: int) -> void:
	phase_label.text = "Phase %d" % phase


func _on_boss_defeated() -> void:
	_tracked_boss = null
	visible = false
	phase_label.text = ""
