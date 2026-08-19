class_name Projectile
extends Node2D

var payload: Payload
var target: Node2D
var speed: float = 300.0
var is_active: bool = false
var direction: Vector2 = Vector2.ZERO

signal on_hit(projectile: Projectile)

func setup(start_pos: Vector2, p_target: Node2D, p_payload: Payload):
	global_position = start_pos
	target = p_target
	payload = p_payload
	is_active = true
	show()

	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()

func _process(delta):
	if not is_active:
		return

	# Homing or straight line. Let's do straight line towards last known direction for now.
	if target and is_instance_valid(target) and target.is_active:
		direction = (target.global_position - global_position).normalized()

	global_position += direction * speed * delta

	# Hit detection (mock simple distance check)
	if target and is_instance_valid(target) and target.is_active:
		if global_position.distance_to(target.global_position) < 20.0:
			hit(target)
	else:
		# Target died before bullet arrived
		# In a real game, let it fly off screen, but for now we just deactivate after a while
		# Need screen bounds check.
		if global_position.x < -100 or global_position.x > 1000 or global_position.y < -100 or global_position.y > 1500:
			deactivate()

func hit(hit_target: Node2D):
	if hit_target.has_method("take_damage"):
		hit_target.take_damage(payload.base_damage, payload.tags)
	deactivate()

func deactivate():
	is_active = false
	hide()
	on_hit.emit(self)
