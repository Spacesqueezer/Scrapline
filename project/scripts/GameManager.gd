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

func _ready():
	print("GameManager initialized.")

	# Connect UI Signals if possible
	if build_menu:
		build_menu.on_start_wave_pressed.connect(_on_ui_start_wave)
		build_menu.on_building_selected.connect(_on_ui_building_selected)

		# Connect to own signals to update UI
		state_changed.connect(func(state):
			var state_name = GameState.keys()[state]
			build_menu.update_state_label(state_name)
		)
		wave_started.connect(func(w): build_menu.update_wave_label(w))
		base_damaged.connect(func(amt, hp): build_menu.update_base_hp(hp))

	# Delay initial state to let UI load
	call_deferred("change_state", GameState.BUILD)

func _on_ui_start_wave():
	if current_state == GameState.BUILD:
		change_state(GameState.COMBAT)

func _on_ui_building_selected(b_type: String):
	if current_state == GameState.BUILD and grid_manager:
		grid_manager.set_selected_building(b_type)

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
			# For now, auto-skip reward back to build
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
