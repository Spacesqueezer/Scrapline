class_name WaveManager
extends Node

@onready var game_manager = get_node("/root/Main/GameManager")
@onready var pool_manager = get_node("/root/Main/PoolManager")
var is_wave_active: bool = false
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

var active_enemies: Array[Enemy] = []

func _ready():
	print("WaveManager initialized.")

var _force_test_wave: bool = false

func start_wave(wave_num: int):
	is_wave_active = true
	if _force_test_wave:
		enemies_to_spawn = 20
		spawn_interval = 0.5
	else:
		enemies_to_spawn = 3 + wave_num * 2
		spawn_interval = max(0.5, 2.0 - (wave_num * 0.2))

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
	var enemy = null
	if pool_manager:
		enemy = pool_manager.get_enemy()
	else:
		enemy = Enemy.new()
		add_child(enemy)

	# Спавн за верхним краем экрана, выравнивание по столбцам (колонкам) сетки
	var grid_manager = get_node("/root/Main/World2D/GridManager")
	var cell_size = 100
	var grid_offset = Vector2.ZERO
	if grid_manager:
		cell_size = grid_manager.cell_size
		grid_offset = grid_manager.global_position

	# Выбираем случайную колонку (от 0 до 6 для ширины 7)
	var random_col = randi() % 7
	var spawn_x = grid_offset.x + (random_col * cell_size) + (cell_size / 2.0)
	var spawn_y = -100.0 # Выше экрана

	# Randomized enemy type logic (Basic, Swarm, Armored)
	var e_type = randi() % 10
	if _force_test_wave:
		e_type = 7 # Force Swarm
	elif game_manager and game_manager.current_wave < 2:
		e_type = 0 # First waves only basic enemies

	if e_type < 6:
		# Basic Enemy: 50 HP, 60 Speed
		enemy.setup(Vector2(spawn_x, spawn_y), 50.0, 60.0, Vector2.DOWN)
	elif e_type < 8:
		# Swarm Enemy: 20 HP, 120 Speed
		enemy.setup(Vector2(spawn_x, spawn_y), 20.0, 120.0, Vector2.DOWN)
	else:
		# Armored Enemy: 150 HP, 30 Speed
		enemy.setup(Vector2(spawn_x, spawn_y), 150.0, 30.0, Vector2.DOWN)

	if not enemy.on_death.is_connected(_on_enemy_death):
		enemy.on_death.connect(_on_enemy_death)
	if not enemy.on_reach_base.is_connected(_on_enemy_reach_base):
		enemy.on_reach_base.connect(_on_enemy_reach_base)

	active_enemies.append(enemy)

func _on_enemy_death(enemy: Enemy):
	active_enemies.erase(enemy)
	enemies_alive -= 1
	check_wave_end()
	if not pool_manager:
		enemy.queue_free()

func _on_enemy_reach_base(enemy: Enemy):
	active_enemies.erase(enemy)
	enemies_alive -= 1
	if game_manager:
		game_manager.damage_base(10)
	check_wave_end()
	if not pool_manager:
		enemy.queue_free()

func check_wave_end():
	if enemies_to_spawn <= 0 and enemies_alive <= 0:
		is_wave_active = false
		print("Wave complete!")
		if game_manager:
			game_manager.change_state(GameManager.GameState.REWARD)

func get_closest_enemy(pos: Vector2, max_range: float) -> Node2D:
	var closest: Node2D = null
	var min_dist = max_range
	for e in active_enemies:
		if e.is_active:
			var dist = e.global_position.distance_to(pos)
			if dist < min_dist:
				min_dist = dist
				closest = e
	return closest
