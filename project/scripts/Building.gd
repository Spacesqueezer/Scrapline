class_name Building
extends Node2D

@export var data: ModuleData
var grid_position: Vector2i
var facing_direction: Vector2i = Vector2i.RIGHT # UP, DOWN, LEFT, RIGHT

# For receiving payload
signal on_payload_received(payload: Payload)
# For outputting payload
signal on_payload_output(payload: Payload, direction: Vector2i)

var sprite: Sprite2D
var base_texture_path: String = ""

func _ready():
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)

	if base_texture_path != "":
		# Важно: Godot импортирует SVG как текстуры.
		# В Godot 4 texture_filter по умолчанию часто Linear, оставим так.
		# Но если мы хотим использовать шейдер прокрутки UV, текстура должна иметь флаг Repeat.
		var tex = load(base_texture_path)
		sprite.texture = tex
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func setup(p_data: ModuleData, p_grid_pos: Vector2i):
	data = p_data
	grid_position = p_grid_pos

func can_receive_payload() -> bool:
	# Base class defaults to true. Subclasses like Modifier or Conveyor should override.
	return true

func receive_payload(payload: Payload):
	# Base class logic. Override in subclasses.
	on_payload_received.emit(payload)

# Проверка, идет ли сейчас бой, чтобы здания не работали в режиме стройки
func is_combat_active() -> bool:
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm and gm.current_state == GameManager.GameState.COMBAT:
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

	# Вращаем спрайт
	if sprite:
		if facing_direction == Vector2i.UP:
			sprite.rotation_degrees = -90
		elif facing_direction == Vector2i.RIGHT:
			sprite.rotation_degrees = 0
		elif facing_direction == Vector2i.DOWN:
			sprite.rotation_degrees = 90
		elif facing_direction == Vector2i.LEFT:
			sprite.rotation_degrees = 180
