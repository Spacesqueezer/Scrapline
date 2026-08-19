class_name MockTestScript
extends Node

@onready var grid_manager: GridManager = $"../World2D/GridManager"
@onready var game_manager: GameManager = $"../GameManager"

func _ready():
	print("--- Running Mock Test ---")
	call_deferred("run_test")

func run_test():
	# 1. Create a Miner
	var miner = Miner.new()
	miner.produce_time = 1.0
	miner.facing_direction = Vector2i.RIGHT
	grid_manager.place_module(Vector2i(2, 4), miner)

	# 2. Create a Modifier
	var modifier = ModifierBuilding.new()
	var mod_data = ModifierData.new()
	var tags: Array[String] = ["Explosive", "Fire"]
	mod_data.tags_to_add = tags
	mod_data.stat_multipliers = {"damage": 2.0}
	modifier.modifier_data = mod_data
	modifier.facing_direction = Vector2i.RIGHT
	grid_manager.place_module(Vector2i(3, 4), modifier)

	# 3. Create a Weapon
	var weapon = WeaponBuilding.new()
	var w_data = WeaponData.new()
	w_data.fire_rate = 2.0
	w_data.range = 500.0
	weapon.weapon_data = w_data
	weapon.facing_direction = Vector2i.RIGHT

	# Connect weapon fire to our mock bullet spawner
	weapon.on_fire.connect(_on_weapon_fire)
	grid_manager.place_module(Vector2i(4, 4), weapon)

	# 4. Create a mock target
	var dummy_enemy = Enemy.new()
	dummy_enemy.setup(Vector2(600, 250), 100, 0, Vector2.LEFT) # Stationary for now
	add_child(dummy_enemy)

	# Register mock enemy to game manager so weapon can find it
	game_manager.set_meta("mock_target", dummy_enemy)

	print("Test setup complete. Miner at (2,4), Modifier at (3,4), Weapon at (4,4).")

func _on_weapon_fire(payload: Payload, start_pos: Vector2, target: Node2D):
	print(">>> BANG! Weapon fired!")
	print("Payload tags: ", payload.tags)
	print("Payload damage: ", payload.base_damage)

	if target:
		# Создаем снаряд, который физически полетит к цели
		var proj = Projectile.new()
		add_child(proj)
		proj.setup(start_pos, target, payload)
