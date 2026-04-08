#respawner
extends Node3D


@export var enemy : PackedScene
@onready var timer = $Timer

var timerStarted = false


func _process(delta: float) -> void:
	if get_child_count()<=1 and timerStarted == false:
		timer.start()
		timerStarted = true

func _on_timer_timeout() -> void:
	var instance = enemy.instantiate()
	add_child(instance)
	timerStarted = false
