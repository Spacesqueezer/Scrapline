class_name Enemy
extends Node2D

var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 50.0
var move_direction: Vector2 = Vector2.LEFT

var is_active: bool = false
signal on_death(enemy: Enemy)
signal on_reach_base(enemy: Enemy)

var sprite: Sprite2D

func _ready():
	sprite = Sprite2D.new()
	add_child(sprite)

func _draw():
	# Рисуем полоску HP над врагом (спрайт рисуется автоматически)
	if max_hp > 0:
		var hp_ratio = clamp(hp / max_hp, 0.0, 1.0)
		var bar_width = 40.0
		var bar_height = 6.0
		var offset_y = -35.0

		# Фон (Красный)
		draw_rect(Rect2(-bar_width / 2.0, offset_y, bar_width, bar_height), Color.RED)
		# Текущее HP (Зеленый)
		draw_rect(Rect2(-bar_width / 2.0, offset_y, bar_width * hp_ratio, bar_height), Color.GREEN)

func setup(start_pos: Vector2, p_hp: float, p_speed: float, dir: Vector2):
	global_position = start_pos
	hp = p_hp
	max_hp = p_hp
	speed = p_speed
	move_direction = dir
	is_active = true

	if sprite:
		if max_hp > 100.0:
			sprite.texture = load("res://assets/enemy_armored.svg")
		elif speed > 80.0:
			sprite.texture = load("res://assets/enemy_swarm.svg")
		else:
			sprite.texture = load("res://assets/enemy_basic.svg")

	show()
	queue_redraw()

func _process(delta):
	if not is_active:
		return

	global_position += move_direction * speed * delta

	# Проверка достижения базы (враг ушел за нижний край экрана, например Y > 1100)
	if global_position.y > 1100:
		reach_base()

func take_damage(amount: float, tags: Array[String]):
	if not is_active:
		return

	hp -= amount
	queue_redraw()

	# Создаем всплывающий текст урона
	var ft = FloatingText.new()
	var color = Color.WHITE
	if "Fire" in tags or "Explosive" in tags:
		color = Color.RED
	get_tree().current_scene.add_child(ft)
	ft.setup(str(int(amount)), global_position, color)

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
