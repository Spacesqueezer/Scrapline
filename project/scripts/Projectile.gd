class_name Projectile
extends Node2D

var payload: Payload
var start_point: Vector2
var end_point: Vector2
var is_active: bool = false
var lifetime: float = 0.1 # Время видимости трассера
var current_time: float = 0.0

# Переменная направления (используется для промахов/дробовика)
var direction: Vector2 = Vector2.RIGHT

signal on_hit(projectile: Projectile)

func _ready():
	queue_redraw()

func _draw():
	if not is_active:
		return

	var proj_color = Color.ORANGE
	var proj_thickness = 2.0

	if payload:
		if "Fire" in payload.tags or "Explosive" in payload.tags:
			proj_color = Color.RED
			proj_thickness = 5.0

	# Уменьшаем прозрачность (alpha) по мере исчезновения трассера
	proj_color.a = 1.0 - (current_time / lifetime)

	# Рисуем линию (трассер) в локальных координатах
	draw_line(Vector2.ZERO, end_point - start_point, proj_color, proj_thickness)

func setup(p_start_pos: Vector2, p_target, p_payload: Payload):
	global_position = p_start_pos
	start_point = p_start_pos
	payload = p_payload
	is_active = true
	current_time = 0.0
	show()

	# Хитскан: мгновенно находим точку попадания и наносим урон
	if p_target and is_instance_valid(p_target):
		end_point = p_target.global_position
		# Наносим урон мгновенно
		if p_target.has_method("take_damage"):
			p_target.take_damage(payload.base_damage, payload.tags)
	else:
		# Если цели нет, летим вперед (с учетом direction, который мог быть передан извне, например, от дробовика)
		end_point = start_point + direction * 500.0

	queue_redraw()

func _process(delta):
	if not is_active:
		return

	current_time += delta
	queue_redraw()

	if current_time >= lifetime:
		deactivate()

func deactivate():
	is_active = false
	hide()
	on_hit.emit(self)
