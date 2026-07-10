extends Resource
class_name ItemData

@export var ItemName: String
@export var Icon: Texture2D
@export var ItemModelPrefab: PackedScene
@export var UsableModel: PackedScene
@export var item_type: String = "misc"
## For item_type == "weapon": "melee" (default), "gun", or "staff".
@export var weapon_class: String = ""
@export var stat_bonuses: Dictionary = {}
## If set, picking up this item unlocks the matching skill id (e.g. "arcane_bolt").
@export var unlock_skill: String = ""
