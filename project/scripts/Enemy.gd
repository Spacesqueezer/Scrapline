class_name Enemy
extends Node2D

var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 50.0
var move_direction: Vector2 = Vector2.LEFT

var is_active: bool = false
signal on_death(enemy: Enemy)
signal on_reach_base(enemy: Enemy)

func setup(start_pos: Vector2, p_hp: float, p_speed: float, dir: Vector2):
	global_position = start_pos
	hp = p_hp
	max_hp = p_hp
	speed = p_speed
	move_direction = dir
	is_active = true
	show()

func _process(delta):
	if not is_active:
		return

	global_position += move_direction * speed * delta

	# Simple base reach check (if it goes too far left)
	if global_position.x < 50: # Mock coordinate for base
		reach_base()

func take_damage(amount: float, tags: Array[String]):
	if not is_active:
		return

	hp -= amount
	if hp <= 0:
		die()

func die():
	is_active = false
	hide()
	on_death.emit(self)

func reach_base():
	is_active = false
	hide()
	on_reach_base.emit(self)
