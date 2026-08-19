class_name Miner
extends Building

@export var produce_time: float = 1.0
var timer: float = 0.0
var active: bool = false

func _ready():
	active = true

func _process(delta):
	if not active:
		return

	timer += delta
	if timer >= produce_time:
		timer = 0.0
		produce()

func produce():
	var p = Payload.new("Scrap", 10.0)
	# Emit out in the facing direction
	on_payload_output.emit(p, facing_direction)
