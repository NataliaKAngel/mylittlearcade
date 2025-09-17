extends Node

const UI_LANDSCAPE := "res://ui/UI_Landscape.tscn"
const UI_PORTRAIT  := "res://ui/UI_Portrait.tscn"

func _ready() -> void:
	_apply_layout()

func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_apply_layout()

func _apply_layout() -> void:
	var size = get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	var path := portrait ? UI_PORTRAIT : UI_LANDSCAPE

	# Hvis ingen scene, eller feil scene, bytt.
	var current := get_tree().current_scene
	if not current or current.scene_file_path != path:
		get_tree().change_scene_to_file(path)
