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

func _ready():
	print("GameManager initialized.")
	change_state(GameState.BUILD)

func change_state(new_state: GameState):
	current_state = new_state
	state_changed.emit(current_state)

	match current_state:
		GameState.BUILD:
			print("Phase: BUILD")
			# Enable grid interactions
		GameState.COMBAT:
			print("Phase: COMBAT")
			start_wave()
		GameState.REWARD:
			print("Phase: REWARD")
			# Show reward draft UI
		GameState.GAME_OVER:
			print("Phase: GAME OVER")
			# Show game over screen

func start_wave():
	current_wave += 1
	wave_started.emit(current_wave)
	print("Starting Wave: ", current_wave)
	# Trigger WaveManager to start spawning enemies

func damage_base(amount: int):
	base_hp -= amount
	base_damaged.emit(amount, base_hp)
	if base_hp <= 0:
		change_state(GameState.GAME_OVER)
