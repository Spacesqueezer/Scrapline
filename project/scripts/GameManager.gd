class_name GameManager
extends Node

enum GameState {
	BUILD,
	COMBAT,
	REWARD,
	GAME_OVER
}

var current_state: GameState = GameState.BUILD
var current_wave: int = 0
var base_hp: int = 100

# Signals
signal state_changed(new_state: GameState)
signal wave_started(wave_num: int)
signal base_damaged(amount: int, current_hp: int)

@onready var wave_manager = $"../WaveManager"
@onready var grid_manager = $"../World2D/GridManager"
@onready var build_menu = $"../UILayer/BuildMenu"
@onready var reward_menu = $"../UILayer/RewardMenu"

func _ready():
	print("GameManager initialized.")

	# Connect UI Signals if possible
	if build_menu:
		build_menu.on_start_wave_pressed.connect(_on_ui_start_wave)
		build_menu.on_building_selected.connect(_on_ui_building_selected)
		build_menu.on_test_scenario_pressed.connect(_on_ui_test_scenario)

		# Connect to own signals to update UI
		state_changed.connect(func(state):
			var state_name = GameState.keys()[state]
			build_menu.update_state_label(state_name)
		)
		wave_started.connect(func(w): build_menu.update_wave_label(w))
		base_damaged.connect(func(amt, hp): build_menu.update_base_hp(hp))

	if reward_menu:
		reward_menu.on_reward_selected.connect(_on_reward_selected)

	# Delay initial state to let UI load
	call_deferred("change_state", GameState.BUILD)

func _on_ui_start_wave():
	if current_state == GameState.BUILD:
		change_state(GameState.COMBAT)

func _on_ui_building_selected(b_type: String):
	if current_state == GameState.BUILD and grid_manager:
		grid_manager.set_selected_building(b_type)

func _on_reward_selected(reward_id: String):
	print("Player selected reward: ", reward_id)

	if reward_id != "None" and build_menu:
		build_menu.unlock_building(reward_id)

	if reward_menu:
		reward_menu.hide()

	change_state(GameState.BUILD)

func _on_ui_test_scenario():
	if current_state != GameState.BUILD or not grid_manager:
		return

	# Очищаем сетку
	grid_manager.clear_grid()

	# Ставим 1 очень медленный Miner (1 патрон в 3 секунды)
	grid_manager.set_selected_building("Miner")
	grid_manager.attempt_build(Vector2i(3, 8))
	var slow_miner = grid_manager.get_module_at(Vector2i(3, 8))
	if slow_miner and slow_miner is Miner:
		slow_miner.produce_time = 3.0
		slow_miner.facing_direction = Vector2i.UP

	# Ставим пушку, которая хочет стрелять 10 раз в секунду
	grid_manager.set_selected_building("Weapon")
	grid_manager.attempt_build(Vector2i(3, 7))
	var fast_weapon = grid_manager.get_module_at(Vector2i(3, 7))
	if fast_weapon and fast_weapon is WeaponBuilding:
		var fast_w_data = WeaponData.new()
		fast_w_data.fire_rate = 10.0
		fast_w_data.range = 500.0
		fast_weapon.weapon_data = fast_w_data
		fast_weapon.facing_direction = Vector2i.UP

	# Заставляем WaveManager спавнить толпу Swarm
	if wave_manager:
		wave_manager._force_test_wave = true

	# Снимаем выделение
	grid_manager.set_selected_building("")

	print("Test scenario setup complete. Slow Miner + Fast Weapon.")

func change_state(new_state: GameState):
	current_state = new_state
	state_changed.emit(current_state)

	if grid_manager:
		grid_manager.can_build = (current_state == GameState.BUILD)

	match current_state:
		GameState.BUILD:
			print("Phase: BUILD")
		GameState.COMBAT:
			print("Phase: COMBAT")
			start_wave()
		GameState.REWARD:
			print("Phase: REWARD")
			if wave_manager:
				wave_manager._force_test_wave = false

			if reward_menu:
				var unlocked = build_menu.unlocked_buildings if build_menu else []
				reward_menu.generate_and_show_draft(unlocked)
			else:
				call_deferred("change_state", GameState.BUILD)
		GameState.GAME_OVER:
			print("Phase: GAME OVER")
			var game_over_menu = get_node_or_null("/root/Main/UILayer/GameOverMenu")
			if game_over_menu:
				game_over_menu.show()

func start_wave():
	current_wave += 1
	wave_started.emit(current_wave)
	print("Starting Wave: ", current_wave)
	if wave_manager:
		wave_manager.start_wave(current_wave)

func damage_base(amount: int):
	base_hp -= amount
	base_damaged.emit(amount, base_hp)
	if base_hp <= 0:
		change_state(GameState.GAME_OVER)

func get_closest_enemy(pos: Vector2, max_range: float) -> Node2D:
	if wave_manager:
		return wave_manager.get_closest_enemy(pos, max_range)
	return null
