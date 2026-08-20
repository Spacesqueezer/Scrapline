class_name ConveyorBuilding
extends Building

var processing_time: float = 0.1 # Конвейер передает быстро
var current_payload: Payload = null
var timer: float = 0.0
var is_processing: bool = false

func _init():
	base_texture_path = "res://assets/conveyor.svg"

func _ready():
	super()

	# Применяем шейдер прокрутки для анимации конвейера
	if sprite:
		var mat = ShaderMaterial.new()
		var shader = load("res://assets/conveyor.gdshader")
		mat.shader = shader
		mat.set_shader_parameter("speed", -1.0) # Для прокрутки по горизонтали/вертикали в шейдере
		sprite.material = mat

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
			try_finish_processing()

func try_finish_processing():
	var gm = get_node_or_null("/root/Main/World2D/GridManager")
	if not gm:
		return

	var next_pos = grid_position + facing_direction
	var next_b = gm.get_module_at(next_pos)

	# Если впереди нет здания или оно забито - стоим на месте
	if not next_b or not next_b.has_method("can_receive_payload") or not next_b.can_receive_payload():
		return

	is_processing = false
	var out_p = current_payload
	current_payload = null
	timer = 0.0

	on_payload_output.emit(out_p, facing_direction)
