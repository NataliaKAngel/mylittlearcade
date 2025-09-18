extends Control

signal spin_started
signal ball_dropped(item_id: String)
signal empty_machine

@onready var machine_panel: Panel      = %MachinePanel
@onready var balls2d: Node2D           = %Balls2D
@onready var chute: Marker2D           = %ChutePos
@onready var hint: Label               = %HintLabel
@onready var ball_canvas: Control      = %BallCanvas  # har BallCanvas.gd

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _ball_nodes: Array[Node2D] = []   # 👈 viktig: typed array
var _busy: bool = false

func _ready() -> void:
	_rng.randomize()

	hint.text = "Insert %d coins and SPIN!" % GameState.spin_cost

	# sørg for at BallCanvas har script og peker hit som provider
	if ball_canvas.get_script() == null:
		ball_canvas.set_script(preload("res://scripts/BallCanvas.gd"))
	ball_canvas.set("provider", self)

	_build_placeholder_balls(GameState.pool_remaining())
	GameState.pool_changed.connect(_on_pool_changed)

func _on_pool_changed(left: int) -> void:
	_sync_ball_count(left)

func _build_placeholder_balls(n: int) -> void:
	if is_instance_valid(balls2d):
		balls2d.queue_free()
	balls2d = Node2D.new()
	balls2d.name = "Balls2D"
	machine_panel.add_child(balls2d)

	_ball_nodes.clear()

	# område inni maskinen – justér når du har grafikk
	var rect := Rect2(Vector2(40, 40), Vector2(480, 300))

	for i in n:
		var dot := Node2D.new()
		dot.position = Vector2(
			rect.position.x + _rng.randf() * rect.size.x,
			rect.position.y + _rng.randf() * rect.size.y
		)
		dot.set_meta("color", Color.from_hsv(_rng.randf(), 0.6, 1.0))
		balls2d.add_child(dot)
		_ball_nodes.append(dot)

	ball_canvas.queue_redraw()

func _sync_ball_count(n: int) -> void:
	var curr: int = _ball_nodes.size()
	if n < curr:
		var diff: int = curr - n
		for i in diff:
			var nd: Node2D = _ball_nodes.pop_back() as Node2D  # 👈 typed pop
			if is_instance_valid(nd):
				nd.queue_free()
		ball_canvas.queue_redraw()
	elif n > curr:
		_build_placeholder_balls(n)

func _process(_delta: float) -> void:
	# liten idle-sway
	var t: float = Time.get_ticks_msec() / 1000.0
	for i in _ball_nodes.size():
		var nd: Node2D = _ball_nodes[i]
		nd.position.x += sin(t * 2.0 + float(i)) * 0.08
		nd.position.y += cos(t * 1.7 + float(i)) * 0.08
	ball_canvas.queue_redraw()

func play_spin() -> void:
	if _busy:
		return
	if not GameState.can_spin():
		if GameState.pool_remaining() == 0:
			emit_signal("empty_machine")
		return

	_busy = true
	emit_signal("spin_started")

	await _shake(0.5, 8.0)

	var item_id: String = GameState.spin()

	await _drop_one()

	emit_signal("ball_dropped", item_id)
	_busy = false

func _shake(duration: float, amp: float) -> void:
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var orig: Vector2 = machine_panel.position
	var steps: int = int(duration / 0.05)
	for i in steps:
		var off := Vector2(
			_rng.randf_range(-amp, amp),
			_rng.randf_range(-amp, amp)
		)
		tween.tween_property(machine_panel, "position", orig + off, 0.05)
	tween.tween_property(machine_panel, "position", orig, 0.05)
	await tween.finished

func _drop_one() -> void:
	if _ball_nodes.is_empty():
		return
	var node: Node2D = _ball_nodes.pop_back() as Node2D
	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "global_position", chute.global_position, 0.45)
	await tween.finished
	if is_instance_valid(node):
		node.queue_free()
	ball_canvas.queue_redraw()
