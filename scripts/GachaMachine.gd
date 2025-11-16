extends Control
## Visual controller for the machine (shake, drop one ball, keep list of nodes for BallCanvas).
## Uses GameState (autoload) for actual spin logic and coins/pool.

signal spin_started
signal ball_dropped(item_id: String)
signal empty_machine

@onready var machine_panel: Panel = $CenterContainer/VBoxContainer/MachinePanel
@onready var balls2d: Node2D      = $CenterContainer/VBoxContainer/MachinePanel/Balls2D
@onready var chute: Marker2D      = $CenterContainer/VBoxContainer/MachinePanel/ChutePos
@onready var ball_canvas: Control = $CenterContainer/VBoxContainer/BallCanvas
@onready var hint: Label          = $CenterContainer/VBoxContainer/HintLabel
@onready var machine_body: TextureRect = $"CenterContainer/VBoxContainer/MachinePanel/MachineBody"
@onready var win_tl: Marker2D = $"CenterContainer/VBoxContainer/MachinePanel/WindowTL"
@onready var win_br: Marker2D = $"CenterContainer/VBoxContainer/MachinePanel/WindowBR"

const BALL_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/gacha/balls/pink_ball.png"),
	preload("res://assets/textures/gacha/balls/blue_ball.png"),
	preload("res://assets/textures/gacha/balls/green_ball.png"),
	preload("res://assets/textures/gacha/balls/yellow_ball.png"),
]

var _rng := RandomNumberGenerator.new()
var _ball_nodes: Array[Node2D] = []   # BallCanvas expects this on provider
var _busy := false

func _ready() -> void:
	_rng.randomize()
	
	machine_body.texture = load("res://assets/textures/gacha/machine_body.png")
	machine_body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	machine_body.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL  # Godot 4 setter via Inspector, men stretch+expand er nok
	machine_body.z_index = 0
	balls2d.z_index = 5              # balls layer
	machine_body.z_index = 50        # front frame on top of balls
	
	if hint:
		hint.text = "Insert %d coins and SPIN!" % GameState.spin_cost

	# Ensure BallCanvas knows where to read balls from
	if ball_canvas:
		# (If you haven’t attached BallCanvas.gd yet, uncomment the next two lines)
		# if ball_canvas.get_script() == null:
		# 	ball_canvas.set_script(preload("res://scripts/BallCanvas.gd"))
		ball_canvas.set("provider", self)

	# Build initial placeholder balls based on pool
	_build_placeholder_balls(GameState.pool_remaining())

	# Keep visual count in sync with pool changes
	if GameState.has_signal("pool_changed"):
		GameState.pool_changed.connect(_on_pool_changed)

func _window_rect_in_balls_space() -> Rect2:
	var to_local := balls2d.get_global_transform_with_canvas().affine_inverse()
	var tl := to_local * win_tl.global_position
	var br := to_local * win_br.global_position
	return Rect2(tl, br - tl)
	
func _on_pool_changed(left: int) -> void:
	_sync_ball_count(left)

func _build_placeholder_balls(n: int) -> void:
	# Clear existing
	for c in balls2d.get_children():
		c.queue_free()
	_ball_nodes.clear()

	# Hide the debug circle renderer now that we use sprites
	if ball_canvas:
		ball_canvas.visible = false

	# Area inside the machine – tweak to match your art
	var rect := _window_rect_in_balls_space()

	for i in n:
		var spr := Sprite2D.new()
		spr.texture = BALL_TEXTURES[randi() % BALL_TEXTURES.size()]
		spr.centered = true
		
		# Position randomly inside the rectangle
		spr.position = Vector2(
			rect.position.x + _rng.randf() * rect.size.x,
			rect.position.y + _rng.randf() * rect.size.y
		)
		# Scale down if your PNGs are large (adjust to taste)
		spr.scale = Vector2(0.18, 0.18)   # was 0.35 – tune to taste (0.15–0.2 works well)

		balls2d.add_child(spr)
		_ball_nodes.append(spr) # Sprite2D is a Node2D, so all existing code still works

func _sync_ball_count(n: int) -> void:
	var curr := _ball_nodes.size()
	if n < curr:
		var diff := curr - n
		for i in diff:
			var nd: Node2D = _ball_nodes.pop_back()
			if is_instance_valid(nd):
				nd.queue_free()
		if ball_canvas:
			ball_canvas.queue_redraw()
	elif n > curr:
		_build_placeholder_balls(n)

var idle_sway_amp := 0.0  # 0 disables; try 0.08 for subtle sway

func _process(_delta: float) -> void:
	if idle_sway_amp <= 0.0:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for i in _ball_nodes.size():
		var nd := _ball_nodes[i]
		nd.position.x += sin(t * 2.0 + float(i)) * idle_sway_amp
		nd.position.y += cos(t * 1.7 + float(i)) * (idle_sway_amp * 0.85)

func play_spin() -> void:
	if _busy:
		return
	if not GameState.can_spin():
		if GameState.pool_remaining() == 0:
			emit_signal("empty_machine")
		else:
			if hint: hint.text = "Not enough coins!"
		return

	_busy = true
	emit_signal("spin_started")

	await _shake(0.5, 8.0)

	var item_id: String = GameState.spin()  # updates coins/pool and emits its own signals

	await _drop_one()

	emit_signal("ball_dropped", item_id)
	_busy = false

func _shake(duration: float, amp: float) -> void:
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var orig: Vector2 = balls2d.position
	var steps: int = int(max(1, duration / 0.05))
	for i in steps:
		var off := Vector2(_rng.randf_range(-amp, amp), _rng.randf_range(-amp, amp))
		tween.tween_property(balls2d, "position", orig + off, 0.05)
	tween.tween_property(balls2d, "position", orig, 0.05)
	await tween.finished

func _drop_one() -> void:
	if _ball_nodes.is_empty():
		return
	var node: Node2D = _ball_nodes.pop_back()
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "global_position", chute.global_position, 0.45)
	await tween.finished
	if is_instance_valid(node):
		node.queue_free()
	if ball_canvas:
		ball_canvas.queue_redraw()
