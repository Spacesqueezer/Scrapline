class_name SplitterBuilding
extends Building

var toggle: bool = false
var processing_time: float = 0.2
var current_payload: Payload = null
var timer: float = 0.0
var is_processing: bool = false

func _ready():
	base_color = Color(0.8, 0.8, 0.2) # Желтый для сплиттера

func receive_payload(payload: Payload):
	if is_processing or current_payload != null:
		return

	super(payload)
	current_payload = payload
	is_processing = true
	timer = 0.0

func _process(delta):
	if is_processing and is_combat_active():
		timer += delta
		if timer >= processing_time:
			finish_processing()

func finish_processing():
	is_processing = false
	var out_p = current_payload
	current_payload = null

	# Вычисляем направления влево и вправо относительно текущего facing_direction
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

	var out_dir = left_dir if toggle else right_dir
	toggle = not toggle # Переключаем для следующего ресурса

	on_payload_output.emit(out_p, out_dir)

func _draw():
	# Рисуем базовый квадрат
	var rect_size = 80.0
	var offset = -rect_size / 2.0
	var rect = Rect2(offset, offset, rect_size, rect_size)
	draw_rect(rect, base_color, true)

	# Сплиттер рисует две линии-указателя, чтобы было понятно, куда он отдает
	var dir1 = Vector2i.ZERO
	var dir2 = Vector2i.ZERO
	if facing_direction == Vector2i.UP or facing_direction == Vector2i.DOWN:
		dir1 = Vector2i.LEFT
		dir2 = Vector2i.RIGHT
	else:
		dir1 = Vector2i.UP
		dir2 = Vector2i.DOWN

	draw_line(Vector2.ZERO, Vector2(dir1) * (rect_size / 2.0), Color.YELLOW, 3.0)
	draw_line(Vector2.ZERO, Vector2(dir2) * (rect_size / 2.0), Color.YELLOW, 3.0)
