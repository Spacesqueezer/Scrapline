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
var max_energy: int = 50
var current_energy: int = 50

# Ин-ран баффы (Roguelite модификаторы, действующие до Game Over)
var run_modifiers: Dictionary = {
	"dmg_multiplier": 1.0,
	"fire_rate_multiplier": 1.0,
	"pierce_chance": 0.0
}

# Signals
signal state_changed(new_state: GameState)
signal wave_started(wave_num: int)
signal energy_changed(current: int, max: int)

@onready var wave_manager = $"../WaveManager"
@onready var grid_manager = $"../World2D/GridManager"
@onready var build_menu = $"../UILayer/BuildMenu"
@onready var reward_menu = $"../UILayer/RewardMenu"

func _ready():
	print("GameManager initialized.")
	if StatTracker:
		StatTracker.start_run()

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
		energy_changed.connect(func(c, m): build_menu.update_energy(c, m))

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

	if reward_id != "None":
		apply_run_modifier(reward_id)

	if reward_menu:
		reward_menu.hide()

	change_state(GameState.BUILD)

func apply_run_modifier(reward_id: String):
	match reward_id:
		"dmg_up":
			run_modifiers["dmg_multiplier"] += 0.2
			print("Run Modifier: Damage +20%. Total Multiplier: ", run_modifiers["dmg_multiplier"])
		"fire_rate_up":
			run_modifiers["fire_rate_multiplier"] += 0.15
			print("Run Modifier: Fire Rate +15%. Total Multiplier: ", run_modifiers["fire_rate_multiplier"])
		"pierce_chance":
			run_modifiers["pierce_chance"] += 0.10
			print("Run Modifier: Pierce Chance +10%. Total: ", run_modifiers["pierce_chance"])
		"core_hp":
			if grid_manager and grid_manager.core_building:
				grid_manager.core_building.max_hp += 50
				grid_manager.core_building.hp += 50
				grid_manager.core_building.queue_redraw()
				print("Run Modifier: Core HP +50. New Max: ", grid_manager.core_building.max_hp)

func _on_ui_test_scenario():
	if current_state != GameState.BUILD or not grid_manager:
		return

	# Очищаем сетку
	grid_manager.clear_grid()

	# Ставим Майнер
	grid_manager.set_selected_building("Miner")
	grid_manager.attempt_build(Vector2i(3, 8))
	var slow_miner = grid_manager.get_module_at(Vector2i(3, 8))
	if slow_miner and slow_miner is Miner:
		slow_miner.produce_time = 1.0
		slow_miner.facing_direction = Vector2i.UP

	# Ставим Процессор
	grid_manager.set_selected_building("Processor")
	grid_manager.attempt_build(Vector2i(3, 7))
	var proc = grid_manager.get_module_at(Vector2i(3, 7))
	if proc and proc is ProcessorBuilding:
		proc.facing_direction = Vector2i.UP

	# Ставим Пушку
	grid_manager.set_selected_building("Weapon")
	grid_manager.attempt_build(Vector2i(3, 6))
	var fast_weapon = grid_manager.get_module_at(Vector2i(3, 6))
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

	print("Test scenario setup complete: Miner -> Processor -> Weapon.")

func change_state(new_state: GameState):
	print("[GameManager] change_state called, from: ", current_state, " to: ", new_state)
	current_state = new_state
	state_changed.emit(current_state)

	if grid_manager:
		grid_manager.can_build = (current_state == GameState.BUILD)

	match current_state:
		GameState.BUILD:
			print("Phase: BUILD")
			max_energy += 20
			current_energy += 20
			energy_changed.emit(current_energy, max_energy)
			if grid_manager:
				for key in grid_manager.grid.keys():
					var building = grid_manager.grid[key] as Building
					if building and building.has_method("repair"):
						building.repair()
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

			# Начисляем награду за забег в SaveManager (10 скрапа за каждую волну)
			if SaveManager:
				var scrap_reward = current_wave * 10
				SaveManager.add_scrap(scrap_reward)
				SaveManager.update_max_wave(current_wave)
				print("Saved meta progress. Awarded ", scrap_reward, " scrap.")

			var game_over_menu = get_node_or_null("/root/Main/UILayer/GameOverMenu")
			if game_over_menu:
				game_over_menu.show()

func start_wave():
	current_wave += 1
	wave_started.emit(current_wave)
	print("Starting Wave: ", current_wave)
	if wave_manager:
		wave_manager.start_wave(current_wave)

# Больше не используется (враги теперь атакуют Ядро напрямую в Enemy.gd)
# Оставлено для обратной совместимости, если понадобится
func damage_base(amount: int):
	pass

func get_closest_enemy(pos: Vector2, max_range: float) -> Node2D:
	if wave_manager:
		return wave_manager.get_closest_enemy(pos, max_range)
	return null
