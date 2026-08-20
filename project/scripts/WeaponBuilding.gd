class_name WeaponBuilding
extends Building

@export var weapon_data: WeaponData
var timer: float = 0.0
var can_fire: bool = true
var ammo_queue: Array[Payload] = []

signal on_fire(payload: Payload, start_pos: Vector2, target: Node2D)

func _ready():
	base_color = Color(0.8, 0.2, 0.2) # Красный для пушки

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	super.setup(w_data, p_grid_pos)
	weapon_data = w_data

func receive_payload(payload: Payload):
	# Если мы в режиме стройки, просто игнорируем случайные остаточные патроны
	if not is_combat_active():
		return

	super(payload)
	ammo_queue.append(payload)
	queue_redraw()

func _process(delta):
	if not is_combat_active():
		return

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
	var wm = get_node_or_null("/root/Main/WaveManager")
	if wm and weapon_data:
		var face_dir = Vector2(facing_direction)
		return wm.get_closest_enemy_in_arc(global_position, weapon_data.range, face_dir, weapon_data.firing_arc)
	return null

func fire(target: Node2D):
	var payload_to_fire = ammo_queue.pop_front()
	can_fire = false
	timer = 0.0

	# Emit multiple times if shotgun
	var count = weapon_data.projectiles_per_shot if weapon_data else 1
	for i in range(count):
		on_fire.emit(payload_to_fire, global_position, target)

	queue_redraw()

func _draw():
	super()

	# Отрисовываем сектор обстрела (если он меньше 360)
	if weapon_data and weapon_data.firing_arc < 360.0:
		var face_dir = Vector2(facing_direction)
		var angle = face_dir.angle()
		var arc_rad = deg_to_rad(weapon_data.firing_arc)

		# Отрисовываем две линии, показывающие сектор
		var p1 = Vector2.from_angle(angle - arc_rad/2) * 50.0
		var p2 = Vector2.from_angle(angle + arc_rad/2) * 50.0
		draw_line(Vector2.ZERO, p1, Color(1, 0, 0, 0.3), 2.0)
		draw_line(Vector2.ZERO, p2, Color(1, 0, 0, 0.3), 2.0)

	# Отрисовка счетчика патронов
	var ammo_count = str(ammo_queue.size())
	# Отрисовываем текст поверх здания (чуть ниже центра)
	var text_pos = Vector2(0, 10)
	draw_string(ThemeDB.fallback_font, text_pos, ammo_count, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)
