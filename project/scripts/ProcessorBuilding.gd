class_name ProcessorBuilding
extends Building

var processing_time: float = 0.5
var current_payload: Payload = null
var timer: float = 0.0
var is_processing: bool = false

func _init():
	base_texture_path = "res://assets/modifier.svg" # Пока используем ту же текстуру, потом можно заменить

func can_receive_payload(payload: Payload = null) -> bool:
	if not super(payload): return false

	# Процессор принимает только сырье
	if payload and payload.base_type != "RawMetal":
		return false

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

func _reset_state():
	current_payload = null
	is_processing = false

func finish_processing():
	if current_payload:
		# Перерабатываем сырье в патроны
		current_payload.base_type = "Ammo"
		if StatTracker:
			StatTracker.track_resource_produced("Ammo")

	is_processing = false
	var out_p = current_payload
	current_payload = null

	on_payload_output.emit(out_p, facing_direction)
