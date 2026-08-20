class_name ModifierBuilding
extends Building

@export var modifier_data: ModifierData
var processing_time: float = 0.2 # Small delay for processing
var current_payload: Payload = null
var timer: float = 0.0
var is_processing: bool = false

func _init():
	base_texture_path = "res://assets/modifier.svg"

func can_receive_payload() -> bool:
	return not is_processing and current_payload == null

func receive_payload(payload: Payload):
	if is_processing or current_payload != null:
		return

	super(payload)
	current_payload = payload
	is_processing = true
	timer = 0.0

func _process(delta):
	if is_processing and is_combat_active():
		timer += delta
		if timer >= processing_time:
			finish_processing()

func finish_processing():
	if current_payload and modifier_data:
		current_payload.apply_modifier(modifier_data)

	is_processing = false
	var out_p = current_payload
	current_payload = null

	on_payload_output.emit(out_p, facing_direction)
