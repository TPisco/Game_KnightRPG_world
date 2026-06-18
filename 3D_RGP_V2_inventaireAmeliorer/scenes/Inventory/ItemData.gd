extends Resource
class_name ItemData

@export var ItemName: String
@export var Icon: Texture2D
@export var ItemModelPrefab: PackedScene
@export var UsableModel: PackedScene
@export var item_type: String = "misc"
@export var stat_bonuses: Dictionary = {}
