class_name Miner
extends Building

@export var produce_time: float = 1.0
var timer: float = 0.0
var active: bool = false

func _init():
	base_texture_path = "res://assets/miner.svg"

func _ready():
	super()
	active = true

func _process(delta):
	if not active or not is_combat_active():
		return

	timer += delta
	if timer >= produce_time:
		timer = 0.0
		produce()

func produce():
	# Майнер добывает сырой металл, который еще нужно переработать
	var p = Payload.new("RawMetal", 10.0)
	if StatTracker:
		StatTracker.track_resource_produced("RawMetal")
	# Emit out in the facing direction
	on_payload_output.emit(p, facing_direction)
