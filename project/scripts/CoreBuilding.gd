class_name CoreBuilding
extends Building

@export var max_energy: int = 50

func _init():
	base_texture_path = "res://assets/core.svg"

func _ready():
	super()
	max_hp = 200.0
	hp = max_hp

# Ядро ничего не производит и не передает (пока), только питает фабрику и выступает целью
func can_receive_payload() -> bool:
	return false

func receive_payload(payload: Payload):
	pass

func on_destroyed():
	# Если ядро уничтожено - игра окончена
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm:
		gm.change_state(gm.GameState.GAME_OVER)
