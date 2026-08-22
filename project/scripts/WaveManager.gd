extends Node
class_name WaveManager

var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0

var active_enemies: Array[Node] = []
var is_wave_active: bool = false

@onready var pool_manager = get_node_or_null("/root/Main/PoolManager")
@onready var game_manager = get_node_or_null("/root/Main/GameManager")

func _ready():
	print("WaveManager initialized.")

var _force_test_wave: bool = false

func start_wave(wave_num: int):
	is_wave_active = true
	if StatTracker:
		StatTracker.update_wave(wave_num)

	if _force_test_wave:
		enemies_to_spawn = 20
		spawn_interval = 0.5
	# Каждая 5-я волна — волна с боссом
	elif wave_num > 0 and wave_num % 5 == 0:
		enemies_to_spawn = 1 + floor(wave_num / 10.0)
		spawn_interval = 1.0 # Спавним его почти сразу
	else:
		enemies_to_spawn = 3 + wave_num * 3
		spawn_interval = max(0.2, 2.0 - (wave_num * 0.2))

	enemies_alive = enemies_to_spawn
	spawn_timer = 0.0
	print("Wave ", wave_num, " started. Enemies to spawn: ", enemies_to_spawn)

func _process(delta):
	if not is_wave_active:
		return

	if enemies_to_spawn > 0:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_enemy()
			enemies_to_spawn -= 1

func spawn_enemy():
	var grid_manager = get_node("/root/Main/World2D/GridManager")
	var cell_size = 100
	var grid_offset = Vector2.ZERO
	if grid_manager:
		cell_size = grid_manager.cell_size
		grid_offset = grid_manager.global_position

	var random_col = randi() % 7
	var spawn_x = grid_offset.x + (random_col * cell_size) + (cell_size / 2.0)
	var spawn_y = -100.0 # Выше экрана

	# Проверка на спавн босса
	var is_boss_wave = false
	var diff_mult = 1.0
	var dmg_mult = 1.0
	if game_manager:
		if game_manager.current_wave > 0 and game_manager.current_wave % 5 == 0 and not _force_test_wave:
			is_boss_wave = true
		diff_mult = 1.0 + (game_manager.current_wave * 0.5)
		dmg_mult = 1.0 + (game_manager.current_wave * 0.2)

	var enemy = null
	if is_boss_wave:
		enemy = BossEnemy.new()
		add_child(enemy)
		enemy.enemy_type_name = "Boss"
		enemy.setup(Vector2(spawn_x, spawn_y), 500.0 * diff_mult, 20.0 + (game_manager.current_wave * 2.0), Vector2.DOWN)
		enemy.attack_damage = 25.0 * dmg_mult
	else:
		if pool_manager:
			enemy = pool_manager.get_enemy()
		else:
			enemy = Enemy.new()
			add_child(enemy)

		var e_type = randi() % 10
		if _force_test_wave:
			e_type = 7 # Force Swarm
		elif game_manager and game_manager.current_wave < 2:
			e_type = 0 # First waves only basic enemies

		if e_type < 6:
			# Basic Enemy
			enemy.enemy_type_name = "Basic"
			enemy.setup(Vector2(spawn_x, spawn_y), 50.0 * diff_mult, 60.0, Vector2.DOWN)
			enemy.attack_damage = 5.0 * dmg_mult
		elif e_type < 8:
			# Swarm Enemy
			enemy.enemy_type_name = "Swarm"
			enemy.setup(Vector2(spawn_x, spawn_y), 20.0 * diff_mult, 120.0 + (game_manager.current_wave * 2.0), Vector2.DOWN)
			enemy.attack_damage = 2.0 * dmg_mult
		else:
			# Armored Enemy
			enemy.enemy_type_name = "Armored"
			enemy.setup(Vector2(spawn_x, spawn_y), 150.0 * diff_mult, 30.0, Vector2.DOWN)
			enemy.attack_damage = 15.0 * dmg_mult

	if not enemy.on_death.is_connected(_on_enemy_death):
		enemy.on_death.connect(_on_enemy_death)
	if not enemy.on_reach_base.is_connected(_on_enemy_reach_base):
		enemy.on_reach_base.connect(_on_enemy_reach_base)

	active_enemies.append(enemy)

func _on_enemy_death(enemy: Enemy):
	active_enemies.erase(enemy)
	enemies_alive -= 1
	check_wave_end()

	if enemy is BossEnemy:
		enemy.queue_free()
	elif not pool_manager:
		enemy.queue_free()

func _on_enemy_reach_base(enemy: Enemy):
	active_enemies.erase(enemy)
	enemies_alive -= 1

	# Наносим урон Ядру за пропущенного врага (штраф)
	var grid_manager = get_node_or_null("/root/Main/World2D/GridManager")
	if grid_manager and grid_manager.core_building:
		# Штраф скалируется от волны
		var penalty = 10.0 + (game_manager.current_wave if game_manager else 0) * 2.0
		grid_manager.core_building.take_damage(penalty)

	check_wave_end()

	if enemy is BossEnemy:
		enemy.queue_free()
	elif not pool_manager:
		enemy.queue_free()

func check_wave_end():
	if enemies_to_spawn <= 0 and enemies_alive <= 0:
		is_wave_active = false
		print("Wave complete!")
		if game_manager:
			# Если ядро было уничтожено, стейт уже GAME_OVER, не переключаемся на REWARD
			if game_manager.current_state != GameManager.GameState.GAME_OVER:
				game_manager.change_state(GameManager.GameState.REWARD)

func get_closest_enemy_in_arc(pos: Vector2, max_range: float, face_dir: Vector2, arc_degrees: float) -> Node2D:
	var closest: Node2D = null
	var min_dist = max_range
	var arc_rad = deg_to_rad(arc_degrees)
	var half_arc = arc_rad / 2.0

	for e in active_enemies:
		if not e.is_active:
			continue

		var dist = pos.distance_to(e.global_position)
		if dist <= max_range:
			# Проверяем угол
			var dir_to_enemy = (e.global_position - pos).normalized()
			var angle_to_enemy = face_dir.angle_to(dir_to_enemy)

			if abs(angle_to_enemy) <= half_arc:
				if dist < min_dist:
					min_dist = dist
					closest = e

	return closest

# Для обратной совместимости или пушек на 360 градусов
func get_closest_enemy(pos: Vector2, max_range: float) -> Node2D:
	return get_closest_enemy_in_arc(pos, max_range, Vector2.UP, 360.0)

func raycast_enemy(start_pos: Vector2, direction: Vector2, max_range: float, hit_radius: float = 30.0) -> Dictionary:
	var end_pos = start_pos + direction * max_range
	var closest_target = null
	var closest_dist = max_range

	for e in active_enemies:
		if not e.is_active:
			continue

		# Проецируем позицию врага на линию луча, чтобы найти кратчайшее расстояние от центра врага до луча
		var to_enemy = e.global_position - start_pos
		var projection_length = to_enemy.dot(direction)

		# Если враг позади точки старта или дальше максимальной дальности, пропускаем
		if projection_length < 0 or projection_length > max_range:
			continue

		# Ближайшая точка на луче к центру врага
		var closest_point_on_ray = start_pos + direction * projection_length
		var dist_to_ray = closest_point_on_ray.distance_to(e.global_position)

		# Если расстояние меньше радиуса попадания (hitbox), считаем это попаданием
		if dist_to_ray <= hit_radius:
			if projection_length < closest_dist:
				closest_dist = projection_length
				closest_target = e
				end_pos = closest_point_on_ray

	return {
		"hit": closest_target != null,
		"target": closest_target,
		"point": end_pos
	}
