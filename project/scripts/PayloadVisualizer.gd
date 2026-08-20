class_name PayloadVisualizer
extends Node2D

var start_pos: Vector2
var end_pos: Vector2
var t: float = 0.0
var travel_time: float = 0.3
var is_active: bool = false
var payload: Payload

func setup(p_payload: Payload, p_start: Vector2, p_end: Vector2):
	payload = p_payload
	start_pos = p_start
	end_pos = p_end
	global_position = p_start
	t = 0.0
	is_active = true
	show()
	queue_redraw()

func _process(delta):
	if not is_active:
		return

	t += delta / travel_time
	if t >= 1.0:
		is_active = false
		hide()
		# Return to pool or just queue_free for simplicity in MVP
		queue_free()
	else:
		global_position = start_pos.lerp(end_pos, t)

func _draw():
	if not payload:
		return

	var size = 6.0
	var color = Color.GRAY

	if "Fire" in payload.tags or "Explosive" in payload.tags:
		color = Color.RED
		size = 10.0

	draw_rect(Rect2(-size/2, -size/2, size, size), color, true)
