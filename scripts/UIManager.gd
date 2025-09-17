extends Node

const UI_LANDSCAPE := preload("res://ui/UI_Landscape.tscn")
const UI_PORTRAIT  := preload("res://ui/UI_Portrait.tscn")

var current_ui: Node = null
var _is_portrait: bool = false
var _initialized: bool = false
var _switching: bool = false
var _resize_timer := Timer.new()

func _ready() -> void:
	# Debounce rapid resizes
	_resize_timer.one_shot = true
	_resize_timer.wait_time = 0.08
	add_child(_resize_timer)
	_resize_timer.timeout.connect(_apply_layout)

	# IMPORTANT: wait for window to exist, then apply once
	await get_tree().process_frame
	_apply_layout()

	# React on window resize
	get_tree().root.size_changed.connect(_on_window_resized)

func _on_window_resized() -> void:
	_resize_timer.start()

func _apply_layout() -> void:
	if _switching:
		return
	_switching = true

	var win_size: Vector2i = DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0:
		# window not ready yet – try again next frame
		_switching = false
		call_deferred("_apply_layout")
		return

	var want_portrait := win_size.y > win_size.x

	if _initialized and current_ui and _is_portrait == want_portrait:
		_switching = false
		return

	_initialized = true
	_is_portrait = want_portrait

	if current_ui:
		current_ui.queue_free()
		current_ui = null
		await get_tree().process_frame

	var scene: PackedScene = UI_PORTRAIT if want_portrait else UI_LANDSCAPE
	var ui := scene.instantiate()

	# Fail-safe: ensure Full Rect
	if ui is Control:
		var c := ui as Control
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.offset_left = 0
		c.offset_top = 0
		c.offset_right = 0
		c.offset_bottom = 0

	get_tree().root.add_child(ui)
	current_ui = ui

	_switching = false
	print("[UI] Loaded " + ("PORTRAIT" if want_portrait else "LANDSCAPE"))
