class_name WeaponBuilding
extends Building

@export var weapon_data: WeaponData
var timer: float = 0.0
var can_fire: bool = true
var ammo_queue: Array[Payload] = []

signal on_fire(payload: Payload, start_pos: Vector2, target: Node2D)

func _ready():
	base_color = Color(0.8, 0.2, 0.2) # Красный для пушки
	super()

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	super.setup(w_data, p_grid_pos)
	weapon_data = w_data

func receive_payload(payload: Payload):
	super(payload)
	ammo_queue.append(payload)

func _process(delta):
	if not can_fire:
		timer += delta
		if weapon_data and timer >= (1.0 / weapon_data.fire_rate):
			can_fire = true
			timer = 0.0

	if can_fire and ammo_queue.size() > 0:
		var target = find_target()
		if target != null:
			fire(target)

func find_target() -> Node2D:
	# Temporary mock: Return a target if one is in range.
	# GameManager or WaveManager usually provides a list of enemies.
	# For prototype, we will emit a signal or let GameManager inject target logic.
	var gm = get_node_or_null("/root/Main/GameManager")
	if gm and gm.has_method("get_closest_enemy"):
		return gm.get_closest_enemy(global_position, weapon_data.range) if weapon_data else null
	return null

func fire(target: Node2D):
	var payload_to_fire = ammo_queue.pop_front()
	can_fire = false
	timer = 0.0
	on_fire.emit(payload_to_fire, global_position, target)
