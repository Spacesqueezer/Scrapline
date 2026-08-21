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
var enemy_type_name: String = "Basic"

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
		if enemy_type_name == "Boss":
			# Босс настраивается в своем классе
			pass
		elif max_hp > 100.0:
			sprite.texture = load("res://assets/enemy_armored.svg")
			enemy_type_name = "Armored"
		elif speed > 80.0:
			sprite.texture = load("res://assets/enemy_swarm.svg")
			enemy_type_name = "Swarm"
		else:
			sprite.texture = load("res://assets/enemy_basic.svg")
			enemy_type_name = "Basic"

	if StatTracker:
		StatTracker.track_enemy_spawn(enemy_type_name)

	show()
	queue_redraw()

var attack_timer: float = 0.0
var attack_rate: float = 1.0
var attack_damage: float = 10.0
var target_building: Building = null
var attack_range: float = 60.0 # Дистанция атаки

func _process(delta):
	if not is_active:
		return

	var grid_manager = get_node_or_null("/root/Main/World2D/GridManager")

	# Поиск ближайшей живой цели, если текущей нет или она уничтожена
	if target_building == null or target_building.is_destroyed:
		target_building = _find_closest_building(grid_manager)

	# Если цель есть, проверяем дистанцию
	if target_building and not target_building.is_destroyed:
		var dist = global_position.distance_to(target_building.global_position)
		if dist <= attack_range:
			# В радиусе атаки - останавливаемся и бьем
			attack_timer += delta
			if attack_timer >= attack_rate:
				attack_timer = 0.0
				target_building.take_damage(attack_damage)
				# Небольшая визуальная обратная связь атаки врага
				var attack_dir = (target_building.global_position - global_position).normalized()
				global_position += attack_dir * 5
				var t = get_tree().create_timer(0.1)
				t.timeout.connect(func(): global_position -= attack_dir * 5)
			return
		else:
			# Движемся к цели
			move_direction = (target_building.global_position - global_position).normalized()

			# Поворот спрайта по направлению движения
			if sprite:
				sprite.rotation = move_direction.angle() - PI/2 # минус 90 градусов, т.к. изначально смотрит вниз
	else:
		# Если вообще нет зданий на карте (маловероятно), просто идем вниз
		move_direction = Vector2.DOWN
		if sprite:
			sprite.rotation = 0

	# Применяем движение
	global_position += move_direction * speed * delta

	# Если враг ушел за нижний край экрана
	if global_position.y > 1100:
		reach_base()

func _find_closest_building(grid_manager) -> Building:
	if not grid_manager:
		return null

	var closest_b: Building = null
	var min_dist = INF

	for key in grid_manager.grid:
		var b = grid_manager.grid[key]
		if b is Building and not b.is_destroyed:
			var dist = global_position.distance_to(b.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_b = b

	return closest_b

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
	if StatTracker:
		StatTracker.track_enemy_kill(enemy_type_name)
	on_death.emit(self)

func reach_base():
	is_active = false
	hide()
	on_reach_base.emit(self)
