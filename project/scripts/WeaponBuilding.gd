class_name WeaponBuilding
extends Building

@export var weapon_data: WeaponData
var timer: float = 0.0
var can_fire: bool = true
var ammo_queue: Array[Payload] = []

var ammo_label: Label

signal on_fire(payload: Payload, start_pos: Vector2, target: Node2D, hit_point: Vector2)

func _init():
	# Default to regular weapon
	base_texture_path = "res://assets/weapon.svg"

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	weapon_data = w_data

	# Если это дробовик, меняем текстуру
	if w_data and w_data.firing_arc < 360.0:
		base_texture_path = "res://assets/shotgun.svg"
		if sprite:
			sprite.texture = load(base_texture_path)

	super.setup(w_data, p_grid_pos)

	if ammo_label == null:
		ammo_label = Label.new()
		ammo_label.set_anchors_preset(Control.PRESET_CENTER)
		ammo_label.position = Vector2(-20, -10)
		ammo_label.add_theme_font_size_override("font_size", 24)
		ammo_label.add_theme_color_override("font_color", Color.WHITE)
		ammo_label.add_theme_color_override("font_outline_color", Color.BLACK)
		ammo_label.add_theme_constant_override("outline_size", 4)
		ammo_label.z_index = 10 # Убеждаемся, что текст рисуется поверх спрайта и линий сектора

		# Делаем так, чтобы Label не крутился вместе с базовым Rotation (в Godot 4 CanvasItem не крутится,
		# но если мы крутили саму ноду - это спасло бы. Мы крутим Sprite, так что Label и так прямой).
		add_child(ammo_label)
		_update_ammo_label()

func can_receive_payload(payload: Payload = null) -> bool:
	if not super(payload): return false

	# Пушки принимают ТОЛЬКО готовые патроны, а не сырье
	if payload and payload.base_type != "Ammo":
		return false

	return true

func receive_payload(payload: Payload):
	# Если мы в режиме стройки, просто игнорируем случайные остаточные патроны
	if not is_combat_active():
		return

	super(payload)
	ammo_queue.append(payload)
	_update_ammo_label()

func _process(delta):
	if not is_combat_active():
		return

	if not can_fire:
		timer += delta

		var current_fire_rate = weapon_data.fire_rate if weapon_data else 1.0
		var gm = get_node_or_null("/root/Main/GameManager")
		if gm and gm.run_modifiers.has("fire_rate_multiplier"):
			current_fire_rate *= gm.run_modifiers["fire_rate_multiplier"]

		if current_fire_rate > 0 and timer >= (1.0 / current_fire_rate):
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

	var count = weapon_data.projectiles_per_shot if weapon_data else 1
	var wm = get_node_or_null("/root/Main/WaveManager")
	var face_dir = Vector2(facing_direction)
	var w_range = weapon_data.range if weapon_data else 500.0

	for i in range(count):
		var current_target = target
		var hit_point = target.global_position if target else global_position + face_dir * w_range
		var shot_dir = face_dir

		# Логика дробовика (конусное распределение пуль и raycast)
		if count > 1 and wm and weapon_data:
			var arc_rad = deg_to_rad(weapon_data.firing_arc)
			var base_angle = face_dir.angle()

			# Равномерно распределяем лучи по сектору или добавляем случайный разброс
			var random_offset = randf_range(-arc_rad / 2.0, arc_rad / 2.0)
			var ray_angle = base_angle + random_offset
			shot_dir = Vector2(cos(ray_angle), sin(ray_angle))

			# Трассируем луч, чтобы понять, в кого или куда мы попали
			var raycast_result = wm.raycast_enemy(global_position, shot_dir, w_range)
			if raycast_result["hit"]:
				current_target = raycast_result["target"]
				hit_point = raycast_result["point"]
			else:
				current_target = null
				hit_point = raycast_result["point"]

		# Применяем ин-ран баффы урона и пробития к Payload перед выстрелом
		var gm = get_node_or_null("/root/Main/GameManager")
		var p_clone = Payload.new(payload_to_fire.base_type, payload_to_fire.base_damage)
		p_clone.tags = payload_to_fire.tags.duplicate()

		if gm:
			if gm.run_modifiers.has("dmg_multiplier"):
				p_clone.base_damage *= gm.run_modifiers["dmg_multiplier"]

			if gm.run_modifiers.has("pierce_chance") and gm.run_modifiers["pierce_chance"] > 0:
				if randf() <= gm.run_modifiers["pierce_chance"]:
					if "Pierce" not in p_clone.tags:
						p_clone.tags.append("Pierce")

		on_fire.emit(p_clone, global_position, current_target, hit_point)

	_update_ammo_label()

func _update_ammo_label():
	if ammo_label:
		ammo_label.text = str(ammo_queue.size())

func _reset_state():
	ammo_queue.clear()
	_update_ammo_label()

func _draw():
	# Вызываем базовую отрисовку полоски HP
	super._draw()

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
