extends Label3D


func setup(world_pos: Vector3, amount: int, color: Color = Color.WHITE) -> void:
	global_position = world_pos
	text = str(amount)
	modulate = color
	font_size = 48
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", world_pos.y + 1.5, 0.7)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.chain().tween_callback(queue_free)
