extends Node

var current_ui : Node = null

func _ready():
	# sjekk skjermstørrelse
	var is_portrait = get_viewport().size.y > get_viewport().size.x
	if is_portrait:
		switch_ui("res://ui/UI_Portrait.tscn")
	else:
		switch_ui("res://ui/UI_Landscape.tscn")

func switch_ui(scene_path: String):
	if current_ui:
		current_ui.queue_free()
	var new_ui = load(scene_path).instantiate()
	get_tree().root.add_child(new_ui)
	current_ui = new_ui
