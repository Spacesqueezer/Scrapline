class_name SplitterBuilding
extends Building

var toggle: bool = false
var processing_time: float = 0.2
var current_payload: Payload = null
var timer: float = 0.0
var is_processing: bool = false

func _init():
	base_texture_path = "res://assets/splitter.svg"

func receive_payload(payload: Payload):
	if is_processing or current_payload != null:
		return

	super(payload)
	current_payload = payload
	is_processing = true
	timer = 0.0

func can_receive_payload() -> bool:
	return not is_processing and current_payload == null

func _process(delta):
	if is_processing and is_combat_active():
		timer += delta
		if timer >= processing_time:
			try_finish_processing()

func _reset_state():
	current_payload = null
	is_processing = false

func try_finish_processing():
	# Получаем ссылки на соседей через GridManager
	var gm = get_node_or_null("/root/Main/World2D/GridManager")
	if not gm:
		return

	var left_dir = Vector2i.ZERO
	var right_dir = Vector2i.ZERO

	if facing_direction == Vector2i.UP:
		left_dir = Vector2i.LEFT
		right_dir = Vector2i.RIGHT
	elif facing_direction == Vector2i.RIGHT:
		left_dir = Vector2i.UP
		right_dir = Vector2i.DOWN
	elif facing_direction == Vector2i.DOWN:
		left_dir = Vector2i.RIGHT
		right_dir = Vector2i.LEFT
	elif facing_direction == Vector2i.LEFT:
		left_dir = Vector2i.DOWN
		right_dir = Vector2i.UP

	var b_left = gm.get_module_at(grid_position + left_dir)
	var b_right = gm.get_module_at(grid_position + right_dir)

	var can_go_left = b_left != null and b_left.has_method("can_receive_payload") and b_left.can_receive_payload()
	var can_go_right = b_right != null and b_right.has_method("can_receive_payload") and b_right.can_receive_payload()

	# Если оба забиты или отсутствуют — сплиттер забивается, ресурс ждет
	if not can_go_left and not can_go_right:
		return

	var out_dir = Vector2i.ZERO

	# Если свободен только один — шлем туда. Если оба, то чередуем.
	if can_go_left and not can_go_right:
		out_dir = left_dir
	elif can_go_right and not can_go_left:
		out_dir = right_dir
	else:
		out_dir = left_dir if toggle else right_dir
		toggle = not toggle

	is_processing = false
	var out_p = current_payload
	current_payload = null
	timer = 0.0

	on_payload_output.emit(out_p, out_dir)
