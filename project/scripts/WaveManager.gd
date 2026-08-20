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

func start_wave(wave_num: int):
	is_wave_active = true
	enemies_to_spawn = 3 + wave_num * 2
	enemies_alive = enemies_to_spawn
	spawn_interval = max(0.5, 2.0 - (wave_num * 0.2))
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

	# Spawn somewhere offscreen to the right, random Y
	var random_y = randf_range(100.0, 500.0)
	enemy.setup(Vector2(800, random_y), 50.0, 60.0, Vector2.LEFT)

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
