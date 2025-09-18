extends Control

# GachaMachine.gd sets this:  ball_canvas.provider = self
var provider: Node = null

@export var radius: float = 6.0
@export var segments: int = 22

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if provider == null:
		return

	# Expect provider to have:  var _ball_nodes: Array[Node2D]
	var balls = provider.get("_ball_nodes")
	if typeof(balls) != TYPE_ARRAY:
		return

	# Transform global → this Control's local (canvas) space
	var inv_xform: Transform2D = get_global_transform_with_canvas().affine_inverse()

	for nd in balls:
		if nd == null or not (nd is Node2D):
			continue

		var n2d := nd as Node2D
		var gp: Vector2 = n2d.global_position
		# ✅ Use operator * on Transform2D to transform the point
		var local_p: Vector2 = inv_xform * gp

		var col: Color = n2d.get_meta("color") if n2d.has_meta("color") else Color(1, 1, 1, 1)
		_draw_circle(local_p, radius, col)

func _draw_circle(center: Vector2, r: float, col: Color) -> void:
	var pts: PackedVector2Array = []
	for i in segments:
		var a := i * TAU / float(segments)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)
