class_name Projectile
extends Node2D

var payload: Payload
var target # Duck typing, может быть Enemy или любой Node2D со здоровьем
var speed: float = 300.0
var is_active: bool = false
var direction: Vector2 = Vector2.ZERO

signal on_hit(projectile: Projectile)

func _ready():
	queue_redraw()

func _draw():
	var proj_color = Color.ORANGE
	var proj_size = 8.0

	if payload:
		if "Fire" in payload.tags or "Explosive" in payload.tags:
			proj_color = Color.RED
			proj_size = 14.0 # Снаряд становится больше, если прошел через модификатор

	draw_circle(Vector2.ZERO, proj_size, proj_color)

func setup(start_pos: Vector2, p_target, p_payload: Payload):
	global_position = start_pos
	target = p_target
	payload = p_payload
	is_active = true
	show()

	# Снаряд летит строго по прямой к той точке, где был враг в момент выстрела.
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		direction = Vector2.RIGHT

	queue_redraw()

func _process(delta):
	if not is_active:
		return

	# Движение строго по прямой
	global_position += direction * speed * delta

	# Универсальная проверка столкновений (со всеми активными врагами)
	var wave_manager = get_node_or_null("/root/Main/WaveManager")
	if wave_manager:
		var hit_target = null
		for enemy in wave_manager.active_enemies:
			if enemy.is_active and global_position.distance_to(enemy.global_position) < 25.0:
				hit_target = enemy
				break

		if hit_target:
			hit(hit_target)
			return

	# Удаление при вылете за экран
	if global_position.x < -100 or global_position.x > 1000 or global_position.y < -100 or global_position.y > 1500:
		deactivate()

func hit(hit_target):
	if hit_target.has_method("take_damage"):
		hit_target.take_damage(payload.base_damage, payload.tags)
	deactivate()

func deactivate():
	is_active = false
	hide()
	on_hit.emit(self)
