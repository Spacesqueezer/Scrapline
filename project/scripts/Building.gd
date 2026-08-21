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

var max_hp: float = 50.0
var hp: float = 50.0
var is_destroyed: bool = false
var hp_bar_node: Node2D

var emp_timer_node: Timer

func _ready():
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)

	hp_bar_node = Node2D.new()
	hp_bar_node.z_index = 20 # Гарантируем, что полоска будет поверх спрайта здания
	add_child(hp_bar_node)
	hp_bar_node.draw.connect(_on_hp_bar_draw)

	emp_timer_node = Timer.new()
	emp_timer_node.one_shot = true
	emp_timer_node.timeout.connect(_on_emp_timeout)
	add_child(emp_timer_node)

	if base_texture_path != "":
		# Важно: Godot импортирует SVG как текстуры.
		# В Godot 4 texture_filter по умолчанию часто Linear, оставим так.
		# Но если мы хотим использовать шейдер прокрутки UV, текстура должна иметь флаг Repeat.
		var tex = load(base_texture_path)
		sprite.texture = tex
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	hp = max_hp

func _draw():
	pass

func _on_hp_bar_draw():
	# Отрисовка эффекта EMP (желтый квадрат)
	if is_emped() and not is_destroyed:
		var emp_size = 80.0
		hp_bar_node.draw_rect(Rect2(-emp_size / 2.0, -emp_size / 2.0, emp_size, emp_size), Color(1.0, 1.0, 0.0, 0.4))

	if not is_destroyed and hp < max_hp and max_hp > 0:
		var hp_ratio = clamp(hp / max_hp, 0.0, 1.0)
		var bar_width = 60.0
		var bar_height = 8.0
		var offset_y = -55.0 # Поднимаем выше здания

		# Фон (Красный)
		hp_bar_node.draw_rect(Rect2(-bar_width / 2.0, offset_y, bar_width, bar_height), Color.RED)
		# Текущее HP (Зеленый)
		hp_bar_node.draw_rect(Rect2(-bar_width / 2.0, offset_y, bar_width * hp_ratio, bar_height), Color.GREEN)

func apply_emp(duration: float):
	if is_destroyed:
		return
	var current_time_left = emp_timer_node.time_left if not emp_timer_node.is_stopped() else 0.0
	emp_timer_node.start(max(current_time_left, duration))
	if hp_bar_node:
		hp_bar_node.queue_redraw()

func is_emped() -> bool:
	return emp_timer_node != null and not emp_timer_node.is_stopped()

func _on_emp_timeout():
	if hp_bar_node:
		hp_bar_node.queue_redraw()

func take_damage(amount: float):
	if is_destroyed:
		return

	hp -= amount
	if StatTracker:
		StatTracker.track_damage_taken(amount, false)

	if hp_bar_node:
		hp_bar_node.queue_redraw()
	if hp <= 0:
		hp = 0
		is_destroyed = true
		on_destroyed()

func on_destroyed():
	# Визуально "выключаем" здание
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)

	# Вызываем виртуальный метод для сброса состояния (ресурсы, патроны и т.д.) у наследников
	_reset_state()

# Виртуальный метод, который переопределяют дочерние классы (для сброса состояния при смерти)
func _reset_state():
	pass

func repair():
	is_destroyed = false
	hp = max_hp
	if emp_timer_node:
		emp_timer_node.stop()
	if hp_bar_node:
		hp_bar_node.queue_redraw()
	if sprite:
		sprite.modulate = Color.WHITE

func setup(p_data: ModuleData, p_grid_pos: Vector2i):
	data = p_data
	grid_position = p_grid_pos

func can_receive_payload(payload: Payload = null) -> bool:
	# Если здание уничтожено или замкнуто, оно ничего не принимает
	if is_destroyed or is_emped():
		return false
	# Base class defaults to true. Subclasses like Modifier or Conveyor should override.
	return true

func receive_payload(payload: Payload):
	# Base class logic. Override in subclasses.
	on_payload_received.emit(payload)

# Проверка, идет ли сейчас бой, чтобы здания не работали в режиме стройки
func is_combat_active() -> bool:
	if is_destroyed or is_emped():
		return false
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
