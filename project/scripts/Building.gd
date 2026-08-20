class_name Building
extends Node2D

@export var data: ModuleData
var grid_position: Vector2i
var facing_direction: Vector2i = Vector2i.RIGHT # UP, DOWN, LEFT, RIGHT

# For receiving payload
signal on_payload_received(payload: Payload)
# For outputting payload
signal on_payload_output(payload: Payload, direction: Vector2i)

var base_color: Color = Color(0.5, 0.5, 0.5)

func _ready():
	queue_redraw()

func _draw():
	# Отрисовываем квадрат для здания (чуть меньше ячейки 100х100)
	var rect_size = 80.0
	var offset = -rect_size / 2.0
	var rect = Rect2(offset, offset, rect_size, rect_size)
	draw_rect(rect, base_color, true)

	# Отрисовываем "носик" (выход), чтобы понимать направление
	if facing_direction != Vector2i.ZERO:
		var dir = Vector2(facing_direction)
		draw_line(Vector2.ZERO, dir * (rect_size / 2.0), Color.YELLOW, 3.0)

func setup(p_data: ModuleData, p_grid_pos: Vector2i):
	data = p_data
	grid_position = p_grid_pos
	queue_redraw()

func receive_payload(payload: Payload):
	# Base class logic. Override in subclasses.
	on_payload_received.emit(payload)

# Проверка, идет ли сейчас бой, чтобы здания не работали в режиме стройки
func is_combat_active() -> bool:
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm and gm.current_state == gm.GameState.COMBAT:
		return true
	return false

func rotate_building(dir: Vector2i = Vector2i.ZERO):
	if dir == Vector2i.ZERO:
		# Поворот на 90 градусов по часовой стрелке, если направление не передано
		if facing_direction == Vector2i.UP:
			facing_direction = Vector2i.RIGHT
		elif facing_direction == Vector2i.RIGHT:
			facing_direction = Vector2i.DOWN
		elif facing_direction == Vector2i.DOWN:
			facing_direction = Vector2i.LEFT
		elif facing_direction == Vector2i.LEFT:
			facing_direction = Vector2i.UP
	else:
		facing_direction = dir

	# Мы не вращаем саму ноду (чтобы UI текст не крутился), мы перерисовываем указатель
	queue_redraw()
