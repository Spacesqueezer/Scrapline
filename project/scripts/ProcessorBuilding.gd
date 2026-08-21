class_name ProcessorBuilding
extends Building

var processing_time: float = 0.5
var current_payload: Payload = null
var timer: float = 0.0
var is_processing: bool = false
var input_queue: Array[Payload] = []
var max_queue: int = 5

func _init():
	base_texture_path = "res://assets/modifier.svg"

func can_receive_payload(payload: Payload = null) -> bool:
	if not super(payload): return false

	if payload and payload.base_type != "RawMetal":
		return false

	return input_queue.size() < max_queue

func receive_payload(payload: Payload):
	if input_queue.size() >= max_queue:
		return
	super(payload)
	input_queue.append(payload)

func _process(delta):
	if not is_combat_active():
		return

	if not is_processing and input_queue.size() > 0:
		current_payload = input_queue.pop_front()
		is_processing = true
		timer = 0.0

	if is_processing:
		timer += delta
		if timer >= processing_time:
			finish_processing()

func _reset_state():
	current_payload = null
	is_processing = false
	input_queue.clear()

func finish_processing():
	if current_payload:
		current_payload.base_type = "Ammo"
		if StatTracker:
			StatTracker.track_resource_produced("Ammo")

	is_processing = false
	var out_p = current_payload
	current_payload = null

	on_payload_output.emit(out_p, facing_direction)
