extends Area3D
signal OnItemPickedUp(item)

@export var ItemTypes : Array[ItemData] = []

var NearbyBodies : Array[InteractebleItem]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		PisckUpNearestItem()

func PisckUpNearestItem():
	var nearestItem : InteractebleItem = null
	var nearestItemDistance : float = INF

	for i in range(NearbyBodies.size() - 1, -1, -1):
		if not is_instance_valid(NearbyBodies[i]):
			NearbyBodies.remove_at(i)
	for item in NearbyBodies:
		if item.global_position.distance_to(global_position) < nearestItemDistance :
			nearestItemDistance = item.global_position.distance_to(global_position)
			nearestItem = item
	
	if nearestItem !=null :
		nearestItem.queue_free()
		NearbyBodies.remove_at(NearbyBodies.find(nearestItem))
		var itemPrefab = nearestItem.scene_file_path
		for i in ItemTypes.size():
			if ItemTypes[i].ItemModelPrefab != null and ItemTypes[i].ItemModelPrefab.resource_path == itemPrefab :
				print("Item id : "+ str(i)+ " Item Name : "+ItemTypes[i].ItemName)
				OnItemPickedUp.emit(ItemTypes[i])
				return
		
		printerr("Item Not Found")

func _on_body_entered(body: Node3D) -> void:
	if body is InteractebleItem:
		body.GainFocus()
		NearbyBodies.append(body)


func _on_body_exited(body: Node3D) -> void:
	if body is InteractebleItem:
		body.LoseFocus()
		NearbyBodies.remove_at(NearbyBodies.find(body))
