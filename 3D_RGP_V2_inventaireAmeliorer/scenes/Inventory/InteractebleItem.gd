extends Node3D
class_name InteractebleItem

@export var ItemHighLightMesh : MeshInstance3D

func GainFocus():
	ItemHighLightMesh.visible = true

func LoseFocus():
	ItemHighLightMesh.visible = false
